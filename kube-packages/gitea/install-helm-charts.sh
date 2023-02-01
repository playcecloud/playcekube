#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube-dev
CHART_NAME=gitea
CHART_VERSION=5.0.9

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
## gitea
sed -i "s|repository: \(.*\)|repository: registry.local.cloud:5000/\1|" ${BASEDIR}/installed-values.yaml
## memcached
sed -i "/^memcached:/a\  image:\n    registry: registry.local.cloud:5000" ${BASEDIR}/installed-values.yaml
## postgresql
sed -i "/^postgresql:/a\  image:\n    registry: registry.local.cloud:5000" ${BASEDIR}/installed-values.yaml
## mysql
sed -i "/^mysql:/a\  image:\n    registry: registry.local.cloud:5000" ${BASEDIR}/installed-values.yaml
## mariadb
sed -i "/^mariadb:/a\  image:\n    registry: registry.local.cloud:5000" ${BASEDIR}/installed-values.yaml

# protocol config
sed -i "s/config: .*/config:\n    server:\n      ROOT_URL: https\:\/\/gitea.${USING_CLUSTER}.${PLAYCE_DOMAIN}\n    oauth2_client:\n      ENABLE_AUTO_REGISTRATION: true\n      USERNAME: nickname\n    service:\n      ALLOW_ONLY_EXTERNAL_REGISTRATION: true\n    webhook:\n      SKIP_TLS_VERIFY: true\n      ALLOWED_HOST_LIST: \"*\" /" ${BASEDIR}/installed-values.yaml

# user setting
grep -A 5 -n "^gitea:" ${BASEDIR}/installed-values.yaml | grep "username:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/username: .*/username: gitea-admin/" ${BASEDIR}/installed-values.yaml
grep -A 5 -n "^gitea:" ${BASEDIR}/installed-values.yaml | grep "password:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/password: .*/password: vmffpdltm/" ${BASEDIR}/installed-values.yaml

# certs volume mount
sed -i "s|^extraVolumes:.*|extraVolumes:\n  - name: root-ca\n    secret:\n      secretName: os-root-ca|g" ${BASEDIR}/installed-values.yaml
sed -i "s|^extraVolumeMounts:.*|extraVolumeMounts:\n  - name: root-ca\n    mountPath: /etc/ssl/certs/ca-certificates.crt\n    subPath: ca-certificates.crt|g" ${BASEDIR}/installed-values.yaml

## keycloak secret
REALM_KUBERNETES_SECRET=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get secrets keycloak-client-secret -o jsonpath={.data.kubernetes} | base64 --decode)
if [[ "${REALM_KUBERNETES_SECRET}" != "" ]]; then
## readinessProbe
cat << EOF > yamltemp.txt
    - name: KeyCloak
      provider: openidConnect
      key: kubernetes
      secret: ${REALM_KUBERNETES_SECRET}
      autoDiscoverUrl: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/.well-known/openid-configuration
      groupClaimName: groups
      adminGroup: admin
EOF

YAML_TEMP=$(cat yamltemp.txt | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
rm -rf yamltemp.txt
sed -i "s/oauth: .*/oauth:\n${YAML_TEMP}/" ${BASEDIR}/installed-values.yaml
fi

# ingress enable
grep -A 3 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml

# ingress hosts setting
grep -A 15 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "\- host:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/host: .*/host: gitea.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls:/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\    - secretName: wild-tls\n      hosts:\n        - gitea.${USING_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

