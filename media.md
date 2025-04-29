인프라 구축 프로젝트 

프로젝트명: 미니 넷플릭스 인프라 구축

프로젝트 목적

- 본 과정에서 학습한 기술과 솔루션 구성 능력 배양
- 팀 프로젝트 수행을 통한 협업 능력 평가
- 개인의 학습 외적 기술 역량 수련 결과 평가

작업 이전 sudo dnf update -y 통해 시스템 패키지 최신 업데이트

**4  dnf install epel-release -y → EPEL (Extra Packages for Enterprise Linux) 저장소 활성화**

**FFMPEG** `ffmpeg`는 기본 `dnf` 저장소에 포함되지 않으므로, EPEL 저장소를 활성화
    ****

**5  dnf install**

[**https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm](https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm) -y**

FFmpeg는 EPEL 저장소에 포함되지 않기 때문에, `rpmfusion` 저장소를 추가하여 설치

RPM Fusion은 다양한 멀티미디어 소프트웨어를 제공하는 저장소

    **6  dnf install ffmpeg ffmpeg-devel -y**

    **7  ffmpeg -version
    8  dnf install ffmpeg ffmpeg-devel -y --nobest
    9  dnf install ffmpeg ffmpeg-devel -y --nobest --skip-broken
   10  ffmpeg --version
   11  ffmpeg -v
   12  systemctl status ffmpeg**

   **13  dnf config-manager --set-enabled crb**

`PowerTools` 저장소 활성화

   **14  dnf install ffmpeg ffmpeg-devel -y**

   **FFmpeg 설치**

   **15  ffmpeg --version
   16  ffmpeg -version**

**설치 및 버전 확인**

   **17  pwd
   18  ls
   19  ls -all
   20  ls /var
   21  ls -all**

   **22  ffmpeg -i sample.mp4 -vn -acodec libmp3lame sample.mp3**

   **23  ls -all
   24  ffmpeg -i sample-5s.mp4 -vn -acodec libmp3lame sample.mp3**

**예제 테스트 - 동영상에서 오디오 추출하기**

   **25  ffmpeg -i sampel-5s.mp4   -c:v libx264 -preset veryfast -crf 23   -c:a aac -b:a 128k   -f hls   -hls_time 4   -hls_playlist_type vod   stream.m3u8**

   **26  ffmpeg -f lavfi -i testsrc=duration=10:size=1280x720:rate=30 test.mp4**

**샘플 영상 준비**

   **27  ffmpeg -i test.mp4   -c:v libx264 -preset veryfast -crf 23   -c:a aac -b:a 128k   -f hls   -hls_time 4   -hls_playlist_type vod   stream.m3u8**

- `hls_time 4`: 4초 단위로 ts 분할
- `stream.m3u8`: 재생목록 파일
- `stream0.ts`, `stream1.ts` … 조각 파일 생성됨
    
    ![image.png](attachment:ee75f549-6500-48a9-a605-55e04f063336:image.png)
    

변환 성공

   **28  history
미디어처리 서버 구축 히스토리**

## ✅ 전체 목표

- **미디어 변환 서버 (`172.16.0.134`)** 에 저장된 영상 파일을
- **스트리밍 서버 (`172.16.0.135`)** 에서 NFS로 공유 및 Nginx 웹서버 통해
- **웹 브라우저로 실시간 스트리밍 가능**하게 구성

---

## 🎬 스트리밍 서버 구현 과정 (Nginx 기반)

### 1. 📁 디렉토리 생성

```bash

mkdir -p /usr/local/nginx/html/videos

```

### 2. ✅ Nginx 설치

```bash

dnf install -y nginx

```

### 3. 🔧 Nginx 설정 추가

예: `/etc/nginx/conf.d/stream.conf`

```

server {
    listen 8080;
    server_name localhost;

    location /videos/ {
        alias /usr/local/nginx/html/videos/;
        add_header Content-Type video/mp4;
        try_files $uri =404;
    }
}

```

> alias 경로는 영상이 마운트될 경로와 일치해야 합니다.
> 

### 4. ▶️ Nginx 실행/재시작

```bash

systemctl enable nginx
systemctl restart nginx

```

### 5. 🌍 확인

웹 브라우저 접속:

```

http://172.16.0.135:8080/videos/sample-5s.mp4

```

영상이 재생되면 성공

---

## 📡 NFS 공유 설정 (미디어 변환 서버 → 스트리밍 서버)

### 6. 📁 미디어 저장 디렉토리 준비 (미디어 변환 서버)

```bash

mkdir -p /home/media/videos
# mp4 파일 등 저장

```

### 7. 🔧 `/etc/exports` 수정 (미디어 변환 서버)

```bash

/home/media/videos 172.16.0.135(rw,sync,no_root_squash)

```

### 8. 🔄 NFS 서비스 적용

```bash

exportfs -ra
systemctl restart nfs-server

```

필요 시 방화벽 설정:

```bash

firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload

```

---

## 🔗 스트리밍 서버에서 NFS 마운트

### 9. 📁 마운트 지점 생성

```bash

mkdir -p /usr/local/nginx/html/videos

```

### 10. 📎 마운트 실행

```bash

mount 172.16.0.134:/home/media/videos /usr/local/nginx/html/videos

```

### 11. ✅ 마운트 확인

```bash

mount | grep videos

```

> 마운트 후에는 위에서 설정한 Nginx를 통해 /videos/로 접근 가능합니다.
> 

---

## 💡 선택 사항: HTML 플레이어 페이지 만들기

`/usr/local/nginx/html/index.html`

```html

<video width="640" height="360" controls>
  <source src="/videos/sample-5s.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

```

접속:

```

http://172.16.0.135:8080/index.html

```
