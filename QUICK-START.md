# 🚀 Quick Deployment Guide

## 📋 Yêu cầu
- Server Ubuntu với Docker đã cài đặt
- Domain đã trỏ DNS về IP server
- SSH access vào server

---

## 🌐 Deploy HTTP (không SSL)

### Bước 1: Cấu hình DNS
Tại nhà cung cấp domain, tạo A Record:
```
Type: A
Name: @ (hoặc để trống)
Value: <IP_SERVER>
TTL: 3600
```

### Bước 2: Deploy
```bash
./deploy.sh <SERVER_IP> <SERVER_USER>

# Ví dụ:
./deploy.sh 45.119.87.94 ubuntu
```

✅ Website sẽ chạy tại: **http://your-domain.com**

---

## 🔒 Deploy HTTPS (với SSL)

### Bước 1: Cấu hình DNS (nếu chưa làm)
Giống như phần HTTP ở trên

### Bước 2: Setup SSL (chỉ làm 1 lần)
```bash
./setup-ssl-server.sh <SERVER_IP> <SERVER_USER> <DOMAIN> <EMAIL>

# Ví dụ:
./setup-ssl-server.sh 45.119.87.94 ubuntu manhuong.love admin@manhuong.love
```

Script sẽ:
- ✅ Cài đặt Certbot
- ✅ Lấy SSL certificate từ Let's Encrypt
- ✅ Setup auto-renewal

### Bước 3: Deploy với SSL
```bash
./deploy.sh <SERVER_IP> <SERVER_USER> --with-ssl

# Ví dụ:
./deploy.sh 45.119.87.94 ubuntu --with-ssl
```

✅ Website sẽ chạy tại: **https://your-domain.com**  
✅ HTTP tự động redirect sang HTTPS

---

## 🔄 Update Website

Sau khi thay đổi code, chạy lại deploy:

### HTTP:
```bash
./deploy.sh 45.119.87.94 ubuntu
```

### HTTPS:
```bash
./deploy.sh 45.119.87.94 ubuntu --with-ssl
```

---

## 📊 Kiểm tra

### Kiểm tra container đang chạy:
```bash
ssh ubuntu@<SERVER_IP> "docker ps"
```

### Xem logs:
```bash
ssh ubuntu@<SERVER_IP> "docker logs -f yami-buzzy-wedding"
```

### Test SSL:
```bash
curl -I https://your-domain.com
```

### Kiểm tra SSL certificate:
```bash
ssh ubuntu@<SERVER_IP> "sudo certbot certificates"
```

---

## 🛠️ Troubleshooting

### Container không start:
```bash
ssh ubuntu@<SERVER_IP> "docker logs yami-buzzy-wedding"
```

### SSL không hoạt động:
```bash
# Kiểm tra nginx config
ssh ubuntu@<SERVER_IP> "docker exec yami-buzzy-wedding nginx -t"

# Kiểm tra certificate
ssh ubuntu@<SERVER_IP> "sudo certbot certificates"
```

### Port đã được sử dụng:
```bash
ssh ubuntu@<SERVER_IP> "docker ps"
ssh ubuntu@<SERVER_IP> "docker stop yami-buzzy-wedding"
```

---

## 📁 File Structure

```
.
├── deploy.sh                  # Main deployment script
├── setup-ssl-server.sh        # SSL setup script (run once)
├── nginx.conf                 # NGINX config for HTTP
├── nginx-ssl.conf             # NGINX config for HTTPS
├── index.html                 # Main website file
├── wp-content/                # Website assets
├── wp-includes/               # Website dependencies
├── DOMAIN-SETUP.md           # Detailed domain setup guide
└── SSL-MANUAL-INSTALL.md     # Manual SSL installation guide
```

---

## 🎯 Quick Reference

| Task | Command |
|------|---------|
| Deploy HTTP | `./deploy.sh <IP> <USER>` |
| Setup SSL (once) | `./setup-ssl-server.sh <IP> <USER> <DOMAIN> <EMAIL>` |
| Deploy HTTPS | `./deploy.sh <IP> <USER> --with-ssl` |
| View logs | `ssh <USER>@<IP> "docker logs -f yami-buzzy-wedding"` |
| Restart | `ssh <USER>@<IP> "docker restart yami-buzzy-wedding"` |
| Check SSL | `ssh <USER>@<IP> "sudo certbot certificates"` |

---

## 🆘 Support

Chi tiết đầy đủ:
- **Domain setup**: Xem `DOMAIN-SETUP.md`
- **SSL manual install**: Xem `SSL-MANUAL-INSTALL.md`
- **Full deployment guide**: Xem `DEPLOYMENT.md`

---

## ✅ Checklist

- [ ] DNS đã trỏ về server
- [ ] Server có Docker
- [ ] SSH access hoạt động
- [ ] Port 80/443 đã mở (nếu có firewall)
- [ ] (Nếu dùng SSL) Đã chạy `setup-ssl-server.sh`
- [ ] Đã chạy `deploy.sh`
- [ ] Website truy cập được

**Chúc mừng! Website của bạn đã sẵn sàng! 🎉**
