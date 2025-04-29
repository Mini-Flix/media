넷플릭스 인프라 구축 프로젝트 (2)

내부 서버 라우터 통신 시도

내가 만든 내부 서버: DNS, 스트리밍, 미디어 변환, 백업 (예정)

### ✅ **백업 서버의 핵심 역할**

1. **미디어 파일 백업**
    - 변환 완료된 mp4 등 콘텐츠 파일을 주기적으로 저장해 원본이 손상되거나 삭제될 경우 복원 가능하게 함.
2. **DB 백업**
    - 사용자 정보, 시청 기록, 로그 등 중요한 데이터베이스 백업.
3. **구성 설정/애플리케이션 백업**
    - nginx, FFmpeg 설정 등 스트리밍 환경의 설정 파일들 백업.
4. **재해 복구(Disaster Recovery)**
    - 스트리밍 서버가 장애로 다운될 경우 빠르게 콘텐츠 제공을 재개할 수 있는 준비된 인프라.

---

### 🏆 **추천 방식: rsync 기반 파일 백업 서버**

**rsync**는 빠르고 효율적인 증분 백업 도구로, 미디어 파일 백업에 최적화되어 있습니다.

---

## 🛠️ **구축 방법 요약**

### 1. **백업 서버 준비**

- Rocky9 기반 서버 1대 준비 (`hostname: backup`, IP: 예시 `172.16.0.136`)
- `/mnt/backup/videos` 디렉토리 생성

```bash
bash

mkdir -p /mnt/backup/videos

```

---

### 2. **스트리밍 서버에서 rsync 설치 및 백업 스크립트 작성**

```bash
bash

dnf install -y rsync

```

**예시 백업 스크립트 (`/usr/local/bin/backup_videos.sh`)**:

```bash
bash

#!/bin/bash
rsync -avz --delete /usr/local/nginx/html/videos/ root@172.16.0.136:/mnt/backup/videos/

```

```bash
bash

chmod +x /usr/local/bin/backup_videos.sh

```

---

### 3. **SSH 비밀번호 없이 자동 백업 설정**

```bash
bash

# 스트리밍 서버에서
ssh-keygen -t rsa  # 엔터 연타로 진행
ssh-copy-id root@172.16.0.136

```

---

### 4. **크론탭에 주기적 백업 등록 (예: 30분마다)**

```bash
bash

crontab -e

```

```
cron

*/30 * * * * /usr/local/bin/backup_videos.sh

```

---

### 5. **백업 서버에서 공유 확인**

```bash
bash

ls /mnt/backup/videos/

```

미디어 파일들이 백업되고 있는지 확인할 수 있습니다.

---

### 💡 추가 팁

- rsync 외에도 **BorgBackup, Duplicity, Restic** 등의 백업 도구도 활용 가능하지만, 단순 파일 백업은 rsync가 빠르고 직관적입니다.
- 보안과 무결성을 위해 **rsync + SSH + 로그 기록** 설정을 추가하는 것도 권장됩니다.

---

필요하시면 `DB 백업`까지 통합하는 방법도 알려드릴게요.

어떻게 도와드릴까요? (ex. mariadb/mysql 백업도 함께?)

4o

### 나의 말:

[root@stream ~]# rsync -avz --delete /usr/local/nginx/html/videos/ root@172.16.0.136:/mnt/backup/videos/
The authenticity of host '172.16.0.136 (172.16.0.136)' can't be established.
ED25519 key fingerprint is SHA256:SO8721Pr4KdO6BHUGDzx+SzJgF6A5YRQINzT4k/J3MA.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '172.16.0.136' (ED25519) to the list of known hosts.
root@172.16.0.136's password:
bash: line 1: rsync: command not found
rsync: connection unexpectedly closed (0 bytes received so far) [sender]
rsync error: error in rsync protocol data stream (code 12) at io.c(228) [sender=3.2.3]

### ChatGPT의 말:

지금 오류 메시지를 보면 **백업 서버(172.16.0.136)** 쪽에 `rsync` 명령어가 설치되어 있지 않아서 생긴 문제입니다:

```

bash: line 1: rsync: command not found

```

---

### ✅ 해결 방법: 백업 서버에 `rsync` 설치

백업 서버에 접속해서 아래 명령어를 실행해 주세요:

```bash
bash

dnf install -y rsync

```

설치 후 다시 스트리밍 서버에서 백업 명령어를 실행하시면 정상적으로 작동할 것입니다:

