#!/bin/bash

BASEDIR=$(dirname $(readlink -f $0))


echo ${BASEDIR}

CADIR=${BASEDIR}/CA
CERTSDIR=${BASEDIR}/certs

CNNAME=$1
SAN=$2

if [ "${CNNAME}" == "" ]; then
  echo "please input cn"
  exit 1;
fi

echo "### create certs ${CERTSDIR}/${CNNAME}.key,csr,crt"

if [ "${SAN}" == "" ]; then
  # create key,csr
  openssl req -reqexts v3_req \
    -config ${BASEDIR}/openssl_certs.cnf \
    -newkey rsa:2048 -nodes -keyout ${CERTSDIR}/${CNNAME}.key \
    -out ${CERTSDIR}/${CNNAME}.csr \
    -subj "/C=KR/CN=${CNNAME}"

  # ca sign
  openssl x509 -req -extensions v3_req \
    -extfile <(cat ${BASEDIR}/openssl_certs.cnf \
    <(printf "\n[ v3_req ]\nauthorityKeyIdentifier = keyid,issuer")) \
    -CA ${CADIR}/playcekube_rootca.crt -CAcreateserial -CAkey ${CADIR}/playcekube_rootca.key \
    -in ${CERTSDIR}/${CNNAME}.csr -out ${CERTSDIR}/${CNNAME}.crt -days 3650
else
  # create key,csr
  openssl req -reqexts v3_req \
    -config <(cat ${BASEDIR}/openssl_certs.cnf \
    <(printf "\n[ v3_req ]\nsubjectAltName=${SAN}")) \
    -newkey rsa:2048 -nodes -keyout ${CERTSDIR}/${CNNAME}.key \
    -out ${CERTSDIR}/${CNNAME}.csr \
    -subj "/C=KR/CN=${CNNAME}"

  # ca sign
  openssl x509 -req -extensions v3_req \
    -extfile <(cat ${BASEDIR}/openssl_certs.cnf \
    <(printf "\n[ v3_req ]\nauthorityKeyIdentifier = keyid,issuer") \
    <(printf "\nsubjectAltName=${SAN}")) \
    -CA ${CADIR}/playcekube_rootca.crt -CAcreateserial -CAkey ${CADIR}/playcekube_rootca.key \
    -in ${CERTSDIR}/${CNNAME}.csr -out ${CERTSDIR}/${CNNAME}.crt -days 3650
fi

