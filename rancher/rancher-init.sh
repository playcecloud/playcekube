#!/bin/bash

# sh config
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# wait keycloak start
echo "[INFO] Wait for keycloak start..."
docker exec -it playcecloud_keycloak /bin/sh -c 'while [ "$(curl http://localhost:8080 -Lsk -w %{http_code} -o /dev/null)" != "200" ] ; do sleep 5; done;'

# wait rancher start
echo "[INFO] Wait for rancher start..."
docker exec -it playcekube_rancher /bin/sh -c 'while [ "$(curl http://127.0.0.1:80 -Lsk -w %{http_code} -o /dev/null)" != "200" ] ; do sleep 5; done;'

# start
echo "[INFO] Start initialize rancher"

ADMIN_USER=playce-admin
ADMIN_PASSWD=vmffpdltm
REALM_NAME=playcecloud
CLIENT_ID=playcecloud
CLIENT_SECRET=
CLIENT_ADMIN_ID=

# get client secret
cat << EOF > ${BASEDIR}/get-client-secret.sh
#!/bin/bash
# auth
/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user \${KEYCLOAK_ADMIN} --password \${KEYCLOAK_ADMIN_PASSWORD} --config=/tmp/kcadm.config
# get secret
REALM_KUBERNETES_ID=\$(/opt/keycloak/bin/kcadm.sh get clients --config /tmp/kcadm.config -r ${REALM_NAME} -q clientId=${CLIENT_ID} --fields id --format csv --noquotes)
REALM_KUBERNETES_SECRET=\$(/opt/keycloak/bin/kcadm.sh get clients/\${REALM_KUBERNETES_ID}/client-secret --config /tmp/kcadm.config -r ${REALM_NAME} -q clientId=${CLIENT_ID} --fields value --format csv --noquotes)
echo \${REALM_KUBERNETES_SECRET}
EOF
chmod 755 ${BASEDIR}/get-client-secret.sh

docker cp ${BASEDIR}/get-client-secret.sh playcecloud_keycloak:/tmp/get-client-secret.sh
CLIENT_SECRET=$(docker exec playcecloud_keycloak /tmp/get-client-secret.sh)
rm -rf ${BASEDIR}/get-client-secret.sh

# get client admin
cat << EOF > ${BASEDIR}/get-client-admin.sh
#!/bin/bash
# auth
/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user \${KEYCLOAK_ADMIN} --password \${KEYCLOAK_ADMIN_PASSWORD} --config=/tmp/kcadm.config
# get secret
CLIENT_ADMIN_ID=\$(/opt/keycloak/bin/kcadm.sh get users --config /tmp/kcadm.config -r ${REALM_NAME} -q username=${ADMIN_USER} --fields id --format csv --noquotes)
echo \${CLIENT_ADMIN_ID}
EOF
chmod 755 ${BASEDIR}/get-client-admin.sh
docker cp ${BASEDIR}/get-client-admin.sh playcecloud_keycloak:/tmp/get-client-admin.sh
CLIENT_ADMIN_ID=$(docker exec playcecloud_keycloak /tmp/get-client-admin.sh)
rm -rf ${BASEDIR}/get-client-admin.sh

# admin user
RANCHER_ADMIN=$(docker exec playcekube_rancher kubectl get users -l authz.management.cattle.io/bootstrapping=admin-user -o jsonpath={.items[0].metadata.name})

# secret
RANCHER_SECRET_NAME=token-first
RANCHER_SECRET=$(echo $RANDOM | sha256sum | head -c 50)
sed -i "s/^RANCHER_SECRET=.*/RANCHER_SECRET=${RANCHER_SECRET_NAME}:${RANCHER_SECRET}/g" ${PLAYCE_DIR}/playcecloud.conf

# init settings
cat << EOF > ${BASEDIR}/settings.yaml
---
apiVersion: management.cattle.io/v3
kind: AuthConfig
metadata:
  name: keycloakoidc
type: keyCloakOIDCConfig
allowedPrincipalIds:
- keycloakoidc_user://${CLIENT_ADMIN_ID}
accessMode: unrestricted
authEndpoint: https://keycloak.${PLAYCE_DOMAIN}:9443/realms/${REALM_NAME}/protocol/openid-connect/auth
clientId: ${CLIENT_ID}
clientSecret: ${CLIENT_SECRET}
enabled: true
groupSearchEnabled: true
issuer: https://keycloak.${PLAYCE_DOMAIN}:9443/realms/${REALM_NAME}
privateKey: ""
rancherUrl: https://rancher.${PLAYCE_DOMAIN}:8443/verify-auth
scope: openid profile email
---
apiVersion: management.cattle.io/v3
displayName: Default Admin
kind: User
metadata:
  name: ${RANCHER_ADMIN}
username: admin
password: \$2a\$10\$DwdFVHLZrGV8fnHi4XWxPe7/q7WT2wgrHFFonplZvJ43eujLwmrVC
principalIds:
- local://${RANCHER_ADMIN}
- keycloakoidc_user://${CLIENT_ADMIN_ID}
---
apiVersion: management.cattle.io/v3
kind: Token
metadata:
  name: ${RANCHER_SECRET_NAME}
  labels:
    authn.management.cattle.io/token-userId: ${RANCHER_ADMIN}
authProvider: keycloakoidc
current: false
description: First token
expired: false
isDerived: true
token: ${RANCHER_SECRET}
ttl: 0
userId: ${RANCHER_ADMIN}
userPrincipal:
  displayName: playce-admin@playce.cloud
  loginName: playce-admin@playce.cloud
  me: true
  metadata:
    name: keycloakoidc_user://${CLIENT_ADMIN_ID}
  principalType: user
  provider: keycloakoidc
---
apiVersion: management.cattle.io/v3
kind: Catalog
metadata:
  name: playce-library
spec:
  branch: ""
  catalogKind: helm:http
  description: "Playce Cloud helm charts"
  url: https://repository.local.cloud/helm-charts
---
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: first-login
default: "true"
value: "false"
customized: false
---
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: server-url
value: "https://rancher.${PLAYCE_DOMAIN}:8443"
customized: false
---
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: hide-local-cluster
default: "false"
value: "true"
customized: false
---
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: ui-brand
default: null
value: "Playce Cloud"
customized: false
---
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: ui-logo-light
default: null
value: data:image/png;base64,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
---
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: ui-pl
default: "rancher"
value: "Playce Cloud"
customized: false
---
apiVersion: management.cattle.io/v3
kind: Feature
metadata:
  name: continuous-delivery
spec:
  value: false
---
apiVersion: management.cattle.io/v3
kind: Feature
metadata:
  name: harvester
spec:
  value: false
---
apiVersion: management.cattle.io/v3
kind: Feature
metadata:
  name: rke1-custom-node-cleanup
spec:
  value: false
---
apiVersion: management.cattle.io/v3
kind: Feature
metadata:
  name: rke2
spec:
  value: false
EOF

docker cp ${BASEDIR}/settings.yaml playcekube_rancher:/tmp/settings.yaml
docker exec playcekube_rancher kubectl apply -f /tmp/settings.yaml
rm -rf ${BASEDIR}/settings.yaml