```bash
bash

rsync -avz --delete /usr/local/nginx/html/videos/ root@172.16.0.136:/mnt/backup/videos/

```

---

필요하시면 성공적으로 복사되었는지 백업 서버에서 다음 명령어로 확인도 가능합니다:

```bash
bash

ls /mnt/backup/videos/

```

이후 `ssh-key` 등록도 했으니 비밀번호 입력 없이 cron에 등록해 자동화도 바로 가능할 거예요.

진행하다 다른 오류나 백업 자동화 관련해 궁금한 점 있으면 말씀 주세요!

4o

### 나의 말:

chmod +x /usr/local/bin/backup_videos.sh  이 스크립트는 어떻게 만들지?

### ChatGPT의 말:

좋습니다! `chmod +x /usr/local/bin/backup_videos.sh`는 스크립트 파일에 실행 권한을 부여하는 명령어이고, 그 전에 **`backup_videos.sh` 스크립트 자체를 만들어야** 하죠.

---

### ✅ 1. 백업 스크립트 만들기

아래 명령어로 파일을 만듭니다:

```bash
bash

nano /usr/local/bin/backup_videos.sh

```

그 다음 아래 내용을 붙여 넣으세요 (원하는 대로 경로만 조정):

```bash
bash

#!/bin/bash

# 날짜 찍기 (로그용)
echo "=== 백업 시작: $(date) ==="

# rsync 명령어
rsync -avz --delete /usr/local/nginx/html/videos/ root@172.16.0.136:/mnt/backup/videos/

# 종료 로그
echo "=== 백업 종료: $(date) ==="

```

> Ctrl + O → 저장, Enter → Ctrl + X → 종료
> 

---

### ✅ 2. 실행 권한 부여

```bash
bash

chmod +x /usr/local/bin/backup_videos.sh

```

---

### ✅ 3. 실행 테스트

```bash
bash

/usr/local/bin/backup_videos.sh

```

정상적으로 실행되고 파일이 복사되면 성공입니다!

---

### ✨ 다음 단계: 자동화하고 싶으면?

자동 백업 원하시면 crontab에 등록하면 됩니다. 원하실 경우 도와드릴게요!

필요하시면 `log` 남기는 방식이나 실패 시 알림 설정도 추가해드릴 수 있어요.

4o

### 나의 말:

nano 대체 명령어

### ChatGPT의 말:

`nano`는 간편한 텍스트 편집기지만, 시스템에 없을 수도 있으니 아래처럼 대체 편집기를 사용할 수 있습니다:

---

### 🔹 1. `vi` 또는 `vim` (거의 모든 리눅스에 기본 설치)

```bash
bash

vi /usr/local/bin/backup_videos.sh

```

### 입력 방법:

- **i** : 입력 모드 진입
- 스크립트 내용 붙여넣기
- **Esc** → **:wq** → 엔터 : 저장하고 종료

---

### 🔹 2. `echo` + 리디렉션 방식 (간단한 파일 생성용)

```bash
bash

cat << 'EOF' > /usr/local/bin/backup_videos.sh
#!/bin/bash

echo "=== 백업 시작: $(date) ==="
rsync -avz --delete /usr/local/nginx/html/videos/ root@172.16.0.136:/mnt/backup/videos/
echo "=== 백업 종료: $(date) ==="
EOF

```

그 다음 권한 부여:

```bash
bash

chmod +x /usr/local/bin/backup_videos.sh

```

---

어떤 방식이 편하신가요? 자동화도 같이 진행해드릴까요?

4o

### 나의 말:

crontab까지 마치면 /usr/local/nginx/html/videos/ 경로의 영상 파일이 /mnt/backup/videos/에 30분 주기마다 저장이 되는거야?

### ChatGPT의 말:

맞습니다! 🎉

`crontab`에 해당 스크립트를 30분 주기로 등록하면 아래 경로의 파일이:

```
swift

/usr/local/nginx/html/videos/

```

→ 자동으로 백업 서버의 이 경로로:

```
ruby

172.16.0.136:/mnt/backup/videos/

```

**30분마다 동기화**되며 저장됩니다.

---

### ✅ 요약 흐름

1. `backup_videos.sh` 스크립트가 `rsync` 명령어를 실행함
2. `/usr/local/nginx/html/videos/` 디렉토리의 모든 파일을 원격 서버의 `/mnt/backup/videos/`로 전송
3. `-delete` 옵션 덕분에 원본에서 삭제된 파일은 백업 서버에서도 삭제되어 **양쪽이 완전히 동기화**됨
4. `crontab`을 통해 30분마다 반복 실행

