#!/bin/bash

# Script tự động cài SSL cho server từ xa
# Chạy từ máy local

SERVER_IP="45.119.87.94"
SERVER_USER="ubuntu"
DOMAIN="manhuong.love"
WWW_DOMAIN="www.manhuong.love"

echo "========================================="
echo "  Cài đặt SSL cho $DOMAIN"
echo "========================================="

# Bước 1: Stop container hiện tại
echo "Bước 1: Dừng container để giải phóng port 80..."
ssh ${SERVER_USER}@${SERVER_IP} << 'EOF1'
docker stop yami-buzzy-wedding
EOF1

# Bước 2: Cài đặt Certbot và lấy certificate
echo "Bước 2: Cài đặt Certbot và lấy SSL certificate..."
ssh -t ${SERVER_USER}@${SERVER_IP} << 'EOF2'
# Cài Certbot nếu chưa có
if ! command -v certbot &> /dev/null; then
    echo "Đang cài đặt Certbot..."
    sudo apt update
    sudo apt install -y certbot
fi

# Lấy SSL certificate
sudo certbot certonly --standalone \
    -d manhuong.love \
    -d www.manhuong.love \
    --non-interactive \
    --agree-tos \
    --email admin@manhuong.love \
    --preferred-challenges http

# Setup auto-renewal
sudo systemctl enable certbot.timer || true
sudo systemctl start certbot.timer || true
EOF2

# Bước 3: Upload nginx config với SSL
echo "Bước 3: Upload cấu hình NGINX với SSL..."
scp nginx-ssl.conf ${SERVER_USER}@${SERVER_IP}:~/nginx.conf

# Bước 4: Tạo Dockerfile mới trên server
echo "Bước 4: Cập nhật cấu hình Docker..."
ssh ${SERVER_USER}@${SERVER_IP} << 'EOF4'
cat > ~/Dockerfile.ssl << 'DOCKERFILE'
FROM nginx:latest

WORKDIR /usr/share/nginx/html

# Remove default nginx config and files
RUN rm -rf /etc/nginx/conf.d/default.conf
RUN rm -rf ./*

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/manhuong.conf

# Copy website files (will be mounted from host)
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE
EOF4

# Bước 5: Rebuild và chạy container với SSL
echo "Bước 5: Rebuild và khởi động container với SSL..."
ssh ${SERVER_USER}@${SERVER_IP} << 'EOF5'
# Build image mới với SSL config
docker build -f ~/Dockerfile.ssl -t yami-buzzy-wedding:ssl ~/

# Chạy container với SSL mount
docker run -d \
  --name yami-buzzy-wedding \
  -p 80:80 \
  -p 443:443 \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  -v ~/wp-content:/usr/share/nginx/html/wp-content:ro \
  -v ~/wp-includes:/usr/share/nginx/html/wp-includes:ro \
  -v ~/index.html:/usr/share/nginx/html/index.html:ro \
  --restart unless-stopped \
  yami-buzzy-wedding:ssl
EOF5

echo ""
echo "========================================="
echo "  ✅ Hoàn tất cài đặt SSL!"
echo "========================================="
echo ""
echo "Kiểm tra website tại:"
echo "  HTTP:  http://manhuong.love"
echo "  HTTPS: https://manhuong.love"
echo ""
echo "Kiểm tra certificate:"
echo "  ssh ${SERVER_USER}@${SERVER_IP} 'sudo certbot certificates'"
echo ""
