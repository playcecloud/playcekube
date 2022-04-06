#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# data dir create
mkdir -p ${PLAYCE_DATADIR}

# function call
. ${PLAYCE_DIR}/playcekube/deployer/scripts/playcekube_common.sh
# check info
CHECKOSFAMILY=$(getOSFamily)
CHECKOSVERSION=$(getOSVersion)

# set package manager
PKGCMD=yum
if [[ "${CHECKOSFAMILY}" == "centos" ]] && [[ "${CHECKOSVERSION}" == "8" ]]; then
  PKGCMD=dnf
fi

# timezone
timedatectl set-timezone Asia/Seoul

# selinux disable
sed -i "s/^SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
setenforce 0

# firewalld disable
#systemctl disable firewalld --now

# ca-trust update
cp -rp ${PLAYCE_DIR}/playcekube/deployer/certification/CA/playcekube_rootca.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

if ! isOnline; then

if [[ "${CHECKOSFAMILY}" == "centos" ]]; then
mkdir -p /etc/yum.repos.d/backup-$(date +%Y%m%d)
mv /etc/yum.repos.d/CentOS* /etc/yum.repos.d/backup-$(date +%Y%m%d)
mv /etc/yum.repos.d/Rocky* /etc/yum.repos.d/backup-$(date +%Y%m%d)

# docker-ce
cat << EOF > /etc/yum.repos.d/docker-ce-stable.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=file://${PLAYCE_DATADIR}/repositories/${CHECKOSFAMILY}${CHECKOSVERSION}/docker-ce-stable
enabled=1
gpgcheck=0
EOF

  if [[ "${MAJOR_VERSION}" == "8" ]]; then

# baseos, appstream
cat << EOF > /etc/yum.repos.d/base.repo
[baseos]
name=Rocky Linux \$releasever - BaseOS
baseurl=file://${PLAYCE_DATADIR}/repositories/${CHECKOSFAMILY}${CHECKOSVERSION}/baseos
enabled=1
gpgcheck=0

[appstream]
name=Rocky Linux \$releasever - AppStream
baseurl=file://${PLAYCE_DATADIR}/repositories/${CHECKOSFAMILY}${CHECKOSVERSION}/appstream
enabled=1
gpgcheck=0

[extras]
name=Rocky Linux \$releasever - Extras
baseurl=file://${PLAYCE_DATADIR}/repositories/${CHECKOSFAMILY}${CHECKOSVERSION}/extras
enabled=1
gpgcheck=0
EOF

  else

# centos7 base
cat << EOF > ${PLAYCE_DATADIR}/repositories/centos7/base.repo
[base]
name=CentOS-\$releasever - Base
baseurl=file://${PLAYCE_DATADIR}/repositories/${CHECKOSFAMILY}${CHECKOSVERSION}/base
enabled=1
gpgcheck=0

[updates]
name=CentOS-\$releasever - Updates
baseurl=file://${PLAYCE_DATADIR}/repositories/${CHECKOSFAMILY}${CHECKOSVERSION}/updates
enabled=1
gpgcheck=0

[extras]
name=CentOS-\$releasever - Extras
baseurl=file://${PLAYCE_DATADIR}/repositories/${CHECKOSFAMILY}${CHECKOSVERSION}/extras
enabled=1
gpgcheck=0
EOF

[epel]
name=CentOS-\$releasever - EPEL
baseurl=file://${PLAYCE_DATADIR}/repositories/${CHECKOSFAMILY}${CHECKOSVERSION}/epel
enabled=1
gpgcheck=0
EOF

  fi
fi

# is online
else

  if [[ "${CHECKOSVERSION}" == "7" ]]; then
    yum -y install createrepo yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  elif [[ "${CHECKOSVERSION}" == "8" ]]; then
    dnf -y install dnf-plugins-core yum-utils createrepo
    dnf -y config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  fi

fi

# duplicate remove
${PKGCMD} -y remove dnsmasq podman libvirt
${PKGCMD} clean all

# requirements install
${PKGCMD} -y install jq tar git wget

# install docker-ce
${PKGCMD} -y install docker-ce
systemctl enable docker --now
systemctl restart docker

# service container download
if [[ ! -f ${PLAYCE_DATADIR}/base-service-containers.tar ]]; then
  docker pull docker.io/library/nginx:1.20.2
  docker pull docker.io/library/registry:2.7.1
  docker pull docker.io/ubuntu/bind9:9.16-21.10_edge

  docker save -o ${PLAYCE_DATADIR}/base-service-containers.tar docker.io/library/nginx:1.20.2 docker.io/library/registry:2.7.1 docker.io/ubuntu/bind9:9.16-21.10_edge
