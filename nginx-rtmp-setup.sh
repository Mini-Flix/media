#!/bin/bash

# 스크립트 실행 시 에러 발생하면 중단
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 루트 권한 확인
if [[ $EUID -ne 0 ]]; then
   error "이 스크립트는 root 권한으로 실행되어야 합니다."
fi

# 변수 설정
NGINX_VERSION="1.23.1"
OPENSSL_VERSION="1.1.1l"
NFS_SERVER="192.168.0.102"
NFS_SHARE="/mnt/nfs_share"
LOCAL_MOUNT="/mnt/backup"
NGINX_PREFIX="/usr/local/nginx"

log "Nginx RTMP 서버 설치 스크립트를 시작합니다."

# 1. 호스트명 설정
log "호스트명을 'stream'으로 설정합니다."
hostnamectl set-hostname stream

# 2. 필요한 패키지 설치
log "필요한 패키지를 설치합니다."
dnf install -y gcc make pcre-devel zlib-devel libtool git openssl-devel perl perl-core nfs-utils

# 3. 작업 디렉토리 이동
cd /usr/local/src

# 4. Nginx 소스 다운로드
log "Nginx ${NGINX_VERSION} 다운로드 중..."
if [ ! -f "nginx-${NGINX_VERSION}.tar.gz" ]; then
    curl -LO "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
fi
tar -xzvf "nginx-${NGINX_VERSION}.tar.gz"
cd "nginx-${NGINX_VERSION}"

# 5. Nginx RTMP 모듈 클론
log "Nginx RTMP 모듈을 다운로드합니다."
if [ ! -d "nginx-rtmp-module" ]; then
    git clone https://github.com/arut/nginx-rtmp-module.git
fi

# 6. OpenSSL 다운로드 및 컴파일
log "OpenSSL ${OPENSSL_VERSION} 다운로드 및 설정 중..."
cd /usr/local/src
if [ ! -f "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
    curl -LO "https://www.openssl.org/source/old/1.1.1/openssl-${OPENSSL_VERSION}.tar.gz"
fi
tar -xzvf "openssl-${OPENSSL_VERSION}.tar.gz"

cd "openssl-${OPENSSL_VERSION}"
./config --prefix=/usr/local/openssl no-shared no-threads
make -j$(nproc)
make install

# 7. Nginx 컴파일 및 설치
log "Nginx를 컴파일하고 설치합니다."
cd "/usr/local/src/nginx-${NGINX_VERSION}"
./configure \
    --prefix=${NGINX_PREFIX} \
    --with-http_ssl_module \
    --add-module=./nginx-rtmp-module \
    --with-openssl="/usr/local/src/openssl-${OPENSSL_VERSION}"

make -j$(nproc)
make install

# 8. Nginx 버전 확인
log "Nginx 설치 확인..."
${NGINX_PREFIX}/sbin/nginx -v

# 9. NFS 마운트 설정
log "NFS 마운트를 설정합니다."
mkdir -p ${LOCAL_MOUNT}

# NFS 서버 확인
if showmount -e ${NFS_SERVER} &>/dev/null; then
    log "NFS 서버에서 공유 목록을 확인했습니다."
    mount -t nfs ${NFS_SERVER}:${NFS_SHARE} ${LOCAL_MOUNT}
    
    # 마운트 확인
    if mount | grep ${LOCAL_MOUNT} &>/dev/null; then
        log "NFS 마운트 성공!"
        chmod -R 755 ${LOCAL_MOUNT}
    else
        warning "NFS 마운트 실패. 수동으로 확인이 필요합니다."
    fi
else
    warning "NFS 서버 ${NFS_SERVER}에 연결할 수 없습니다."
fi

# 10. 방화벽 설정
log "방화벽 포트를 개방합니다."
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=8082/tcp --permanent
firewall-cmd --zone=public --add-port=8083/tcp --permanent
firewall-cmd --add-service=http --permanent
firewall-cmd --reload

# 11. SELinux 설정 (임시)
log "SELinux를 임시로 비활성화합니다."
setenforce 0

# 12. 네트워크 포워딩 설정
log "IP 포워딩을 활성화합니다."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# 13. Nginx 기본 설정 파일 생성
log "Nginx 기본 설정 파일을 생성합니다."
cat > ${NGINX_PREFIX}/conf/nginx.conf << 'EOF'
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       8080;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }

        # NFS 마운트 디렉토리 서빙
        location /backup/ {
            alias /mnt/backup/;
            autoindex on;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}

# RTMP 설정
rtmp {
    server {
        listen 1935;
        application live {
            live on;
            record off;
        }
    }
}
EOF

# 14. Nginx 시작
log "Nginx를 시작합니다."
${NGINX_PREFIX}/sbin/nginx

# 15. systemd 서비스 파일 생성
log "Nginx systemd 서비스 파일을 생성합니다."
cat > /etc/systemd/system/nginx-rtmp.service << EOF
[Unit]
Description=Nginx with RTMP module
After=network.target

[Service]
Type=forking
ExecStart=${NGINX_PREFIX}/sbin/nginx
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nginx-rtmp

# 16. 설치 완료 메시지
log "================================"
log "Nginx RTMP 서버 설치가 완료되었습니다!"
log "================================"
log "Nginx 버전: $(${NGINX_PREFIX}/sbin/nginx -v 2>&1)"
log "설치 경로: ${NGINX_PREFIX}"
log "NFS 마운트: ${LOCAL_MOUNT}"
log ""
log "서비스 상태 확인: systemctl status nginx-rtmp"
log "로그 확인: tail -f ${NGINX_PREFIX}/logs/access.log"
log ""
log "HTTP 포트: 8080"
log "RTMP 포트: 1935"
log "================================"

# 17. 마운트 영구 설정 안내
warning "NFS 마운트를 영구적으로 설정하려면 /etc/fstab에 다음 라인을 추가하세요:"
echo "${NFS_SERVER}:${NFS_SHARE} ${LOCAL_MOUNT} nfs defaults 0 0"