---

### 예시 crontab 설정 확인

```bash
bash

crontab -e

```

그리고 아래 줄이 있다면 설정 OK:

```
ruby

*/30 * * * * /usr/local/bin/backup_videos.sh >> /var/log/backup_videos.log 2>&1

```

> 로그도 /var/log/backup_videos.log에 저장돼서 나중에 백업 상태도 확인할 수 있어요.
> 

---

필요하다면 자동 로그인용 SSH 키 설정도 알려드릴게요.

(root 비번 안 물어보게 하려면 필수!)

4o

### 나의 말:

혹시 전원이 종료 되거나 재시작 시에도 설정은 유지가 되는감?

### ChatGPT의 말:

좋은 질문입니다! 💡

### ✅ 결론부터 말씀드리면:

**네, 서버 전원 종료나 재시작이 발생해도 `crontab`에 등록된 작업과 `backup_videos.sh` 스크립트는 그대로 유지됩니다.**

---

### 🔒 왜 유지되나요?

- `crontab -e`로 등록한 작업은 해당 사용자(여기선 `root`)의 **크론 데몬** 설정에 저장됩니다.
    
    이 설정은 `/var/spool/cron/root` 같은 시스템 경로에 저장되므로 **재부팅돼도 사라지지 않아요.**
    
- `backup_videos.sh` 스크립트도 `/usr/local/bin/`에 있는 한 시스템 재부팅 후에도 사용할 수 있습니다.
    
    단, **파일 시스템이 정상적으로 마운트되고**, 해당 경로가 삭제되지 않았을 경우에 한해요.
    

---

### ⚠️ 단, 주의할 점

1. **백업 대상 경로(`/usr/local/nginx/html/videos/`)** 또는
    
    **백업 목적지(`/mnt/backup/videos/`)**가 **마운트된 디스크**일 경우:
    
    > 부팅 시 자동 마운트 설정(fstab or systemd mount unit)이 되어 있어야 해요.
    > 
    
    그렇지 않으면 **스크립트 실행 시 경로가 없어서 오류 발생**합니다.
    
2. **네트워크 문제**
    
    재부팅 이후 백업 서버(`172.16.0.136`)에 SSH 접속이 실패하면 `rsync`도 실패합니다.
    

---

### ✅ 체크리스트

- [x]  `backup_videos.sh`는 `/usr/local/bin/`에 있고, 실행 권한 있음
- [x]  `crontab -e`로 등록 완료
- [x]  백업 서버 경로 `/mnt/backup/videos/`는 정상 마운트되고 존재함
- [x]  SSH 인증은 패스워드 or 공개키 방식으로 설정됨
- [x]  양쪽 서버의 시간이 비슷하게 설정됨 (백업 파일 비교에 중요)

---

필요하시면 `fstab` 자동 마운트 설정이나, SSH 키 기반 무인 로그인 설정도 도와드릴게요! 😄

# [root@stream ~]# dnf install -y rsync
Rocky Linux 9 - BaseOS 857 B/s | 4.1 kB 00:04
Rocky Linux 9 - AppStream 946 B/s | 4.5 kB 00:04
Rocky Linux 9 - Extras 625 B/s | 2.9 kB 00:04
Dependencies resolved.

# Package Architecture Version Repository Size

Installing:
rsync                                         x86_64                                         3.2.3-20.el9_5.1                                           baseos                                         391 k

# Transaction Summary

Install  1 Package

## Total download size: 391 k
Installed size: 743 k
Downloading Packages:
rsync-3.2.3-20.el9_5.1.x86_64.rpm 184 kB/s | 391 kB 00:02

Total                                                                                                                                                                          81 kB/s | 391 kB     00:04
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
Preparing        :                                                                                                                                                                                      1/1
Installing       : rsync-3.2.3-20.el9_5.1.x86_64                                                                                                                                                        1/1
Running scriptlet: rsync-3.2.3-20.el9_5.1.x86_64                                                                                                                                                        1/1
Verifying        : rsync-3.2.3-20.el9_5.1.x86_64                                                                                                                                                        1/1

Installed:
rsync-3.2.3-20.el9_5.1.x86_64