else
  docker load -i ${PLAYCE_DATADIR}/base-service-containers.tar
fi

# chrony config
sed -i "s/^#allow .*/allow 0.0.0.0\/0/g" /etc/chrony.conf
sed -i "s/^#local stratum .*/local stratum 8/g" /etc/chrony.conf

# chrony start
systemctl enable chronyd --now
systemctl restart chronyd

# sync
chronyc sources

# certs dir create
mkdir -p ${PLAYCE_DIR}/playcekube/deployer/certification/certs
mkdir -p ${PLAYCE_DIR}/playcekube/deployer/certification/intermediateCA
sed "s|^dir =.*|dir = ${PLAYCE_DIR}/playcekube/deployer/certification|" ${PLAYCE_DIR}/playcekube/deployer/certification/openssl_certs.cnf

# bind9 config
mkdir -p ${PLAYCE_DIR}/playcekube/deployer/bind9/{config,cache,records}
chown 0:101 ${PLAYCE_DIR}/playcekube/deployer/bind9/{config,cache,records}
chmod 775 ${PLAYCE_DIR}/playcekube/deployer/bind9/{cache,records}


cat << EOF > ${PLAYCE_DIR}/playcekube/deployer/bind9/config/named.conf
options {
        directory "/var/cache/bind";

        forwarders {
               ${UPSTREAM_DNS}; 
        };

        dnssec-validation auto;

        listen-on port 8053 { any; };
        listen-on-v6 port 8053 { any; };
        allow-query     { any; };

};

zone "${PLAYCE_DOMAIN}" IN {
        type master;
        file "named.${PLAYCE_DOMAIN}.zone";
};

include "/etc/bind/named.kubernetes.zones";
EOF

touch ${PLAYCE_DIR}/playcekube/deployer/bind9/config/named.kubernetes.zones

cat << EOF > ${PLAYCE_DIR}/playcekube/deployer/bind9/cache/named.${PLAYCE_DOMAIN}.zone
\$ORIGIN ${PLAYCE_DOMAIN}.
\$TTL 86400      ; 1 day
@                               IN SOA   ns.${PLAYCE_DOMAIN}. root.${PLAYCE_DOMAIN}. (
                                $(date +%Y%m%d)01  ; serial
                                10800       ; refresh (3 hours)
                                900         ; retry (15 minutes)
                                604800      ; expire (1 week)
                                86400       ; minimum (1 day)
                                )
                                NS ns.${PLAYCE_DOMAIN}.


; base ttl, dns
\$TTL 604800
@                               IN A ${PLAYCE_DEPLOYER}

; 1 day cache dns
\$TTL 86400
ns                              IN A ${PLAYCE_DEPLOYER}

; deployer
registry                        IN A ${PLAYCE_DEPLOYER}
repositories                    IN A ${PLAYCE_DEPLOYER}
repository                      IN A ${PLAYCE_DEPLOYER}

EOF

# registry config
mkdir -p ${PLAYCE_DIR}/playcekube/deployer/registry
mkdir -p ${PLAYCE_DATADIR}/registry

# registry certs copy
rm -rf ${PLAYCE_DIR}/playcekube/deployer/registry/registry.${PLAYCE_DOMAIN}.*
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh registry.${PLAYCE_DOMAIN} DNS:registry.${PLAYCE_DOMAIN},DNS:localhost,IP:${PLAYCE_DEPLOYER}
cp -rp ${PLAYCE_DIR}/playcekube/deployer/certification/certs/registry.${PLAYCE_DOMAIN}.* ${PLAYCE_DIR}/playcekube/deployer/registry/


cat << EOF > ${PLAYCE_DIR}/playcekube/deployer/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
  tls:
    certificate: /etc/docker/registry/registry.${PLAYCE_DOMAIN}.crt
    key: /etc/docker/registry/registry.${PLAYCE_DOMAIN}.key
  http2:
    disabled: false
EOF


# repository config
mkdir -p ${PLAYCE_DIR}/playcekube/deployer/nginx/ssl
mkdir -p ${PLAYCE_DATADIR}/repositories/{helm-charts,certs}

# rootca copy repositories
rm -rf ${PLAYCE_DATADIR}/repositories/certs/playcekube_rootca.crt
cp -rp ${PLAYCE_DIR}/playcekube/deployer/certification/CA/playcekube_rootca.crt ${PLAYCE_DATADIR}/repositories/certs/playcekube_rootca.crt

