#!/bin/bash

# Deploy script for Yami-Buzzy Wedding Website
# Usage: ./deploy.sh [SERVER_IP] [SERVER_USER] [--with-ssl]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="yami-buzzy-wedding"
IMAGE_NAME="yami-buzzy-wedding:latest"
CONTAINER_NAME="yami-buzzy-wedding"
PORT="80"
DOMAIN="manhuong.love"
SSL_ENABLED=false

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Yami-Buzzy Wedding Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if deploying locally or to remote server
if [ "$#" -eq 0 ]; then
    print_info "Deploying locally..."
    DEPLOY_MODE="local"
elif [ "$#" -ge 2 ]; then
    SERVER_IP=$1
    SERVER_USER=$2
    # Check for --with-ssl flag
    if [ "$#" -eq 3 ] && [ "$3" = "--with-ssl" ]; then
        SSL_ENABLED=true
        IMAGE_NAME="yami-buzzy-wedding:ssl"
    fi
    print_info "Deploying to remote server: ${SERVER_USER}@${SERVER_IP}"
    [ "$SSL_ENABLED" = true ] && print_info "SSL mode enabled"
    DEPLOY_MODE="remote"
else
    print_error "Usage: ./deploy.sh [SERVER_IP] [SERVER_USER] [--with-ssl]"
    print_info "For local deployment: ./deploy.sh"
    print_info "For remote deployment (HTTP): ./deploy.sh 192.168.1.100 ubuntu"
    print_info "For remote deployment (HTTPS): ./deploy.sh 192.168.1.100 ubuntu --with-ssl"
    exit 1
fi

# Function to deploy locally
deploy_local() {
    print_info "Step 1: Building Docker image..."
    docker build -t $IMAGE_NAME .
    
    print_info "Step 2: Stopping and removing old container (if exists)..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    
    print_info "Step 3: Starting new container..."
    docker run -d \
        --name $CONTAINER_NAME \
        -p $PORT:80 \
        --restart unless-stopped \
        $IMAGE_NAME
    
    print_info "Step 4: Checking container status..."
    sleep 3
    if docker ps | grep -q $CONTAINER_NAME; then
        print_info "${GREEN}✓ Deployment successful!${NC}"
        print_info "Website is running at: http://localhost:$PORT"
    else
        print_error "Container failed to start. Check logs with: docker logs $CONTAINER_NAME"
        exit 1
    fi
}

# Function to deploy to remote server
deploy_remote() {
    print_info "Step 1: Creating deployment package..."
    DEPLOY_DIR="/tmp/${PROJECT_NAME}-deploy"
    rm -rf $DEPLOY_DIR
    mkdir -p $DEPLOY_DIR
    
    # Copy necessary files
    if [ "$SSL_ENABLED" = true ]; then
        cp -r index.html wp-content wp-includes nginx-ssl.conf .dockerignore $DEPLOY_DIR/ 2>/dev/null || true
        cp nginx-ssl.conf $DEPLOY_DIR/nginx.conf
    else
        cp -r index.html wp-content wp-includes nginx.conf .dockerignore $DEPLOY_DIR/ 2>/dev/null || true
    fi
    
    print_info "Step 2: Compressing files..."
    tar -czf /tmp/${PROJECT_NAME}.tar.gz -C /tmp ${PROJECT_NAME}-deploy
    
    print_info "Step 3: Uploading to server..."
    scp /tmp/${PROJECT_NAME}.tar.gz ${SERVER_USER}@${SERVER_IP}:/tmp/
    
    if [ "$SSL_ENABLED" = true ]; then
        deploy_with_ssl
    else
        deploy_without_ssl
    fi
    
    print_info "Step 5: Verifying deployment..."
    sleep 3
    if ssh ${SERVER_USER}@${SERVER_IP} "docker ps | grep -q yami-buzzy-wedding"; then
        print_info "${GREEN}✓ Remote deployment successful!${NC}"
        if [ "$SSL_ENABLED" = true ]; then
            print_info "Website is running at: https://${DOMAIN}"
            print_info "HTTP will redirect to HTTPS automatically"
        else
            print_info "Website is running at: http://${SERVER_IP}"
        fi
    else
        print_error "Container failed to start on remote server"
        ssh ${SERVER_USER}@${SERVER_IP} "docker logs yami-buzzy-wedding 2>&1 | tail -20"
        exit 1
    fi
    
    # Cleanup local temp files
    rm -f /tmp/${PROJECT_NAME}.tar.gz
    rm -rf /tmp/${PROJECT_NAME}-deploy
}

