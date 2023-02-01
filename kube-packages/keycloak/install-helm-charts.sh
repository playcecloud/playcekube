#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=keycloak
CHART_VERSION=9.2.2

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}

# installed-values.yaml private registry setting
grep -A 3 -n "^global:" ${BASEDIR}/installed-values.yaml | grep "imageRegistry:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/imageRegistry: .*/imageRegistry: registry.local.cloud:5000/" ${BASEDIR}/installed-values.yaml

# admin info
ADMIN_USER=playce-admin
ADMIN_PASSWORD=vmffpdltm

# secret
sed -i "s/  adminUser: .*/  adminUser: ${ADMIN_USER}/g" ${BASEDIR}/installed-values.yaml
sed -i "s/  adminPassword: .*/  adminPassword: ${ADMIN_PASSWORD}/g" ${BASEDIR}/installed-values.yaml
# db password fix
sed -i "s/ password: .*/ password: 'keypass1!'/g" ${BASEDIR}/installed-values.yaml

# keycloak ingress enable
grep -A 5 -n "^service:" ${BASEDIR}/installed-values.yaml | grep "type:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/type: .*/type: ClusterIP/" ${BASEDIR}/installed-values.yaml
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# keycloak ingress hosts
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "hostname:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/hostname: .*/hostname: keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# keycloak ingress tls
sed -i "s/^proxyAddressForwarding: .*/proxyAddressForwarding: true/" ${BASEDIR}/installed-values.yaml
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls: true/" ${BASEDIR}/installed-values.yaml
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "  extraTls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)extraTls:.*/\1extraTls:\n\1  - hosts:\n\1      - keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}\n\1    secretName: wild-tls/" ${BASEDIR}/installed-values.yaml
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "  annotations:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/  annotations: .*/  annotations:\n    nginx.ingress.kubernetes.io\/proxy-buffer-size: 64k/" ${BASEDIR}/installed-values.yaml

# init cli
grep -A 5 -n "^keycloakConfigCli:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
grep -A 5 -n "keycloakConfigCli.existingConfigmap" ${BASEDIR}/installed-values.yaml | grep "existingConfigmap:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/existingConfigmap: .*/existingConfigmap: keycloak-init-config/" ${BASEDIR}/installed-values.yaml

# create keycloak init config
rm -rf /tmp/keycloak-init.json
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} delete configmap keycloak-init-config
cp ${PLAYCE_DIR}/playcekube/kube-packages/keycloak/template-init.json /tmp/keycloak-init.json
sed -i "s/<<USING_CLUSTER>>/${USING_CLUSTER}/g" /tmp/keycloak-init.json
sed -i "s/<<PLAYCE_DOMAIN>>/${PLAYCE_DOMAIN}/g" /tmp/keycloak-init.json
sed -i "s/<<ADMIN_USER>>/${ADMIN_USER}/g" /tmp/keycloak-init.json
sed -i "s/<<ADMIN_PASSWORD>>/${ADMIN_PASSWORD}/g" /tmp/keycloak-init.json
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} create configmap keycloak-init-config --from-file=keycloak-init.json=/tmp/keycloak-init.json
rm -rf /tmp/keycloak-init.json

# install
helm --kube-context=${USING_CONTEXT} -n ${CHART_NAMESPACE} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} \
 -f ${BASEDIR}/installed-values.yaml \

# Ready check
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} wait --for=condition=Ready pod/keycloak-0 --timeout=300s

# create client secret
cat << EOF > create-secret.sh
#!/bin/bash
kcadm.sh config credentials --server http://localhost:\${KEYCLOAK_HTTP_PORT} --realm master --user \${KEYCLOAK_ADMIN_USER} --password \${KEYCLOAK_ADMIN_PASSWORD} --config=/tmp/kcadm.config
REALM_KUBERNETES_ID=\$(kcadm.sh get clients --config /tmp/kcadm.config -r ${USING_CLUSTER} -q clientId=kubernetes --fields id --format csv --noquotes)
kcadm.sh create --config=/tmp/kcadm.config clients/\${REALM_KUBERNETES_ID}/client-secret -r ${USING_CLUSTER} -s realm=${USING_CLUSTER}
REALM_KUBERNETES_SECRET=\$(kcadm.sh get clients/\${REALM_KUBERNETES_ID}/client-secret --config /tmp/kcadm.config -r ${USING_CLUSTER} -q clientId=kubernetes --fields value --format csv --noquotes)
echo \${REALM_KUBERNETES_SECRET}
EOF
chmod 755 create-secret.sh

kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} cp create-secret.sh keycloak-0:/tmp/create-secret.sh
REALM_KUBERNETES_SECRET=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} exec keycloak-0 -- /tmp/create-secret.sh)
rm -rf create-secret.sh

# user add group
cat << EOF > group-update.sh
#!/bin/bash
kcadm.sh config credentials --server http://localhost:\${KEYCLOAK_HTTP_PORT} --realm master --user \${KEYCLOAK_ADMIN_USER} --password \${KEYCLOAK_ADMIN_PASSWORD} --config=/tmp/kcadm.config
GROUP_ID=\$(kcadm.sh get groups --config=/tmp/kcadm.config -r ${USING_CLUSTER} --fields name,id --format csv --noquotes | grep "admin" | awk -F, '{ print \$2 }')
USER_ID=\$(kcadm.sh get users --config=/tmp/kcadm.config -r ${USING_CLUSTER} -q username=${ADMIN_USER} --fields username,id --format csv --noquotes | grep "${ADMIN_USER}" | awk -F, '{ print \$2 }')
kcadm.sh update --config=/tmp/kcadm.config users/\${USER_ID}/groups/\${GROUP_ID} -r ${USING_CLUSTER} -s realm=${USING_CLUSTER} -s userId=\${USER_ID} -s groupId=\${GROUP_ID} -n
EOF
chmod 755 group-update.sh

kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} cp group-update.sh keycloak-0:/tmp/group-update.sh
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} exec keycloak-0 -- /tmp/group-update.sh
rm -rf group-update.sh

# secret create
kubectl --context=${USING_CONTEXT} -n playcekube delete secret keycloak-client-secret
kubectl --context=${USING_CONTEXT} -n playcekube-dev delete secret keycloak-client-secret
kubectl --context=${USING_CONTEXT} -n playcekube create secret generic keycloak-client-secret --from-literal=kubernetes=${REALM_KUBERNETES_SECRET}
kubectl --context=${USING_CONTEXT} -n playcekube-dev create secret generic keycloak-client-secret --from-literal=kubernetes=${REALM_KUBERNETES_SECRET}

# role binding
kubectl --context=${USING_CONTEXT} apply -f - << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-cluster-admin
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: oidc:admin
EOF

