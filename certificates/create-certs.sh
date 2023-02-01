#!/bin/bash

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
mkdir -p ${CADIR}
mkdir -p ${CERTDIR}

touch ${CADIR}/certs.index

# option
REQ_TYPE=v3_req
CA_TYPE=v3_req
KEY_TYPE=rsa
KEY_BIT=2048
KEY_ENC=0
KEY_PASSWD=""
DEF_SUBJ="/C=KR/OU=Playce Cloud"
CACERT=""
CAKEY=""
CAPASSWD=""
CNAME="rootca"
SAN=""

# args parsing
while [[ $# -gt 0 ]] && [[ "$1" == "-"* ]];
do
  OPT="$1";
  shift;

  case "${OPT}" in
    "--") ;;
    "-")
      break 2;
      ;;
    # intermedia CA
    "--intermedia" )
      CA_TYPE="v3_intermediate_ca";
      ;;
    # private key type
    "--keytype="* )
      KEY_TYPE="${OPT#*=}";
      ;;
    "-t" | "--keytype")
      KEY_TYPE="$1";
      shift;
      ;;
    # encoding
    "--enc=*" )
      KEY_ENC=1;
      KEY_PASSWD="${OPT#*=}";
      ;;
    "-e" | "--enc" )
      KEY_ENC=1;
      KEY_PASSWD="$1";
      shift;
      ;;
    # ca password
    "--capasswd="* )
      CAPASSWD="${OPT#*=}";
      ;;
    "-p" | "--capasswd" )
      CAPASSWD="$1";
      shift;
      ;;
    # cacert
    "-c" | "--cacert" )
      CACERT="$1";
      shift;
      ;;
    "--cacert="* )
      CACERT="${OPT#*=}";
      ;;
    # cakey
    "--cakey="* )
      CAKEY="${OPT#*=}";
      ;;
    "-k" | "--cakey" )
      CAKEY="$1";
      shift;
      ;;
    *)
      echo >&2 "[ERROR] Invalid option: $@";
      exit;
      ;;
  esac
done

if [ "$1" != "" ]; then
  CNAME=$1
  CNAME=${CNAME/\*/wild}
fi

if [ "$2" != "" ]; then
  SAN=$2
fi

STR_KEYTYPE="rsa:${KEY_BIT}"
STR_ENC="-nodes"
STR_CACERT=""
STR_CAKEY=""
STR_CAPASSWD=""
STR_SUBJ=""
STR_SAN=""
CNPATH="${CERTDIR}"

if [ "${KEY_ENC}" == "1" ]; then
  export KEY_PASSWD
  STR_ENC="-passout env:KEY_PASSWD"
fi

if [ "${KEY_TYPE}" == "ec" ]; then
  openssl ecparam -name prime256v1 -out ${BASEDIR}/ecparam.pem
  STR_KEYTYPE=ec:${BASEDIR}/ecparam.pem
fi

if [ "${CACERT}" != "" ]; then
  STR_CACERT="-cert ${CACERT}"
fi

if [ "${CAKEY}" != "" ]; then
  STR_CAKEY="-keyfile ${CAKEY}"
fi

if [ "${CAPASSWD}" != "" ]; then
  STR_CAPASSWD="-key ${CAPASSWD}"
fi

if [ "${SAN}" != "" ]; then
  sed -zE "s/.*(\[ v3_ca \].*)\[ [^\s]* \].*/\1/g" ${BASEDIR}/openssl.conf > ${BASEDIR}/extfile.conf
  echo "subjectAltName=${SAN}" >> ${BASEDIR}/extfile.conf
  STR_SAN="-extfile ${BASEDIR}/extfile.conf"
fi

if [[ "${CNAME}" =~ ^rootca.* ]]; then
  rm -rf ${CADIR}/certs.index ${CADIR}/certs.srl
  touch ${CADIR}/certs.index
  REQ_TYPE="v3_ca"
  CA_TYPE="v3_ca"
  STR_CACERT="-selfsign"
  STR_CAKEY="-keyfile ${CADIR}/playcecloud_${CNAME}.key"
  CNPATH="${CADIR}"
  CNAME="playcecloud_${CNAME}"
  STR_SUBJ="/C=KR/O=Open Source Consulting Inc/OU=Playce Cloud Root CA"
else
  STR_SUBJ="${DEF_SUBJ}/CN=${CNAME}"
fi

if [[ -f "${CNPATH}/${CNAME}.crt" ]]; then
  echo "[WARN] ${CNPATH}/${CNAME}.crt Already exists"
else
  # create key,csr
  openssl req -reqexts ${REQ_TYPE} \
   -config ${BASEDIR}/openssl.conf \
   -newkey ${STR_KEYTYPE} ${STR_ENC} -keyout ${CNPATH}/${CNAME}.key \
   -out ${CNPATH}/${CNAME}.csr \
   -subj "${STR_SUBJ}" \
   -batch

  # ca sign
  openssl ca -extensions ${CA_TYPE} \
   -config ${BASEDIR}/openssl.conf \
   ${STR_CACERT} \
   ${STR_CAKEY} \
   ${STR_CAPASSWD} \
   ${STR_SAN} \
   -in ${CNPATH}/${CNAME}.csr \
   -out ${CNPATH}/${CNAME}.crt \
   -create_serial \
   -notext \
   -days 36500 \
   -batch
fi

rm -rf ${BASEDIR}/extfile.conf ${BASEDIR}/ecparam.pem

