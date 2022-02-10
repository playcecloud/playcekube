#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

#KUBESPRAY_ENV=

if [[ "${KUBESPRAY_ENV}" == "" ]]; then
  echo "KUBESPRAY_ENV environments required"
  exit 1;
fi

CLUSTER_NAME=$(grep "^CLUSTER_NAME=" ${KUBESPRAY_ENV} | sed "s/CLUSTER_NAME=\(.*\)/\1/")
CLUSTER_MASTER_HOSTNAME=`grep -A 1 "\[kube_control_plane\]" ${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/inventory.ini | tail -n 1`
CLUSTER_MASTER=`grep "${CLUSTER_MASTER_HOSTNAME}" ${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/inventory.ini | grep "ansible_host=" | sed "s/.*ansible_host=\([0-9.]*\) .*/\1/g"`
CLUSTER_INGRESS=`grep "node-role.kubernetes.io/ingress" ${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/inventory.ini | head -n 1 | grep "ansible_host=" | sed "s/.*ansible_host=\([0-9.]*\) .*/\1/g"`
if [[ "${CLUSTER_INGRESS}" == "" ]]; then
  CLUSTER_INGRESS=${CLUSTER_MASTER}
fi
CLUSTER_CA=${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/${CLUSTER_NAME}-ca.crt
CLUSTER_CRT=${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/${CLUSTER_NAME}-admin.crt
CLUSTER_KEY=${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/${CLUSTER_NAME}-admin.key

# 가져온 인증 정보로 cluster, context,user 생성 및 등록
kubectl config set-cluster ${CLUSTER_NAME} --server=https://${CLUSTER_MASTER}:6443 --certificate-authority=${CLUSTER_CA}
kubectl config set-credentials ${CLUSTER_NAME}-admin --client-certificate=${CLUSTER_CRT} --client-key=${CLUSTER_KEY}
kubectl config set-context admin@${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --namespace=default --user=${CLUSTER_NAME}-admin
kubectl config use-context admin@${CLUSTER_NAME}

# dns records add
DNSCONF_SDNUM=`grep -n "### start ${CLUSTER_NAME}.${PLAYCE_DOMAIN} ###" ${PLAYCE_DIR}/playcekube/deployer/bind9/config/named.kubernetes.zones | sed "s/\([0-9]*\).*/\1/"`
DNSCONF_EDNUM=`grep -n "### end ${CLUSTER_NAME}.${PLAYCE_DOMAIN} ###" ${PLAYCE_DIR}/playcekube/deployer/bind9/config/named.kubernetes.zones | sed "s/\([0-9]*\).*/\1/"`
if [[ "${DNSCONF_SDNUM}" -gt "0" ]] && [[ "${DNSCONF_EDNUM}" -gt "0" ]]; then
  sed -i "${DNSCONF_SDNUM},${DNSCONF_EDNUM}d" ${PLAYCE_DIR}/playcekube/deployer/bind9/config/named.kubernetes.zones
fi

cat << EOF >> ${PLAYCE_DIR}/playcekube/deployer/bind9/config/named.kubernetes.zones

### start ${CLUSTER_NAME}.${PLAYCE_DOMAIN} ###
zone "${CLUSTER_NAME}.${PLAYCE_DOMAIN}" IN {
    type master;
    file "named.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.zone";
};
### end ${CLUSTER_NAME}.${PLAYCE_DOMAIN} ###
EOF

cat << EOF > ${PLAYCE_DIR}/playcekube/deployer/bind9/cache/named.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.zone
\$ORIGIN ${CLUSTER_NAME}.${PLAYCE_DOMAIN}.
\$TTL 86400      ; 1 day
@                               IN SOA   ns.${CLUSTER_NAME}.${PLAYCE_DOMAIN}. root.${CLUSTER_NAME}.${PLAYCE_DOMAIN}. (
                                $(date +%Y%m%d)01  ; serial
                                10800       ; refresh (3 hours)
                                900         ; retry (15 minutes)
                                604800      ; expire (1 week)
                                86400       ; minimum (1 day)
                                )
                                NS ns.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.

; base ttl, dns
\$TTL 604800
@                               IN A ${CLUSTER_MASTER}

; 1 day cache dns
\$TTL 86400
ns                              IN A ${CLUSTER_MASTER}

; master
\$TTL 86400
master                           IN A ${CLUSTER_MASTER}

; ingress
*                               IN A ${CLUSTER_INGRESS}
EOF

# bind9 restart
docker restart playcekube_bind9


