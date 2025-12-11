#!/bin/bash

# SSL Setup Script for manhuong.love
# Run this ONCE before deploying with --with-ssl flag
# Usage: ./setup-ssl-server.sh [SERVER_IP] [SERVER_USER] [DOMAIN] [EMAIL]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check arguments
if [ "$#" -lt 2 ]; then
    print_error "Usage: ./setup-ssl-server.sh [SERVER_IP] [SERVER_USER] [DOMAIN] [EMAIL]"
    print_info "Example: ./setup-ssl-server.sh 45.119.87.94 ubuntu manhuong.love admin@manhuong.love"
    exit 1
fi

SERVER_IP=$1
SERVER_USER=$2
DOMAIN=${3:-manhuong.love}
EMAIL=${4:-admin@$DOMAIN}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SSL Setup for ${DOMAIN}${NC}"
echo -e "${GREEN}========================================${NC}"

print_info "Server: ${SERVER_USER}@${SERVER_IP}"
print_info "Domain: ${DOMAIN}"
print_info "Email: ${EMAIL}"
echo ""

# Step 1: Stop any running container
print_info "Step 1: Stopping container to free port 80..."
ssh ${SERVER_USER}@${SERVER_IP} "docker stop yami-buzzy-wedding 2>/dev/null || true"

# Step 2: Install Certbot
print_info "Step 2: Installing Certbot on server..."
ssh -t ${SERVER_USER}@${SERVER_IP} << EOF
if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    sudo apt update
    sudo apt install -y certbot
else
    echo "Certbot already installed"
fi
EOF

# Step 3: Obtain SSL Certificate
print_info "Step 3: Obtaining SSL certificate for ${DOMAIN}..."
ssh -t ${SERVER_USER}@${SERVER_IP} << EOF
sudo certbot certonly --standalone \
    -d ${DOMAIN} \
    --non-interactive \
    --agree-tos \
    --email ${EMAIL}
EOF

# Step 4: Setup Auto-renewal
print_info "Step 4: Setting up automatic renewal..."
ssh ${SERVER_USER}@${SERVER_IP} << 'EOF'
sudo systemctl enable certbot.timer 2>/dev/null || true
sudo systemctl start certbot.timer 2>/dev/null || true
EOF

# Step 5: Verify certificate
print_info "Step 5: Verifying certificate..."
ssh -t ${SERVER_USER}@${SERVER_IP} "sudo certbot certificates"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ SSL Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
print_info "Next steps:"
echo "  1. Deploy website with SSL:"
echo "     ./deploy.sh ${SERVER_IP} ${SERVER_USER} --with-ssl"
echo ""
echo "  2. Access your website:"
echo "     https://${DOMAIN}"
echo ""
print_info "Certificate will auto-renew every 90 days"
