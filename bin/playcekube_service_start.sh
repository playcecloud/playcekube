#!/bin/bash

# sh config
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# ntp(chrony) server restart
systemctl restart chronyd

# network create
if [ "$(docker network ls | grep "playce_network")" == "" ]; then
  docker network create --gateway 172.18.0.1 --subnet 172.18.0.0/24 playce_network
fi

# registry container restart
DAEMON_NAME=playcecloud_registry
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
#docker stop ${DAEMON_NAME} 2> /dev/null
#docker rm ${DAEMON_NAME} 2> /dev/null
if [ "${DAEMON_LIVE}" == "1" ]; then
  # restart
  docker restart ${DAEMON_NAME}
else
  docker run --name ${DAEMON_NAME} \
  -d --restart always \
  --network playce_network \
  --ip 172.18.0.5 \
  -v ${PLAYCE_CONFDIR}/registry:/etc/docker/registry \
  -v ${PLAYCE_DATADIR}/registry:/var/lib/registry \
  -p 5000:5000 \
  docker.io/library/registry:2.7.1
fi

# dns(bind9) container restart
DAEMON_NAME=playcecloud_bind9
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
#docker stop ${DAEMON_NAME} 2> /dev/null
#docker rm ${DAEMON_NAME} 2> /dev/null
if [ "${DAEMON_LIVE}" == "1" ]; then
  # restart
  docker restart ${DAEMON_NAME}
else
  docker run --name ${DAEMON_NAME} \
  -d --restart always \
  --privileged \
  --network playce_network \
  --ip 172.18.0.10 \
  -e TZ=Asia/Seoul \
  -v ${PLAYCE_CONFDIR}/bind9/config:/etc/bind \
  -v ${PLAYCE_CONFDIR}/bind9/cache:/var/cache/bind \
  -v ${PLAYCE_CONFDIR}/bind9/records:/run/name \
  -p 53:53 \
  -p 53:53/udp \
  docker.io/ubuntu/bind9:9.16-21.10_edge
fi

# repository (nginx) container restart
DAEMON_NAME=playcecloud_repository
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
#docker stop ${DAEMON_NAME} 2> /dev/null
#docker rm ${DAEMON_NAME} 2> /dev/null
if [ "${DAEMON_LIVE}" == "1" ]; then
  # restart
  docker restart ${DAEMON_NAME}
else
  docker run --name ${DAEMON_NAME} \
  -d --restart always \
  --network playce_network \
  --ip 172.18.0.7 \
  -v ${PLAYCE_CONFDIR}/nginx/repositories.conf:/etc/nginx/nginx.conf \
  -v ${PLAYCE_CONFDIR}/nginx/servers.conf:/etc/nginx/servers.conf \
  -v ${PLAYCE_CONFDIR}/nginx/ssl:/etc/nginx/ssl \
  -v ${PLAYCE_DATADIR}/repositories:/repositories \
  -p 80:80 \
  -p 443:443 \
  docker.io/library/nginx:1.20.2
fi

# nfs-server container restart
DAEMON_NAME=playcecloud_nfs
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
#docker stop ${DAEMON_NAME} 2> /dev/null
#docker rm ${DAEMON_NAME} 2> /dev/null
if [ "${DAEMON_LIVE}" == "1" ]; then
  # restart
  docker restart ${DAEMON_NAME}
else
  docker run --name ${DAEMON_NAME} \
  -d --restart always \
  --privileged \
  --network playce_network \
  --ip 172.18.0.8 \
  -e SHARED_DIRECTORY=/playcecloud \
  -e PERMITTED="*" \
  -v ${PLAYCE_DATADIR}/nfsshare:/playcecloud \
  -p 2049:2049 \
  docker.io/itsthenetwork/nfs-server-alpine:12
fi

# keycloak container restart
DAEMON_NAME=playcecloud_keycloak
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
#docker stop ${DAEMON_NAME} 2> /dev/null
#docker rm ${DAEMON_NAME} 2> /dev/null
if [ "${DAEMON_LIVE}" == "1" ]; then
  # restart
  docker restart ${DAEMON_NAME}
else
  docker run --name ${DAEMON_NAME} \
  -d --restart always \
  --network playce_network \
  -p 9443:9443 \
  -v ${PLAYCE_CONFDIR}/keycloak/keycloak.${PLAYCE_DOMAIN}.crt:/opt/keycloak/conf/keycloak.${PLAYCE_DOMAIN}.crt \
  -v ${PLAYCE_CONFDIR}/keycloak/keycloak.${PLAYCE_DOMAIN}.key:/opt/keycloak/conf/keycloak.${PLAYCE_DOMAIN}.key \
  -e KC_HTTP_ENABLED=true \
  -e KC_HOSTNAME=keycloak.${PLAYCE_DOMAIN} \
  -e KEYCLOAK_ADMIN=playce-admin \
  -e KEYCLOAK_ADMIN_PASSWORD=vmffpdltm \
  -e KC_HTTPS_PORT=9443 \
  -e KC_HTTPS_CERTIFICATE_FILE=/opt/keycloak/conf/keycloak.${PLAYCE_DOMAIN}.crt \
  -e KC_HTTPS_CERTIFICATE_KEY_FILE=/opt/keycloak/conf/keycloak.${PLAYCE_DOMAIN}.key \
  -e KC_HTTPS_PROTOCOLS=TLSv1.3,TLSv1.2 \
  quay.io/keycloak/keycloak:18.0.2 start

  # init
  ${PLAYCE_DIR}/playcekube/keycloak/keycloak-init.sh
fi

# rancher container restart
DAEMON_NAME=playcekube_rancher
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
#docker stop ${DAEMON_NAME} 2> /dev/null
#docker rm ${DAEMON_NAME} 2> /dev/null
if [ "${DAEMON_LIVE}" == "1" ]; then
  # restart
  docker restart ${DAEMON_NAME}
else
  docker run --name ${DAEMON_NAME} \
  -d --restart=unless-stopped \
  --network playce_network \
  --privileged \
  --ip 172.18.0.9 \
  --dns 172.18.0.10 \
  --cgroupns host \
  -p 8080:80 -p 8443:443 \
  -v ${PLAYCE_CONFDIR}/rancher/rancher.${PLAYCE_DOMAIN}.crt:/etc/rancher/ssl/cert.pem \
  -v ${PLAYCE_CONFDIR}/rancher/rancher.${PLAYCE_DOMAIN}.key:/etc/rancher/ssl/key.pem \
  -v ${PLAYCE_DATADIR}/certificates/ca/playcecloud_rootca.crt:/etc/rancher/ssl/cacerts.pem \
  -v ${PLAYCE_DATADIR}/rancher:/var/lib/rancher \
  -e CATTLE_BOOTSTRAP_PASSWORD=vmffpdltm1@# \
  -e CATTLE_SYSTEM_DEFAULT_REGISTRY=registry.local.cloud:5000 \
  -e HELM_NAMESPACE=playcekube \
  docker.io/rancher/rancher:v2.6.6

  # init
  ${PLAYCE_DIR}/playcekube/rancher/rancher-init.sh
fi

