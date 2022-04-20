#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall oauth2-proxy -n oauth2-proxy 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns oauth2-proxy 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s/quay\.io/registry.${PLAYCE_DOMAIN}:5000/g" ${BASEDIR}/installed-values.yaml

# oauth2-proxy keycloak-config
COOKIE_SECRET=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\n' | tr -- '+/' '-_'; echo)
sed -i "/^config:/a\  existingConfig: config" ${BASEDIR}/installed-values.yaml
sed -i "s/  clientID: .*/  clientID: \"kubernetes\"/g" ${BASEDIR}/installed-values.yaml
sed -i "s/  clientSecret: .*/  clientSecret: \"wl1L1BE2fjVqhWAdkPdvuE3wuNsrfDJi\"/g" ${BASEDIR}/installed-values.yaml
#sed -i "s/  cookieName: .*/  cookieName: \"oauth2-keycloak\"/g" ${BASEDIR}/installed-values.yaml
sed -i "s/  cookieSecret: .*/  cookieSecret: \"${COOKIE_SECRET}\"/g" ${BASEDIR}/installed-values.yaml

# email insecure
sed -i "s/^extraArgs:.*/extraArgs:\n  insecure-oidc-allow-unverified-email:/" ${BASEDIR}/installed-values.yaml

# root-ca volume mount
sed -i "s|^extraVolumes:.*|extraVolumes:\n  - name: root-ca\n    secret:\n      secretName: os-root-ca|g" ${BASEDIR}/installed-values.yaml
sed -i "s|^extraVolumeMounts:.*|extraVolumeMounts:\n  - name: root-ca\n    mountPath: /etc/ssl/certs/ca-certificates.crt\n    subPath: ca-certificates.crt|g" ${BASEDIR}/installed-values.yaml

# ingress
grep -A 30 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
grep -A 30 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "# hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}i\  hosts:\n    - oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml
grep -A 30 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "# tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}i\  tls:\n    - secretName: oauth2-proxy-tls\n      hosts:\n        - oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml

# create tls oauth2-proxy
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns oauth2-proxy

# create root ca
kubectl create secret generic os-root-ca --from-file=ca-bundle.crt=/etc/ssl/certs/ca-bundle.crt --from-file=ca-certificates.crt=/etc/ssl/certs/ca-bundle.crt -n oauth2-proxy

# create tls secret
kubectl -n oauth2-proxy create secret tls oauth2-proxy-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# create oauth2-proxy config configmap
cat << EOF > keycloak-config
http_address="0.0.0.0:4180"
email_domains=["*"]
upstreams=["file:///dev/null"]
cookie_secure=false
cookie_domains=[".${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}"]
whitelist_domains=[".${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}"]

session_cookie_minimal=true
#set_xauthrequest=true
#set_authorization_header=true
#pass_access_token=true

# keycloak provider
provider="oidc"
provider_display_name="Keycloak"
oidc_issuer_url="https://keycloak.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${CURRENT_CLUSTER}"
redirect_url="https://oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/oauth2/callback"
EOF
kubectl create configmap config --from-file=oauth2_proxy.cfg=keycloak-config -n oauth2-proxy
rm -rf keycloak-config

# install
helm install oauth2-proxy playcekube/oauth2-proxy -n oauth2-proxy -f ${BASEDIR}/installed-values.yaml

