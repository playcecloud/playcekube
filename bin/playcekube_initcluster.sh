#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# set env file
while getopts ":f:e:" OPT; do
  case ${OPT} in
    f) KUBESPRAY_ENV=${OPTARG}
    ;;
  esac
done

shift $[ $OPTIND - 1 ]
CLUSTER_NAME=$1

if [ "${CLUSTER_NAME}" == "" ] && [ -f "${KUBESPRAY_ENV}" ]; then
  CLUSTER_NAME=$(grep "^CLUSTER_NAME=" ${KUBESPRAY_ENV} | sed "s/CLUSTER_NAME=\(.*\)/\1/")
fi

if [ "${CLUSTER_NAME}" == "" ] || [ ! -d "${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}" ]; then
  echo "[ERROR] cluster inventory not found"
  exit 1;
fi

CLUSTER_MASTER_HOSTNAME=`grep -A 1 "\[kube_control_plane\]" ${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/inventory.ini | tail -n 1`
CLUSTER_MASTER=`grep "${CLUSTER_MASTER_HOSTNAME}" ${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/inventory.ini | grep "ansible_host=" | sed "s/.*ansible_host=\([0-9.]*\) .*/\1/g"`
CLUSTER_INGRESS=`grep "node-role.kubernetes.io/ingress" ${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/inventory.ini | head -n 1 | grep "ansible_host=" | sed "s/.*ansible_host=\([0-9.]*\) .*/\1/g"`

if [ "${CLUSTER_INGRESS}" == "" ]; then
  CLUSTER_INGRESS=${CLUSTER_MASTER}
fi
CLUSTER_CA=${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/${CLUSTER_NAME}-ca.crt
CLUSTER_CRT=${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/${CLUSTER_NAME}-admin.crt
CLUSTER_KEY=${PLAYCE_DATADIR}/kubespray/inventory/${CLUSTER_NAME}/${CLUSTER_NAME}-admin.key

# 가져온 인증 정보로 cluster, context,user 생성 및 등록
kubectl config set-cluster ${CLUSTER_NAME} --server=https://${CLUSTER_MASTER}:6443 --certificate-authority=${CLUSTER_CA}
kubectl config set-credentials ${CLUSTER_NAME}-admin --client-certificate=${CLUSTER_CRT} --client-key=${CLUSTER_KEY}
kubectl config set-context admin@${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --namespace=default --user=${CLUSTER_NAME}-admin

# init ns
kubectl --context=admin@${CLUSTER_NAME} create ns playcekube -o yaml --dry-run=client | kubectl --context=admin@${CLUSTER_NAME} apply -f -
kubectl --context=admin@${CLUSTER_NAME} create ns playcekube-dev -o yaml --dry-run=client | kubectl --context=admin@${CLUSTER_NAME} apply -f -

# init certs
${PLAYCE_DIR}/playcekube/certificates/create-certs.sh *.${CLUSTER_NAME}.${PLAYCE_DOMAIN} DNS:*.${CLUSTER_NAME}.${PLAYCE_DOMAIN}
${PLAYCE_DIR}/playcekube/certificates/create-certs.sh -t ec --intermedia --cacert ${PLAYCE_DATADIR}/certificates/ca/playcecloud_rootca_ec.crt --cakey ${PLAYCE_DATADIR}/certificates/ca/playcecloud_rootca_ec.key linkerd2-issuer

CA_ROOT_FILE=/etc/ssl/certs/ca-bundle.crt
if [ ! -f "${CA_ROOT_FILE}" ]; then
  CA_ROOT_FILE=/etc/ssl/certs/ca-certificates.crt
fi

CA_ROOT_KEYSTORE=/etc/pki/java/cacerts
if [ ! -f "${CA_ROOT_KEYSTORE}" ]; then
  CA_ROOT_KEYSTORE=/etc/ssl/certs/java/cacerts
fi

## playcekube
kubectl --context=admin@${CLUSTER_NAME} -n playcekube delete secret os-root-ca os-java-keystore wild-tls
kubectl --context=admin@${CLUSTER_NAME} -n playcekube create secret generic os-root-ca --from-file=ca-bundle.crt=${CA_ROOT_FILE} --from-file=ca-certificates.crt=${CA_ROOT_FILE}
kubectl --context=admin@${CLUSTER_NAME} -n playcekube create secret generic os-java-keystore --from-file=cacerts=${CA_ROOT_KEYSTORE}
kubectl --context=admin@${CLUSTER_NAME} -n playcekube create secret tls wild-tls --cert=${PLAYCE_DATADIR}/certificates/certs/wild.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DATADIR}/certificates/certs/wild.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.key
## playcekube-dev
kubectl --context=admin@${CLUSTER_NAME} -n playcekube-dev delete secret os-root-ca os-java-keystore wild-tls
kubectl --context=admin@${CLUSTER_NAME} -n playcekube-dev create secret generic os-root-ca --from-file=ca-bundle.crt=${CA_ROOT_FILE} --from-file=ca-certificates.crt=${CA_ROOT_FILE}
kubectl --context=admin@${CLUSTER_NAME} -n playcekube-dev create secret generic os-java-keystore --from-file=cacerts=${CA_ROOT_KEYSTORE}
kubectl --context=admin@${CLUSTER_NAME} -n playcekube-dev create secret tls wild-tls --cert=${PLAYCE_DATADIR}/certificates/certs/wild.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DATADIR}/certificates/certs/wild.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.key
### harbor
kubectl --context=admin@${CLUSTER_NAME} -n playcekube-dev delete secret harbor.${CLUSTER_NAME}.${PLAYCE_DOMAIN}-tls
kubectl --context=admin@${CLUSTER_NAME} -n playcekube-dev create secret tls harbor.${CLUSTER_NAME}.${PLAYCE_DOMAIN}-tls --cert=${PLAYCE_DATADIR}/certificates/certs/wild.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DATADIR}/certificates/certs/wild.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.key
### prometheus
ETCDPOD_NAME=$(kubectl --context=admin@${CLUSTER_NAME} -n kube-system get pods -o=jsonpath='{.items[0].metadata.name}' -l component=etcd)
kubectl --context=admin@${CLUSTER_NAME} -n playcekube delete secret etcd-client-cert
kubectl --context=admin@${CLUSTER_NAME} -n playcekube delete configmap certs-configmap
kubectl --context=admin@${CLUSTER_NAME} -n playcekube create secret generic etcd-client-cert \
  --from-literal=etcd-ca="$(kubectl --context=admin@${CLUSTER_NAME} -n kube-system exec ${ETCDPOD_NAME} -- cat /etc/kubernetes/ssl/etcd/ca.crt)" \
  --from-literal=etcd-client="$(kubectl --context=admin@${CLUSTER_NAME} -n kube-system exec ${ETCDPOD_NAME} -- cat /etc/kubernetes/ssl/etcd/healthcheck-client.crt)" \
  --from-literal=etcd-client-key="$(kubectl --context=admin@${CLUSTER_NAME} -n kube-system exec ${ETCDPOD_NAME} -- cat /etc/kubernetes/ssl/etcd/healthcheck-client.key)"