Complete!
[root@stream ~]# rsync -avz --delete /usr/local/nginx/html/videos/ [root@172.16.0.136](mailto:root@172.16.0.136):/mnt/backup/videos/
The authenticity of host '172.16.0.136 (172.16.0.136)' can't be established.
ED25519 key fingerprint is SHA256:SO8721Pr4KdO6BHUGDzx+SzJgF6A5YRQINzT4k/J3MA.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '172.16.0.136' (ED25519) to the list of known hosts.
[root@172.16.0.136](mailto:root@172.16.0.136)'s password:
bash: line 1: rsync: command not found
rsync: connection unexpectedly closed (0 bytes received so far) [sender]
rsync error: error in rsync protocol data stream (code 12) at io.c(228) [sender=3.2.3]
[root@stream ~]# ^C
[root@stream ~]# rsync -avz --delete /usr/local/nginx/html/videos/ [root@172.16.0.136](mailto:root@172.16.0.136):/mnt/backup/videos/
[root@172.16.0.136](mailto:root@172.16.0.136)'s password:
sending incremental file list
./
sample-5s.mp4
sample.mp4

sent 25,881,871 bytes  received 57 bytes  5,751,539.56 bytes/sec
total size is 25,896,319  speedup is 1.00
[root@stream ~]#
[root@stream ~]# chmod +x /usr/local/bin/backup_videos.sh
chmod: cannot access '/usr/local/bin/backup_videos.sh': No such file or directory
[root@stream ~]# nano /usr/local/bin/backup_videos.shnano /usr/local/bin/backup_videos.sh^C
[root@stream ~]# nano /usr/local/bin/backup_videos.sh
-bash: nano: command not found
[root@stream ~]# vi /usr/local/bin/backup_videos.sh
[root@stream ~]# chmod +x /usr/local/bin/backup_videos.sh
[root@stream ~]# /usr/local/bin/backup_videos.sh
=== 백업 시작: Fri Apr 25 09:44:36 AM KST 2025 ===
[root@172.16.0.136](mailto:root@172.16.0.136)'s password:
sending incremental file list

sent 119 bytes  received 12 bytes  20.15 bytes/sec
total size is 25,896,319  speedup is 197,681.82
=== 백업 종료: Fri Apr 25 09:44:42 AM KST 2025 ===
[root@stream ~]# ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:LCosGGapqL/BIRTLvDg3DoaXdlz1daDzwNshbMUxQRk root@stream
The key's randomart image is:
+---[RSA 3072]----+
| .      .  oE*.  |
|o o    . + +oo   |
| =    .   X .    |
|+ oo . . . B .   |
|B*B o . S . o    |
|B% + . .         |
|= * .            |
|.. o             |
|..o.             |
+----[SHA256]-----+
[root@stream ~]#
[root@stream ~]# ssh-copy-id [root@172.16.0.136](mailto:root@172.16.0.136)
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
[root@172.16.0.136](mailto:root@172.16.0.136)'s password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@172.16.0.136'"
and check to make sure that only the key(s) you wanted were added.

[root@stream ~]#
[root@stream ~]#
[root@stream ~]# crontab -e
no crontab for root - using an empty one
crontab: installing new crontab

stream 포트 점유

좋은 질문입니다! 🎯 **스트리밍 서버에서 특정 포트(예: 8080, 8081 등)를 다른 프로세스가 점유하지 못하도록 '단독 점유'하는 방법**은 운영 환경을 안정적으로 유지하는 데 매우 중요합니다.

---

## ✅ 단독 점유 방법 요약

### 1. **SELinux 또는 방화벽으로 포트 접근 제한**

- **방화벽(Firewalld)** 또는 **iptables**로 외부에서 해당 포트를 접근 못 하도록 막고, **Nginx만 접근** 가능하게 구성.
- 예시 (firewalld 사용 시):
    
    ```bash
    firewall-cmd --zone=public --add-port=8081/tcp --permanent
    firewall-cmd --reload
    
    ```
    

### 2. **포트 점유 프로세스 확인 및 차단**

- 부팅 시 해당 포트를 선점하는 다른 서비스가 있다면 제거하거나 충돌 방지 필요.
- 포트 사용 확인:
    
    ```bash
    sudo ss -tuln
    sudo netstat -tulnp | grep 8081
    
    ```
    
- 불필요한 서비스가 점유 중이면:
    
    ```bash
    sudo systemctl stop <service_name>
    sudo systemctl disable <service_name>
    
    ```
    

### 3. **Nginx를 시스템 부팅 시 가장 먼저 실행**

