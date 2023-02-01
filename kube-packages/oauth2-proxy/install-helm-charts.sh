#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=oauth2-proxy
CHART_VERSION=6.2.0

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
sed -i "s/quay\.io/registry.local.cloud:5000/g" ${BASEDIR}/installed-values.yaml
grep -n "^redis:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\  global:\n    imageRegistry: registry.local.cloud:5000" ${BASEDIR}/installed-values.yaml

# get keycloak kubernetes secret
REALM_KUBERNETES_SECRET=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get secrets keycloak-client-secret -o jsonpath={.data.kubernetes} | base64 --decode)

if [[ "${REALM_KUBERNETES_SECRET}" == "" ]]; then
  rm -f ${BASEDIR}/installed-values.yaml
  echo "Please install keycloak first"
  exit 1;
fi

# oauth2-proxy keycloak-config
COOKIE_SECRET=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\n' | tr -- '+/' '-_'; echo)
sed -i "/^config:/a\  existingConfig: oauth2-keycloak-config" ${BASEDIR}/installed-values.yaml
sed -i "s/  clientID: .*/  clientID: \"kubernetes\"/g" ${BASEDIR}/installed-values.yaml
sed -i "s/  clientSecret: .*/  clientSecret: \"${REALM_KUBERNETES_SECRET}\"/g" ${BASEDIR}/installed-values.yaml
sed -i "s/  cookieSecret: .*/  cookieSecret: \"${COOKIE_SECRET}\"/g" ${BASEDIR}/installed-values.yaml

# session store change redis
grep -A 5 -n "^sessionStorage:" ${BASEDIR}/installed-values.yaml | grep "type:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/type: .*/type: redis/" ${BASEDIR}/installed-values.yaml
grep -A 7 -n "^redis:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml

# extra args
sed -i "s/^extraArgs:.*/extraArgs:\n  insecure-oidc-allow-unverified-email:\n  pass-authorization-header:\n  set-authorization-header:\n  set-xauthrequest:\n  cookie-refresh: 300s\n  cookie-expire: 10h/" ${BASEDIR}/installed-values.yaml

# root-ca volume mount
sed -i "s|^extraVolumes:.*|extraVolumes:\n  - name: root-ca\n    secret:\n      secretName: os-root-ca|g" ${BASEDIR}/installed-values.yaml
sed -i "s|^extraVolumeMounts:.*|extraVolumeMounts:\n  - name: root-ca\n    mountPath: /etc/ssl/certs/ca-certificates.crt\n    subPath: ca-certificates.crt|g" ${BASEDIR}/installed-values.yaml

# ingress
grep -A 30 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
grep -A 30 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "# hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}i\  hosts:\n    - oauth2-proxy.${USING_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml
grep -A 30 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "# tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}i\  tls:\n    - secretName: wild-tls\n      hosts:\n        - oauth2-proxy.${USING_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml
grep -n "^ingress:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\  annotations:\n    nginx.ingress.kubernetes.io/proxy-buffer-size: 64k" ${BASEDIR}/installed-values.yaml

# create oauth2-proxy config configmap
cat << EOF > oauth2-keycloak-config
http_address="0.0.0.0:4180"
email_domains=["*"]
upstreams=["file:///dev/null"]
cookie_secure=false
cookie_domains=[".${USING_CLUSTER}.${PLAYCE_DOMAIN}"]
whitelist_domains=[".${USING_CLUSTER}.${PLAYCE_DOMAIN}"]

# keycloak provider
provider="keycloak-oidc"
provider_display_name="Keycloak"
oidc_issuer_url="https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/realms/${USING_CLUSTER}"
redirect_url="https://oauth2-proxy.${USING_CLUSTER}.${PLAYCE_DOMAIN}/oauth2/callback"
EOF
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} delete configmap oauth2-keycloak-config
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} create configmap oauth2-keycloak-config --from-file=oauth2_proxy.cfg=oauth2-keycloak-config
rm -rf oauth2-keycloak-config

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

# ready check
POD_NAME=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get pod -o name -l app.kubernetes.io/name=${CHART_NAME} | head -n 1)
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} wait --for=condition=Ready ${POD_NAME} --timeout=300s


