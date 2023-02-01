#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube-dev
CHART_NAME=harbor
CHART_VERSION=14.0.3

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
## harbor
sed -i "s/imageRegistry: .*/imageRegistry: registry.local.cloud:5000/" ${BASEDIR}/installed-values.yaml
## etc images
sed -i "s/registry: .*/registry: registry.local.cloud:5000/g" ${BASEDIR}/installed-values.yaml

# admin password
sed -i "s/^adminPassword: .*/adminPassword: vmffpdltm/g" ${BASEDIR}/installed-values.yaml
# user config
sed -i "s/configOverwriteJsonSecret: .*/configOverwriteJsonSecret: harbor-userconfig-secret/g" ${BASEDIR}/installed-values.yaml

# admin idchange
cat << EOF > yamltemp.txt
      exec:
        command:
        - bash
        - -c
        - |
          #!/bin/sh
          while [[ "\$(curl -k -u admin:vmffpdltm -s -o /dev/null -w '%{http_code}\n' \${CORE_URL}/api/v2.0/users/current)" != "200" ]]; do sleep 5; done;
          curl -X PUT -u admin:vmffpdltm \${CORE_URL}/api/v2.0/users/1 -H 'Content-Type: application/json' -k -d'{"email":"admin@${USING_CLUSTER}.${PLAYCE_DOMAIN}","realname":"system admin"}'
          curl -X POST -k -u admin:vmffpdltm \${CORE_URL}/api/internal/renameadmin -H 'Content-Type: application/json' -H 'accept: application/json' -d'{"username":"admin@${USING_CLUSTER}.${PLAYCE_DOMAIN}"}' -v
EOF
YAML_TEMP=$(cat yamltemp.txt | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
rm -rf yamltemp.txt
#grep -A 5 -n "jobservice.lifecycleHooks" ${BASEDIR}/installed-values.yaml | grep "lifecycleHooks:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)lifecycleHooks: .*/\1lifecycleHooks:\n\1  postStart:\n${YAML_TEMP}/" ${BASEDIR}/installed-values.yaml

# user config secret
## keycloak secret
REALM_KUBERNETES_SECRET=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get secrets keycloak-client-secret -o jsonpath={.data.kubernetes} | base64 --decode)
if [[ "${REALM_KUBERNETES_SECRET}" != "" ]]; then
cat << EOF > tempsecret.temp
{
"auth_mode":"oidc_auth",
"oidc_name":"KeyCloak",
"oidc_endpoint":"https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}",
"oidc_client_id":"kubernetes",
"oidc_client_secret":"${REALM_KUBERNETES_SECRET}",
"oidc_groups_claim":"groups",
"oidc_admin_group":"admin",
"oidc_scope":"openid",
"oidc_verify_cert":false,
"oidc_auto_onboard":true,
"oidc_user_claim": "preferred_username"
}
EOF
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} create secret generic harbor-userconfig-secret --from-file=overrides.json=tempsecret.temp
rm -rf tempsecret.temp

# user config
sed -i "s/configOverwriteJsonSecret: .*/configOverwriteJsonSecret: harbor-userconfig-secret/g" ${BASEDIR}/installed-values.yaml
fi

# service mode ClusterIP
grep -A 3 -n "^service:" ${BASEDIR}/installed-values.yaml | grep "type:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/type: .*/type: ClusterIP/" ${BASEDIR}/installed-values.yaml

# ingress enable
sed -i "s/^exposureType: .*/exposureType: ingress/g" ${BASEDIR}/installed-values.yaml

# harbor secret
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} create secret tls harbor.${USING_CLUSTER}.${PLAYCE_DOMAIN}-tls --cert=${PLAYCE_DATADIR}/certificates/certs/wild.${USING_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DATADIR}/certificates/certs/wild.${USING_CLUSTER}.${PLAYCE_DOMAIN}.key

# ingress hosts setting
sed -i "s|^externalURL: .*|externalURL: https://harbor.${USING_CLUSTER}.${PLAYCE_DOMAIN}|g" ${BASEDIR}/installed-values.yaml
## core
grep -A 20 -n "^  core:" ${BASEDIR}/installed-values.yaml | grep "hostname:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/hostname: .*/hostname: harbor.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^  core:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls: true/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^  core:" ${BASEDIR}/installed-values.yaml | grep "  extraTls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)extraTls:.*/\1extraTls:\n\1- hosts:\n\1    - harbor.${USING_CLUSTER}.${PLAYCE_DOMAIN}\n\1  secretName: harbor.${USING_CLUSTER}.${PLAYCE_DOMAIN}-tls/" ${BASEDIR}/installed-values.yaml

## notary
grep -A 20 -n "^  notary:" ${BASEDIR}/installed-values.yaml | grep "hostname:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/hostname: .*/hostname: notary.harbor.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^  notary:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls: true/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^  notary:" ${BASEDIR}/installed-values.yaml | grep "  extraTls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)extraTls:.*/\1extraTls:\n\1- hosts:\n\1    - notary.harbor.${USING_CLUSTER}.${PLAYCE_DOMAIN}\n\1  secretName: harbor.${USING_CLUSTER}.${PLAYCE_DOMAIN}-tls/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml


