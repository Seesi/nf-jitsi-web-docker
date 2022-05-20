#!/bin/bash

REPO_ROOT=~/projects/accede/nf-jitsi-web-docker
NOT_FORGOTTEN_JITSI_MEET_DIR=~/projects/accede/nf-jitsi-meet
JITSI_MEET_CONFIG_DIR=~/.jitsi-meet-cfg

echo "Building Jitsi-Meet packages from source ..." && sleep 1

cd $NOT_FORGOTTEN_JITSI_MEET_DIR || { echo "Failed to find $NOT_FORGOTTEN_JITSI_MEET_DIR"; exit 1; }
make || { echo "Make failed"; exit 1; }
make source-package || { echo "Make source-package failed"; exit 1; }

echo "Taking down the Docker container stack" && sleep 1

cd $REPO_ROOT || { echo "Failed to find $REPO_ROOT/Docker"; exit 1; }
docker-compose down 

echo "Removing and recreating Jitsi-Meet config directories" && sleep 1

sudo rm -rf $JITSI_MEET_CONFIG_DIR || { echo "Failed to remove $JITSI_MEET_CONFIG_DIR"; exit 1; }
mkdir -p $JITSI_MEET_CONFIG_DIR/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri} || { echo "Failed to create required config directories at $JITSI_MEET_CONFIG_DIR root"; exit 1; }


echo "Moving and unzipping Jitsi-Meet package archive into Docker build context" && sleep 1
mv $NOT_FORGOTTEN_JITSI_MEET_DIR/jitsi-meet.tar.bz2 $JITSI_MEET_CONFIG_DIR/web || { echo "Failed to move packages to destination"; exit 1; }
cd $JITSI_MEET_CONFIG_DIR/web || { echo "Failed to find $JITSI_MEET_CONFIG_DIR/Docker/Web"; exit 1; }
rm -rf jitsi-meet/ || { echo "Failed to remove jitsi-meet folder": exit 1; }
tar -xvf jitsi-meet* || { echo "Failed to unzip archive"; exit 1; }
rm -rf $JITSI_MEET_CONFIG_DIR/web/jitsi-meet.tar.bz2

mkdir -p $JITSI_MEET_CONFIG_DIR/web/defaults
sudo rsync -azP ~/projects/accede/defaults/ $JITSI_MEET_CONFIG_DIR/web/defaults
sudo rsync -azP $JITSI_MEET_CONFIG_DIR/web/jitsi-meet/interface_config.js $JITSI_MEET_CONFIG_DIR/web/defaults/interface_config.js

echo "Rebuilding Jitsi-Meet web Docker container and bringing up Docker container stack" && sleep 1

cd $REPO_ROOT || { echo "Failed to find $REPO_ROOT/Docker"; exit 1; }
./gen-passwords.sh
docker-compose up -d || { echo "Docker operation failed"; exit 1; }

echo "Copying defaults/ files from container" && sleep 1

echo "Back-end is up"