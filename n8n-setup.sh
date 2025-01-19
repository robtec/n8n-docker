#!/bin/bash
#
# n8n activation script
#
echo "--------------------------------------------------"
echo "This setup requires a domain name.  If you do not have one yet, you may"
echo "cancel this setup, press Ctrl+C.  This script will run again on your next login"
echo "--------------------------------------------------"
echo "Enter a subdomain (default: n8n) and the domain name for your new n8n instance."
echo "(ex. example.org or test.example.org) do not include www or http/s"
echo "--------------------------------------------------"

caddy_file="/opt/n8n-docker-caddy/caddy_config/Caddyfile"
env_file="/opt/n8n-docker-caddy/.env"

a=0
while [ $a -eq 0 ]
do
  read -p "Subdomain (default: n8n): " subdomain
  subdomain=${subdomain:-n8n} # Set default subdomain to "n8n" if none is provided

  read -p "Domain name (e.g., yourdomain.org): " domain_name
  if [ -z "$domain_name" ]
  then
    echo "Please provide a valid domain name to continue or press Ctrl+C to cancel"
  else
    # Combine subdomain and domain name to form the full domain
    dom="$subdomain.$domain_name"

    # Get the IP of the entered domain
    domain_ip=$(dig +short "$dom" | tail -n1)
    # Get the IP of the current machine
    current_ip=$(hostname -I | awk '{print $1}')

    # Check if the domain points to the current machine's IP
    if [ "$domain_ip" == "$current_ip" ]
    then
      a=1
    else
      echo "The given address ($dom) does not point to this droplets IP ($current_ip). Please enter a domain pointing to this machine."
    fi
  fi
done

# Ask for an email address to be used for Let's Encrypt
email=""
while [ -z "$email" ]
do
  read -p "Email address for Let's Encrypt (required): " email
  if [ -z "$email" ]
  then
    echo "Please provide a valid email address to continue or press Ctrl+C to cancel"
  fi
done

# Ask if a timezone shall be configured
read -p "Would you like to configure a timezone? (y/N, default: Europe/Berlin): " configure_timezone
configure_timezone=${configure_timezone:-N}

if [[ "$configure_timezone" =~ ^([yY][eE][sS]|[yY])$ ]]
then
  echo "Please select your timezone using tzselect:"
  timezone=$(tzselect | tail -n1)
else
  echo "Using default timezone: Europe/Berlin"
  timezone="Europe/Berlin"
fi

# Use sed to replace "n8n.<domain>.<suffix>" with the given domain
sed -i "s/n8n\.<domain>\.<suffix>/$dom/g" "/opt/n8n-docker-caddy/caddy_config/Caddyfile"

# Update the .env file with the given subdomain, domain, email and time zone
sed -i "s/^DOMAIN_NAME=.*/DOMAIN_NAME=$domain_name/" "$env_file"
sed -i "s/^SUBDOMAIN=.*/SUBDOMAIN=$subdomain/" "$env_file"
sed -i "s/^SSL_EMAIL=.*/SSL_EMAIL=$email/" "$env_file"
sed -i "s|^GENERIC_TIMEZONE=.*|GENERIC_TIMEZONE=$timezone|" "$env_file"

cd /opt/n8n-docker-caddy
sudo docker compose up -d

cp /etc/skel/.bashrc /root

echo "--------------------------------------------------"
echo "Installation complete. Access your new n8n server in a browser to continue at https://$dom."
