#!/bin/bash

# Script cài đặt SSL certificate cho domain manhuong.love
# Sử dụng Let's Encrypt (Certbot)

set -e

DOMAIN="manhuong.love"
WWW_DOMAIN="www.manhuong.love"
EMAIL="manhlh231@gmail.com"  # Thay bằng email của bạn

echo "========================================="
echo "  SSL Certificate Setup for $DOMAIN"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo ./setup-ssl.sh)"
    exit 1
fi

# Install Certbot
echo "Installing Certbot..."
apt update
apt install -y certbot python3-certbot-nginx

# Stop nginx container temporarily
echo "Stopping nginx container..."
docker stop yami-buzzy-wedding || true

# Obtain SSL certificate
echo "Obtaining SSL certificate for $DOMAIN and $WWW_DOMAIN..."
certbot certonly --standalone \
    -d $DOMAIN \
    -d $WWW_DOMAIN \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    --preferred-challenges http

echo "SSL certificate obtained successfully!"

# Setup auto-renewal
echo "Setting up auto-renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer

echo "========================================="
echo "SSL setup completed!"
echo "Certificates are stored in:"
echo "/etc/letsencrypt/live/$DOMAIN/"
echo ""
echo "Next steps:"
echo "1. Update docker-compose.yml to mount SSL certificates"
echo "2. Update nginx.conf to use SSL"
echo "3. Restart container: docker-compose up -d"
echo "========================================="
