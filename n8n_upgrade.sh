#!/bin/bash
#
# n8n upgrade script
#
echo "--------------------------------------------------"
echo "The upgrade requires a valid version of n8n."
echo "cancel this upgrade, press Ctrl+C.  This script will run again on your next login"
echo "--------------------------------------------------"
echo "Enter a version to upgrade your n8n instance."
echo "(ex. 1.71.3)"
echo "--------------------------------------------------"

env_file="/opt/n8n-docker-caddy/.env"

# Ask for the version number
version=""
while [ -z "$version" ]
do
  read -p "n8n version number: " version

  if [ -z "$version" ]
  then
    echo "Please provide a version number to continue or press Ctrl+C to cancel"
  fi

done

echo ">>> checking if version $version of n8n docker image exists..."

if docker pull docker.n8n.io/n8nio/n8n:$version ; then
    echo ">>> version exists"
else
    echo ">> version $version not found. aborting upgrade."
    exit 1
fi

sleep 3

sed -i "s/^N8N_IMAGE_VERSION=.*/N8N_IMAGE_VERSION=$version/" "$env_file"

echo ">>> upgrading n8n docker container to n8n image version $version..."

cd /opt/n8n-docker-caddy/

# upgrade steps - https://docs.n8n.io/hosting/installation/server-setups/digital-ocean/#updating

docker compose pull

docker compose down

docker compose up -d

echo "--------------------------------------------------"
echo "Upgrade complete. n8n upgraded to version $version"