# Function to deploy without SSL
deploy_without_ssl() {
    print_info "Step 4: Deploying on server (HTTP mode)..."
    ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
set -e

# Extract files
cd /tmp
rm -rf yami-buzzy-wedding-deploy
tar -xzf yami-buzzy-wedding.tar.gz
cd yami-buzzy-wedding-deploy

# Create Dockerfile
cat > Dockerfile << 'DOCKERFILE'
FROM nginx:latest
WORKDIR /usr/share/nginx/html
RUN rm -rf /etc/nginx/conf.d/default.conf
RUN rm -rf ./*
COPY nginx.conf /etc/nginx/conf.d/manhuong.conf
COPY index.html /usr/share/nginx/html/
COPY wp-content /usr/share/nginx/html/wp-content
COPY wp-includes /usr/share/nginx/html/wp-includes
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE

# Stop and remove old container
docker stop yami-buzzy-wedding 2>/dev/null || true
docker rm yami-buzzy-wedding 2>/dev/null || true

# Build and start new container
docker build -t yami-buzzy-wedding:latest .
docker run -d \
    --name yami-buzzy-wedding \
    -p 80:80 \
    --restart unless-stopped \
    yami-buzzy-wedding:latest

# Cleanup
cd /tmp
rm -rf yami-buzzy-wedding-deploy yami-buzzy-wedding.tar.gz

echo "Deployment completed!"
ENDSSH
}

# Function to deploy with SSL
deploy_with_ssl() {
    print_info "Step 4: Deploying on server (HTTPS mode)..."
    ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
set -e

# Extract files
cd /tmp
rm -rf yami-buzzy-wedding-deploy
tar -xzf yami-buzzy-wedding.tar.gz

# Copy files to persistent location
mkdir -p ~/wedding-files
cp yami-buzzy-wedding-deploy/index.html ~/wedding-files/
cp -r yami-buzzy-wedding-deploy/wp-content ~/wedding-files/
cp -r yami-buzzy-wedding-deploy/wp-includes ~/wedding-files/
cp yami-buzzy-wedding-deploy/nginx.conf ~/

# Create SSL Dockerfile
cat > ~/Dockerfile.ssl << 'DOCKERFILE'
FROM nginx:latest
WORKDIR /usr/share/nginx/html
RUN rm -rf /etc/nginx/conf.d/default.conf
RUN rm -rf ./*
COPY nginx.conf /etc/nginx/conf.d/manhuong.conf
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE

cd ~

# Stop and remove old container
docker stop yami-buzzy-wedding 2>/dev/null || true
docker rm yami-buzzy-wedding 2>/dev/null || true

# Build image with SSL config
docker build -f ~/Dockerfile.ssl -t yami-buzzy-wedding:ssl ~/

# Run container with SSL and volume mounts
docker run -d \
    --name yami-buzzy-wedding \
    -p 80:80 \
    -p 443:443 \
    -v /etc/letsencrypt:/etc/letsencrypt:ro \
    -v ~/wedding-files/index.html:/usr/share/nginx/html/index.html:ro \
    -v ~/wedding-files/wp-content:/usr/share/nginx/html/wp-content:ro \
    -v ~/wedding-files/wp-includes:/usr/share/nginx/html/wp-includes:ro \
    --restart unless-stopped \
    yami-buzzy-wedding:ssl

# Cleanup
cd /tmp
rm -rf yami-buzzy-wedding-deploy yami-buzzy-wedding.tar.gz

echo "SSL Deployment completed!"
ENDSSH
}

# Execute deployment based on mode
if [ "$DEPLOY_MODE" = "local" ]; then
    deploy_local
else
    deploy_remote
fi

echo ""
print_info "${GREEN}========================================${NC}"
print_info "${GREEN}  Deployment Complete!${NC}"
print_info "${GREEN}========================================${NC}"

# Show useful commands
echo ""
print_info "Useful commands:"
echo "  - View logs: docker logs -f $CONTAINER_NAME"
echo "  - Stop container: docker stop $CONTAINER_NAME"
echo "  - Restart container: docker restart $CONTAINER_NAME"
echo "  - Remove container: docker rm -f $CONTAINER_NAME"
