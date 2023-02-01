#!/bin/sh

# sh config
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# cert path
CERTBASE=${PLAYCE_DATADIR}/certificates
CADIR=${CERTBASE}/ca
CERTDIR=${CERTBASE}/certs

# os info
. /etc/os-release

if [ "${ID}" == "ubuntu" ]; then
  rm -rf /usr/local/share/ca-certificates/playcecloud_rootca.crt
  cp ${CADIR}/playcecloud_rootca.crt /usr/local/share/ca-certificates/
  update-ca-certificates
else
  rm -rf /etc/pki/ca-trust/source/anchors/playcecloud_rootca.crt
  cp -rp ${CADIR}/playcecloud_rootca.crt /etc/pki/ca-trust/source/anchors/
  update-ca-trust extract
fi

