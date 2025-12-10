# 🚀 Hướng dẫn Deploy Yami-Buzzy Wedding Website

Tài liệu này hướng dẫn chi tiết cách triển khai website thiệp cưới lên server Ubuntu với Docker.

## 📋 Yêu cầu hệ thống

### Server Ubuntu
- **OS**: Ubuntu 20.04 LTS hoặc mới hơn
- **Docker**: Version 20.10+ đã được cài đặt
- **RAM**: Tối thiểu 512MB (khuyến nghị 1GB+)
- **Disk**: Tối thiểu 2GB trống
- **Network**: Port 9896 mở cho HTTP traffic

### Máy local (để deploy)
- Git
- SSH client
- Docker (nếu muốn test local trước)

---

## 🔧 Chuẩn bị Server Ubuntu

### 1. Cài đặt Docker (nếu chưa có)

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Thêm user vào docker group (không cần sudo)
sudo usermod -aG docker $USER

# Logout và login lại để áp dụng
exit
```

### 2. Kiểm tra Docker

```bash
docker --version
docker ps
```

### 3. Mở Port (nếu có firewall)

```bash
# Nếu dùng UFW
sudo ufw allow 9896/tcp
sudo ufw reload

# Kiểm tra
sudo ufw status
```

---

## 📦 Phương pháp 1: Deploy tự động (Khuyến nghị)

### Từ máy local

```bash
# Clone repository (nếu chưa có)
git clone https://github.com/Tynab/Yami-Buzzy.git
cd Yami-Buzzy

# Deploy lên server Ubuntu
./deploy.sh <SERVER_IP> <SERVER_USER>

# Ví dụ:
./deploy.sh 192.168.1.100 ubuntu
```

Script sẽ tự động:
1. ✅ Đóng gói project
2. ✅ Upload lên server
3. ✅ Build Docker image
4. ✅ Deploy container
5. ✅ Kiểm tra trạng thái

---

## 📦 Phương pháp 2: Deploy thủ công

### Bước 1: Upload code lên server

**Option A - Sử dụng Git:**
```bash
# Trên server
cd /opt
sudo git clone https://github.com/Tynab/Yami-Buzzy.git
cd Yami-Buzzy
```

**Option B - Sử dụng SCP:**
```bash
# Trên máy local
tar -czf yami-buzzy.tar.gz --exclude=.git --exclude=node_modules .
scp yami-buzzy.tar.gz user@server_ip:/tmp/

# Trên server
cd /opt
sudo mkdir -p Yami-Buzzy
cd Yami-Buzzy
sudo tar -xzf /tmp/yami-buzzy.tar.gz
```

### Bước 2: Build Docker image

```bash
cd /opt/Yami-Buzzy
docker build -t yami-buzzy-wedding:latest .
```

### Bước 3: Chạy container

```bash
# Dừng container cũ (nếu có)
docker stop yami-buzzy-wedding 2>/dev/null || true
docker rm yami-buzzy-wedding 2>/dev/null || true

# Chạy container mới
docker run -d \
  --name yami-buzzy-wedding \
  -p 9896:80 \
  --restart unless-stopped \
  yami-buzzy-wedding:latest
```

### Bước 4: Kiểm tra

```bash
# Kiểm tra container đang chạy
docker ps | grep yami-buzzy-wedding

# Xem logs
docker logs yami-buzzy-wedding

# Test truy cập
curl http://localhost:9896
```

---

## 📦 Phương pháp 3: Sử dụng Docker Compose

### Bước 1: Upload code như Phương pháp 2

### Bước 2: Chạy với Docker Compose

```bash
cd /opt/Yami-Buzzy

# Chạy container
docker-compose up -d

# Xem logs
docker-compose logs -f

