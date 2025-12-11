# 🌐 Hướng dẫn cấu hình domain manhuong.love

## 📋 Tổng quan
Hướng dẫn này giúp bạn trỏ domain `manhuong.love` về website wedding của bạn với HTTPS.

---

## ✅ Bước 1: Cấu hình DNS

1. **Đăng nhập vào trang quản lý domain** (nơi bạn mua domain: GoDaddy, Namecheap, etc.)

2. **Tìm mục DNS Management / DNS Records**

3. **Thêm A Record:**
   ```
   Type: A
   Name: @ (hoặc để trống cho root domain)
   Value: <IP_SERVER_CUA_BAN>
   TTL: Automatic hoặc 3600
   ```

4. **Thêm A Record cho www (optional):**
   ```
   Type: A
   Name: www
   Value: <IP_SERVER_CUA_BAN>
   TTL: Automatic hoặc 3600
   ```

5. **Lưu thay đổi** - DNS cần 5-30 phút để cập nhật

6. **Kiểm tra DNS:**
   ```bash
   # Từ máy local
   nslookup manhuong.love
   ping manhuong.love
   ```

---

## 🚀 Bước 2: Deploy với HTTP (không SSL)

### Option A: Deploy nhanh
```bash
# Build và chạy
docker-compose up -d --build

# Kiểm tra
docker ps
curl http://manhuong.love
```

### Option B: Test local trước
```bash
# Build image
docker build -t yami-buzzy-wedding:latest .

# Run container
docker run -d \
  --name yami-buzzy-wedding \
  -p 80:80 \
  --restart unless-stopped \
  yami-buzzy-wedding:latest

# Kiểm tra logs
docker logs yami-buzzy-wedding
```

Truy cập: **http://manhuong.love**

---

## 🔒 Bước 3: Cài đặt SSL (HTTPS) - Khuyến nghị

### 3.1. Chuẩn bị
```bash
# Cấp quyền cho script
chmod +x setup-ssl.sh

# Chỉnh sửa email trong setup-ssl.sh
nano setup-ssl.sh
# Thay "your-email@example.com" bằng email của bạn
```

### 3.2. Chạy script SSL
```bash
# Chạy với quyền root
sudo ./setup-ssl.sh
```

Script sẽ:
- ✅ Cài đặt Certbot
- ✅ Tạo SSL certificate từ Let's Encrypt
- ✅ Setup auto-renewal (tự động gia hạn)

### 3.3. Cập nhật cấu hình
```bash
# Thay nginx.conf bằng nginx-ssl.conf
cp nginx-ssl.conf nginx.conf

# Rebuild với SSL
docker-compose -f docker-compose-ssl.yml up -d --build
```

### 3.4. Kiểm tra SSL
```bash
# Test HTTPS
curl https://manhuong.love

# Kiểm tra certificate
openssl s_client -connect manhuong.love:443 -servername manhuong.love
```

Truy cập: **https://manhuong.love** 🎉

---

## 🔧 Troubleshooting

### DNS chưa cập nhật
```bash
# Đợi 5-30 phút
# Kiểm tra lại
dig manhuong.love
```

### Port 80/443 đã được sử dụng
```bash
# Tìm process đang dùng port
sudo lsof -i :80
sudo lsof -i :443

# Stop process cũ
sudo systemctl stop nginx
sudo systemctl stop apache2
```

### Container không start
```bash
# Xem logs
docker logs yami-buzzy-wedding

# Xem chi tiết
docker inspect yami-buzzy-wedding

# Rebuild
docker-compose down
docker-compose up -d --build
```

### SSL certificate không hoạt động
```bash
# Kiểm tra certificate
sudo certbot certificates

# Renew thủ công
sudo certbot renew --dry-run

# Restart container
docker-compose restart
```

---

## 📊 Kiểm tra hoạt động

### Checklist
- [ ] DNS đã trỏ đúng IP
- [ ] Port 80 và 443 đã mở
- [ ] Container đang chạy (`docker ps`)
- [ ] Website truy cập được qua HTTP
- [ ] SSL certificate đã cài đặt
- [ ] Website truy cập được qua HTTPS
- [ ] HTTP tự động redirect sang HTTPS

### Test commands
```bash
# Test HTTP
curl -I http://manhuong.love

# Test HTTPS
curl -I https://manhuong.love

# Test redirect
curl -I http://manhuong.love
# Should return: 301 Moved Permanently

# Test SSL grade
curl https://www.ssllabs.com/ssltest/analyze.html?d=manhuong.love
```

---

## 🔄 Maintenance

### Auto-renewal SSL
Certificate sẽ tự động gia hạn, nhưng bạn có thể test:
```bash
# Test renewal
sudo certbot renew --dry-run

# Xem timer
systemctl list-timers | grep certbot
```

### Update website
```bash
# Pull code mới
git pull

# Rebuild
docker-compose up -d --build
```

### Backup SSL certificates
```bash
# Backup certificates
sudo tar -czf letsencrypt-backup.tar.gz /etc/letsencrypt

# Restore (nếu cần)
sudo tar -xzf letsencrypt-backup.tar.gz -C /
```

---

## 📞 Support

Nếu gặp vấn đề, kiểm tra:
1. DNS đã propagate chưa: https://dnschecker.org
2. Port đã mở chưa: https://www.yougetsignal.com/tools/open-ports/
3. SSL grade: https://www.ssllabs.com/ssltest/

---

## 🎯 Tóm tắt lệnh nhanh

```bash
# Setup cơ bản (HTTP only)
docker-compose up -d --build

# Setup đầy đủ (HTTPS)
sudo ./setup-ssl.sh
cp nginx-ssl.conf nginx.conf
docker-compose -f docker-compose-ssl.yml up -d --build

# Kiểm tra
docker ps
curl https://manhuong.love
```

Chúc mừng! Website của bạn đã sẵn sàng tại **https://manhuong.love** 🎉💒
