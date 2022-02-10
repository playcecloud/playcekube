# Certification

일반적으로 공인 신뢰된 CA 인증서로 부터 인증된 인증서를 사용하지만  
Private Cloud 환경을 고려 해야 하므로 사설 CA 및 사설 CA로 인증된 사설 인증서를 사용할 수 있도록 준비한다  
* 하버나 각 시스템 http UI 등의 https 인증서 생성용으로 사용
* 기본적으로 루트인증서는 따로 생성 하지 않도록 합니다. 이미 생성 되어 있어 다시 생성하면 ca가 계속 만들어져 문제 생길듯 하여...

## 설치환경 정보
Testing 환경

- OS : Rocky Linuex 8.5
- MEMORY : 16GiB
- CPU : 8core
- DISK : 200GiB
- 기본설치 PATH : /playcecloud

## 사용 모듈
사용 프로그램 정보

- OpenSSL 1.1.1k

## 설치전 확인 사항
path 설정 및 git download

```ShellSession
mkdir /playcecloud
cd /playcecloud
git clone https://github.com/playcecloud/playcekube.git
cd deployer/certification
cd PlayceKube/deployer
```

## 사설 CA 인증서

사설 CA를 만들었을 때 서버에서 편하게 사용할때는 서버의 신뢰된 인증서로 등록해주면 되며 다음과 같다  
다만, 서버의 container나 pod 안에서는 별도의 작업이 필요함

```ShellSession
# ubuntu
mkdir /usr/local/share/ca-certificates
rm -rf /usr/local/share/ca-certificates/CA/playcekube_rootca.crt
cp -rp CA/playcekube_rootca.crt /usr/local/share/ca-certificates/
update-ca-certificates

# rhel/centos
rm -rf /etc/pki/ca-trust/source/anchors/playcekube_rootca.crt
cp -rp CA/playcekube_rootca.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
```

## 사설 인증서

일반적으로 도메인 이름을 입력하며 사설 CA 인증서로 인증된 CN값으로 등록된다  
certs 디렉토리에 입력된 값.key,csr,crt 파일로 만들어진다  
(certs 위치에 같은 이름이 있으면 덮어씌워지므로 주의)

```ShellSession
./01-create-ca-signed-cert.sh www.test.com
```

SAN(Subject Alternative Name) 인증서를 만들 경우 추가 파라메터로 입력한다. 여러개 입력이 가능하며 ,로 구분  
기본적으로 main dns도 SAN 정보를 같이 입력하도록 한다(cn 확인시 SAN 정보가 없으면 맞지 않는 것으로 나옴)

```ShellSession
./01-create-ca-signed-cert.sh www.test.com DNS:www.test.com,DNS:test.com,IP:192.168.0.101
```

## 인증서 정보 확인

다양한 인증서 정보를 확인할 수 있다. 기간,issuer,옵션등

```ShellSession
openssl x509 -noout -text -in CA/playcekube_rootca.crt
openssl x509 -noout -text -in certs/www.test.com.crt
```

