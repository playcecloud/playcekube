#!/bin/bash

BASEDIR=$(dirname $(readlink -f $0))

CADIR=${BASEDIR}/CA
CERTSDIR=${BASEDIR}/intermediateCA

CANAME=$1

if [ "${CANAME}" == "" ]; then
  echo "please input ca name"
  exit 1;
fi

echo "### create certs ${CERTSDIR}/${CANAME}.key,csr,crt"

# create key,csr
openssl req -reqexts v3_req \
  -config ${BASEDIR}/openssl_certs.cnf \
  -newkey ec:<(openssl ecparam -name prime256v1) -nodes -keyout ${CERTSDIR}/${CANAME}.key \
  -out ${CERTSDIR}/${CANAME}.csr \
  -subj "/C=KR/CN=${CANAME}"

# ca sign
openssl ca -config ${BASEDIR}/openssl_certs.cnf \
  -batch \
  -extensions v3_intermediate_ca \
  -days 3650 \
  -cert ${CADIR}/playcekube_rootca.crt -keyfile ${CADIR}/playcekube_rootca.key \
  -in ${CERTSDIR}/${CANAME}.csr -out ${CERTSDIR}/${CANAME}.crt