# repository certs copy
rm -rf ${PLAYCE_DIR}/playcekube/deployer/nginx/ssl/repositories.${PLAYCE_DOMAIN}.*
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh repositories.${PLAYCE_DOMAIN} DNS:repositories.${PLAYCE_DOMAIN},DNS:repository.${PLAYCE_DOMAIN},IP:${PLAYCE_DEPLOYER}
cp -rp ${PLAYCE_DIR}/playcekube/deployer/certification/certs/repositories.${PLAYCE_DOMAIN}.* ${PLAYCE_DIR}/playcekube/deployer/nginx/ssl/

cat << EOF > ${PLAYCE_DIR}/playcekube/deployer/nginx/repositories.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  5;

    gzip  on;

    include /etc/nginx/servers.conf;
}
EOF

cat << EOF > ${PLAYCE_DIR}/playcekube/deployer/nginx/servers.conf
server {
    listen       80;
    server_name  repositories.${PLAYCE_DOMAIN};

    access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /repositories;
        autoindex on;
    }

    #error_page  404              /404.html;

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}

server {
    listen       443 ssl;
    server_name  repositories.${PLAYCE_DOMAIN};
    access_log  /var/log/nginx/ssl-host.access.log  main;

    ssl_certificate /etc/nginx/ssl/repositories.${PLAYCE_DOMAIN}.crt;
    ssl_certificate_key /etc/nginx/ssl/repositories.${PLAYCE_DOMAIN}.key;

    #ssl_protocols  TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_protocols  TLSv1.2 TLSv1.3;

    location / {
        root   /repositories;
        autoindex on;
    }

    #error_page  404              /404.html;

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF

# base repo directory create
mkdir -p ${PLAYCE_DATADIR}/repositories/{centos7,rocky8}

# centos7(rhel7) .repo create
# base, update, extras
cat << EOF > ${PLAYCE_DATADIR}/repositories/centos7/base.repo
[base]
name=CentOS-\$releasever - Base
baseurl=https://repositories.${PLAYCE_DOMAIN}/centos7/base
enabled=1
gpgcheck=0

[updates]
name=CentOS-$releasever - Updates
baseurl=https://repositories.${PLAYCE_DOMAIN}/centos7/updates
enabled=1
gpgcheck=0

[extras]
name=CentOS-$releasever - Extras
baseurl=https://repositories.${PLAYCE_DOMAIN}/centos7/extras
enabled=1
gpgcheck=0

[epel]
name=CentOS-$releasever - EPEL
baseurl=https://repositories.${PLAYCE_DOMAIN}/centos7/epel
enabled=1
gpgcheck=0

EOF

# cri-o
cat << EOF > ${PLAYCE_DATADIR}/repositories/centos7/crio.repo
[crio]
name=cri-o
baseurl=https://repositories.${PLAYCE_DOMAIN}/centos7/crio
enabled=1
gpgcheck=0
EOF

# docker-ce
cat << EOF > ${PLAYCE_DATADIR}/repositories/centos7/docker-ce-stable.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://repositories.${PLAYCE_DOMAIN}/centos7/docker-ce-stable
enabled=1
gpgcheck=0
EOF

# rocky8(centos8) .repo create
# baseos, appstream
cat << EOF > ${PLAYCE_DATADIR}/repositories/rocky8/base.repo
[baseos]
name=Rocky Linux $releasever - BaseOS
baseurl=https://repositories.${PLAYCE_DOMAIN}/rocky8/baseos
enabled=1
gpgcheck=0

[appstream]
name=Rocky Linux $releasever - AppStream
baseurl=https://repositories.${PLAYCE_DOMAIN}/rocky8/appstream
enabled=1
gpgcheck=0

[extras]
name=Rocky Linux $releasever - Extras
baseurl=https://repositories.${PLAYCE_DOMAIN}/rocky8/extras
enabled=1
gpgcheck=0
EOF

# cri-o
cat << EOF > ${PLAYCE_DATADIR}/repositories/rocky8/crio.repo
[crio]
name=cri-o
baseurl=https://repositories.${PLAYCE_DOMAIN}/rocky8/crio
enabled=1
gpgcheck=0
EOF

# docker-ce
cat << EOF > ${PLAYCE_DATADIR}/repositories/rocky8/docker-ce-stable.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://repositories.${PLAYCE_DOMAIN}/rocky8/docker-ce-stable
enabled=1
gpgcheck=0
EOF

# kubespray
mkdir -p ${PLAYCE_DATADIR}/kubespray/inventory