- `nginx.service`에 `Before=` 또는 `After=` directive 설정 가능
- 혹은 `systemctl enable nginx`로 부팅 시 자동 실행 설정.

```bash
sudo systemctl enable nginx

```

### 4. **보안 포트 제한 및 Nginx 권한 상승**

- **Linux에서는 1024 미만 포트**는 root만 열 수 있음. 그러나 1024 이상의 포트(8081 등)는 제한 없음.
- 다만, systemd 환경에서는 **포트 바인딩 권한(cap_net_bind_service)** 같은 특수 권한도 설정 가능:
    
    ```bash
    sudo setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx
    
    ```
    

---

## 💡 추가 팁: 충돌 방지용 고정 포트 예약 방법

시스템 레벨에서 특정 포트를 Nginx만 사용하도록 보장하는 강력한 방법은 없지만, 다음을 조합해 **사실상 단독 점유에 가까운 상태**를 만들 수 있습니다:

- 해당 포트를 사용하는 다른 서비스를 `disable`
- systemd로 Nginx 우선 실행
- 포트 사용 여부를 스크립트로 정기 확인 (예: cron + lsof 체크)

---

나중에 dns 서버를 통해 스트리밍 서버의 도메인 주소를 받았을 때는, 172.16.0.135:8083/videos/smaple.mp4의 주소는 어떻게 변환이 될까? 부여하려는 도메인 주소는 stream.mini.netflix야

### ChatGPT의 말:

좋은 질문입니다! 나중에 DNS를 통해 `stream.mini.netflix`이라는 도메인 주소를 부여하면, 기존의 IP 주소 기반 URL인:

```
arduino
복사편집
http://172.16.0.135:8083/videos/sample.mp4

```

은 도메인을 이용해 다음과 같이 **바뀌게 됩니다**:

---

### ✅ 도메인 적용 후 주소

```
bash
복사편집
http://stream.mini.netflix:8083/videos/sample.mp4

```

---

### 🔍 왜 포트 번호는 그대로 남아있을까?

- DNS는 **IP 주소 → 도메인명**을 바꿔주는 역할만 합니다.
- Nginx가 여전히 **8083 포트에서 서비스 중**이라면, 접속하는 쪽에서도 여전히 `:8083` 포트를 써야 합니다.
- 단, **80 또는 443 포트(HTTP/HTTPS 기본 포트)** 를 쓰게 되면 포트를 생략할 수 있습니다:
    
    예시:
    
    ```
    arduino
    복사편집
    http://stream.mini.netflix/videos/sample.mp4      ← 80 포트일 때
    https://stream.mini.netflix/videos/sample.mp4     ← 443 포트일 때 (SSL 인증서 필요)
    
    ```
    

---

### 🛠 포트를 생략하고 싶다면?

1. Nginx에서 `listen 8083;` → `listen 80;` 또는 `listen 443 ssl;` 로 변경
2. 방화벽과 SELinux 설정 확인
3. 80/443 포트는 root 권한이 필요 → `setcap`을 통해 권한 설정 가능
4. 443 포트 사용 시 SSL 인증서 필요 (예: Let's Encrypt)

---

필요하다면 `80/443 포트로 변경하는 방법`, `Let's Encrypt 설정법`, `DNS 레코드 설정 방법 (예: Route 53, Cloudflare)` 도 도와드릴게요!

원하는 방향 알려주세요 :)

[웹 사용자]
↓
[웹 요청] http://stream.mini.netflix/videos/sample.mp4
↓
[NGINX 스트리밍 서버]
↓ (없으면)
[NFS로 연결된 디렉토리에서 확인]
↓
[미디어 변환 서버] ← (자동 감지)
↑
[NFS 공유 디렉토리]
↑
[DB 서버 → NFS 경유 → 원본 sample.mp4 업로드]

지금 해야 하는 것..

저 짝에서는 일단 트랜스코딩 서버 ↔ 스트리밍 서버 마운트 되어 있음.

```jsx
172.16.0.134 #트랜스코딩:/home/media/videos on /usr/local/nginx/html/videos #스트리밍서버 디렉토리 type nfs4 (...)
```

NFS 서버 현재 미구축 

목표: 

```
[트랜스코딩 서버] ←→ [NFS 서버] ←→ [스트리밍 서버]
                     ↑
                     ↓
                  [DB 서버]

```

트랜스코딩과 스트리밍 마운트 파일 지정