# Dừng
docker-compose down
```

---

## 🌐 Cấu hình Domain & HTTPS (Tùy chọn)

### 1. Cài đặt Nginx Reverse Proxy

```bash
sudo apt install nginx -y
```

### 2. Tạo Nginx config

```bash
sudo nano /etc/nginx/sites-available/wedding
```

Nội dung file:
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location / {
        proxy_pass http://localhost:9896;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. Enable site

```bash
sudo ln -s /etc/nginx/sites-available/wedding /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 4. Cài đặt SSL với Certbot

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

---

## 🔄 Cập nhật Website

### Phương pháp nhanh (với deploy.sh)

```bash
# Trên máy local
./deploy.sh <SERVER_IP> <SERVER_USER>
```

### Phương pháp thủ công

```bash
# Trên server
cd /opt/Yami-Buzzy

# Pull code mới (nếu dùng Git)
git pull origin main

# Rebuild và restart
docker stop yami-buzzy-wedding
docker rm yami-buzzy-wedding
docker build -t yami-buzzy-wedding:latest .
docker run -d \
  --name yami-buzzy-wedding \
  -p 8080:80 \
  --restart unless-stopped \
  yami-buzzy-wedding:latest
```

---

## 📊 Quản lý & Giám sát

### Xem logs

```bash
# Xem logs realtime
docker logs -f yami-buzzy-wedding

# Xem 100 dòng logs cuối
docker logs --tail 100 yami-buzzy-wedding
```

### Kiểm tra tài nguyên

```bash
# CPU & Memory usage
docker stats yami-buzzy-wedding

# Disk usage
docker system df
```

### Restart container

```bash
docker restart yami-buzzy-wedding
```

### Dừng và xóa container

```bash
docker stop yami-buzzy-wedding
docker rm yami-buzzy-wedding
```

### Xóa image (để tiết kiệm dung lượng)

```bash
# Xem danh sách images
docker images

# Xóa images không dùng
docker image prune -a
```

---

## 🐛 Xử lý sự cố

### Container không start

```bash
# Xem logs để tìm lỗi
docker logs yami-buzzy-wedding

# Xem chi tiết container
docker inspect yami-buzzy-wedding
```

### Port 9896 đã được sử dụng

```bash
# Tìm process đang dùng port
sudo lsof -i :9896

# Hoặc thay đổi port trong docker run
docker run -d \
  --name yami-buzzy-wedding \
  -p 8888:80 \
  --restart unless-stopped \
  yami-buzzy-wedding:latest
```

### Không truy cập được từ bên ngoài

```bash
# Kiểm tra firewall
sudo ufw status

# Kiểm tra container đang lắng nghe port nào
docker port yami-buzzy-wedding

# Kiểm tra kết nối
curl http://localhost:9896
```

### Website load chậm

```bash
# Kiểm tra tài nguyên
docker stats yami-buzzy-wedding

# Tăng limit (nếu cần)
docker update --memory="1g" --cpus="2" yami-buzzy-wedding
```

---

## 🔒 Bảo mật

### 1. Cập nhật hệ thống định kỳ

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Cấu hình firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 9896/tcp
sudo ufw enable
```

### 3. Giới hạn SSH login

```bash
# Chỉ cho phép key-based authentication
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart ssh
```

---

## 📞 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra logs: `docker logs yami-buzzy-wedding`
2. Kiểm tra container status: `docker ps -a`
3. Tham khảo: [Docker Documentation](https://docs.docker.com/)

---

## 📝 Checklist Deployment

- [ ] Server Ubuntu đã cài Docker
- [ ] Port 9896 đã mở
- [ ] Code đã upload lên server
- [ ] Docker image build thành công
- [ ] Container đang chạy (`docker ps`)
- [ ] Truy cập được từ browser: `http://server_ip:9896`
- [ ] (Optional) Domain đã trỏ về server
- [ ] (Optional) SSL certificate đã cài đặt
- [ ] Auto-restart đã được cấu hình

---

## 🎉 Hoàn thành!

Website thiệp cưới của bạn đã sẵn sàng! 🎊

Truy cập: **http://your-server-ip:9896**