kubectl --context=admin@${CLUSTER_NAME} -n playcekube create configmap certs-configmap --from-file=root-ca.crt=${PLAYCE_DATADIR}/certificates/ca/playcecloud_rootca.crt --from-file=grafana.crt=${PLAYCE_DATADIR}/certificates/certs/wild.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.crt --from-file=grafana.key=${PLAYCE_DATADIR}/certificates/certs/wild.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.key

# create keycloak init config
rm -rf /tmp/keycloak-init.json
kubectl --context=admin@${CLUSTER_NAME} -n playcekube delete configmap keycloak-init-config
cp ${PLAYCE_DIR}/playcekube/kube-packages/keycloak/template-init.json /tmp/keycloak-init.json
# admin info
ADMIN_USER=playce-admin
ADMIN_PASSWORD=vmffpdltm
sed -i "s/<<USING_CLUSTER>>/${CLUSTER_NAME}/g" /tmp/keycloak-init.json
sed -i "s/<<PLAYCE_DOMAIN>>/${PLAYCE_DOMAIN}/g" /tmp/keycloak-init.json
sed -i "s/<<ADMIN_USER>>/${ADMIN_USER}/g" /tmp/keycloak-init.json
sed -i "s/<<ADMIN_PASSWORD>>/${ADMIN_PASSWORD}/g" /tmp/keycloak-init.json
kubectl --context=admin@${CLUSTER_NAME} -n playcekube create configmap keycloak-init-config --from-file=keycloak-init.json=/tmp/keycloak-init.json
rm -rf /tmp/keycloak-init.json

