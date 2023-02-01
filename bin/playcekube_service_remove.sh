#!/bin/bash

# sh config
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# registry container restart
DAEMON_NAME=playcecloud_registry
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
docker stop ${DAEMON_NAME} 2> /dev/null
docker rm ${DAEMON_NAME} 2> /dev/null
rm -rf ${PLAYCE_CONFDIR}/registry
rm -rf ${PLAYCE_DATADIR}/certificates/certs/registry.*

# dns(bind9) container restart
DAEMON_NAME=playcecloud_bind9
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
docker stop ${DAEMON_NAME} 2> /dev/null
docker rm ${DAEMON_NAME} 2> /dev/null
rm -rf ${PLAYCE_CONFDIR}/bind9

# repository (nginx) container restart
DAEMON_NAME=playcecloud_repository
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
docker stop ${DAEMON_NAME} 2> /dev/null
docker rm ${DAEMON_NAME} 2> /dev/null
rm -rf ${PLAYCE_CONFDIR}/nginx
rm -rf ${PLAYCE_DATADIR}/certificates/certs/repository.*

# nfs-server container restart
DAEMON_NAME=playcecloud_nfs
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
docker stop ${DAEMON_NAME} 2> /dev/null
docker rm ${DAEMON_NAME} 2> /dev/null

# keycloak container restart
DAEMON_NAME=playcecloud_keycloak
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
docker stop ${DAEMON_NAME} 2> /dev/null
docker rm ${DAEMON_NAME} 2> /dev/null
rm -rf ${PLAYCE_CONFDIR}/keycloak
rm -rf ${PLAYCE_DATADIR}/certificates/certs/keycloak.*

# rancher container restart
DAEMON_NAME=playcekube_rancher
DAEMON_LIVE=$(docker ps | grep "${DAEMON_NAME}" | wc -l)
docker stop ${DAEMON_NAME} 2> /dev/null
docker rm ${DAEMON_NAME} 2> /dev/null
rm -rf ${PLAYCE_CONFDIR}/rancher
rm -rf ${PLAYCE_DATADIR}/rancher
rm -rf ${PLAYCE_DATADIR}/certificates/certs/rancher.*

# network delete
if [ "$(docker network ls | grep "playce_network")" != "" ]; then
  docker network rm playce_network
fi


