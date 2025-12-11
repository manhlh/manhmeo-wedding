# 🔒 Hướng dẫn cài SSL thủ công cho manhuong.love

## Bước 1: SSH vào server
```bash
ssh ubuntu@45.119.87.94
```

## Bước 2: Dừng container hiện tại
```bash
docker stop yami-buzzy-wedding
docker rm yami-buzzy-wedding
```

## Bước 3: Cài đặt Certbot (nếu chưa có)
```bash
sudo apt update
sudo apt install -y certbot
```

## Bước 4: Lấy SSL Certificate
```bash
# Chỉ dùng domain chính (không có www)
sudo certbot certonly --standalone \
    -d manhuong.love \
    --agree-tos \
    --email admin@manhuong.love
```

**Lưu ý:** Nếu muốn thêm www.manhuong.love, bạn cần tạo thêm DNS A Record cho www trước.

Certbot sẽ hỏi:
- Nhấn **Y** để đồng ý Terms of Service
- Nhập email của bạn
- Chờ certificate được tạo (khoảng 30 giây)

## Bước 5: Kiểm tra certificate đã tạo
```bash
sudo certbot certificates
```

Bạn sẽ thấy:
```
Certificate Name: manhuong.love
  Domains: manhuong.love www.manhuong.love
  Expiry Date: 2026-03-11 (VALID: 89 days)
  Certificate Path: /etc/letsencrypt/live/manhuong.love/fullchain.pem
  Private Key Path: /etc/letsencrypt/live/manhuong.love/privkey.pem
```

## Bước 6: Chạy container với SSL
```bash
# Chạy container với SSL certificate mount
docker run -d \
  --name yami-buzzy-wedding \
  -p 80:80 \
  -p 443:443 \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  --restart unless-stopped \
  yami-buzzy-wedding:ssl
```

## Bước 7: Kiểm tra
```bash
# Kiểm tra container đang chạy
docker ps | grep yami

# Kiểm tra logs
docker logs yami-buzzy-wedding

# Test HTTPS từ server
curl -k https://localhost
```

## Bước 8: Setup Auto-renewal
```bash
# Enable certbot timer
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Kiểm tra timer
systemctl list-timers | grep certbot
```

## Bước 9: Test renewal (optional)
```bash
sudo certbot renew --dry-run
```

---

## ✅ Xong! 

Truy cập:
- **HTTP**: http://manhuong.love (sẽ redirect sang HTTPS)
- **HTTPS**: https://manhuong.love

## 🔧 Troubleshooting

### Nếu gặp lỗi "port 80 already in use":
```bash
docker stop yami-buzzy-wedding
sudo certbot certonly --standalone -d manhuong.love -d www.manhuong.love
docker start yami-buzzy-wedding
```

### Nếu certificate không hoạt động:
```bash
# Kiểm tra nginx config
docker exec yami-buzzy-wedding nginx -t

# Xem logs chi tiết
docker logs -f yami-buzzy-wedding
```

### Kiểm tra SSL grade:
Truy cập: https://www.ssllabs.com/ssltest/analyze.html?d=manhuong.love