# add rancher
echo "[INFO] ### Add cluster to rancher"
# get cluster id
CLUSTER_ID=$(curl -k --oauth2-bearer ${RANCHER_SECRET} https://rancher.${PLAYCE_DOMAIN}:8443/v3/clusters?name=${CLUSTER_NAME} -H "content-type: application/json" 2> /dev/null | jq -r .data[0].id)
if [[ "${CLUSTER_ID}" == "null" ]] || [[ "${CLUSTER_ID}" == "" ]]; then
  CLUSTER_ID=$(curl -k --oauth2-bearer ${RANCHER_SECRET} https://rancher.${PLAYCE_DOMAIN}:8443/v3/clusters -H "content-type: application/json" -d "{\"type\":\"cluster\",\"name\":\"${CLUSTER_NAME}\",\"import\":true}" 2> /dev/null | jq -r .id)
  CLUSTER_TOKEN_ID=""

  # get cluster token id
  for i in {1..5}
  do
    echo "[INFO] Try get token id..."
    sleep 5;
    CLUSTER_TOKEN_ID=$(curl -k --oauth2-bearer ${RANCHER_SECRET} https://rancher.${PLAYCE_DOMAIN}:8443/v3/clusters/${CLUSTER_ID}/clusterregistrationtokens -H 'content-type: application/json' -d "{\"type\":\"clusterRegistrationToken\",\"clusterId\":\"${CLUSTER_ID}\",\"uuid\":\"${OLDUUID}\"}" 2> /dev/null | jq -r .id)
    if [[ "${CLUSTER_TOKEN_ID}" != "null" ]] && [[ "${CLUSTER_TOKEN_ID}" != "" ]]; then
      break;
    fi
  done

  if [[ "${CLUSTER_TOKEN_ID}" != "null" ]] && [[ "${CLUSTER_TOKEN_ID}" != "" ]]; then
    echo "[INFO] get agent command & run command"
    AGENTCOMMAND=$(curl -k --oauth2-bearer ${RANCHER_SECRET} https://rancher.${PLAYCE_DOMAIN}:8443/v3/clusters/${CLUSTER_ID}/clusterregistrationtoken/${CLUSTER_TOKEN_ID} 2> /dev/null | jq -r .command)
    eval "${AGENTCOMMAND} --context=admin@${CLUSTER_NAME}"

cat << EOF | kubectl --context=admin@${CLUSTER_NAME} apply -f -
---
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: rancher-charts
spec:
  gitBranch: ""
  gitRepo: ""
  url: https://repository.local.cloud/helm-charts
EOF

  else
    echo "[ERROR] get agent command fail. Please check Rancher"
  fi

fi

# dns records add
DNSCONF_SDNUM=`grep -n "### start ${CLUSTER_NAME}.${PLAYCE_DOMAIN} ###" ${PLAYCE_CONFDIR}/bind9/config/named.kubernetes.zones | sed "s/\([0-9]*\).*/\1/"`
DNSCONF_EDNUM=`grep -n "### end ${CLUSTER_NAME}.${PLAYCE_DOMAIN} ###" ${PLAYCE_CONFDIR}/bind9/config/named.kubernetes.zones | sed "s/\([0-9]*\).*/\1/"`
if [[ "${DNSCONF_SDNUM}" -gt "0" ]] && [[ "${DNSCONF_EDNUM}" -gt "0" ]]; then
  sed -i "${DNSCONF_SDNUM},${DNSCONF_EDNUM}d" ${PLAYCE_CONFDIR}/bind9/config/named.kubernetes.zones
fi

cat << EOF >> ${PLAYCE_CONFDIR}/bind9/config/named.kubernetes.zones

### start ${CLUSTER_NAME}.${PLAYCE_DOMAIN} ###
zone "${CLUSTER_NAME}.${PLAYCE_DOMAIN}" IN {
    type master;
    file "named.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.zone";
};
### end ${CLUSTER_NAME}.${PLAYCE_DOMAIN} ###
EOF

cat << EOF > ${PLAYCE_CONFDIR}/bind9/cache/named.${CLUSTER_NAME}.${PLAYCE_DOMAIN}.zone
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
docker restart playcecloud_bind9

# create nfs directory
mkdir -p ${PLAYCE_DATADIR}/nfsshare/${CLUSTER_NAME}

# default engine install
## metrics-server install
echo -en "\n[INFO] ### metrics-server install ###\n"
${PLAYCE_DIR}/playcekube/kube-packages/metrics-server/install-helm-charts.sh admin@${CLUSTER_NAME}

# default addons install
## ingress install
echo -en "\n[INFO] ### ingress install ###\n"
${PLAYCE_DIR}/playcekube/kube-packages/ingress-nginx/install-helm-charts.sh admin@${CLUSTER_NAME}

## csi-nfs-driver install
echo -en "\n[INFO] ### csi-nfs-driver install ###\n"
${PLAYCE_DIR}/playcekube/kube-packages/csi-driver-nfs/install-helm-charts.sh admin@${CLUSTER_NAME}

## keycloak install
#echo -en "\n[INFO] ### keycloak install ###\n"
#${PLAYCE_DIR}/playcekube/kube-packages/keycloak/install-helm-charts.sh admin@${CLUSTER_NAME}

## prometheus install
#echo -en "\n#[INFO] ## prometheus install ###\n"
#${PLAYCE_DIR}/playcekube/kube-packages/prometheus/install-helm-charts.sh admin@${CLUSTER_NAME}

## velero install
#echo -en "\n[INFO] ### minio for velero install ###\n"
#${PLAYCE_DIR}/playcekube/kube-packages/minio/install-helm-charts.sh admin@${CLUSTER_NAME}
#echo -en "\n[INFO] ### velero install ###\n"
#${PLAYCE_DIR}/playcekube/kube-packages/velero/install-helm-charts.sh admin@${CLUSTER_NAME}


