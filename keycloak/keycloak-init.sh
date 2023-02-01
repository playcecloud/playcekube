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
docker exec -it playcecloud_keycloak /bin/sh -c 'while [ "$(curl http://localhost:8080 -Ls -w %{http_code} -o /dev/null)" != "200" ] ; do sleep 5; done;'

# start
echo "[INFO] Start initialize keycloak"

ADMIN_USER=playce-admin
ADMIN_PASSWD=vmffpdltm
REALM_NAME=playcecloud
CLIENT_ID=playcecloud

# cli init json
cat << EOF > ${BASEDIR}/init.json
{
    "realm": "${REALM_NAME}",
    "enabled": true,
    "displayName": "Playce Cloud",
    "displayNameHtml": "<div class=\"kc-logo-text\"><span>Playce Cloud</span></div>",
    "clients": [
        {
            "clientId": "${CLIENT_ID}",
            "enabled": true,
            "baseUrl": "https://keycloak.local.cloud/realms/${REALM_NAME}/account/",
            "clientAuthenticatorType": "client-secret",
            "redirectUris": [ "https://*" ],
            "webOrigins": [ "*" ],
            "directAccessGrantsEnabled": true,
            "serviceAccountsEnabled": false,
            "publicClient": false,
            "protocol": "openid-connect",
            "protocolMappers": [
                {
                    "name": "groups",
                    "protocol": "openid-connect",
                    "protocolMapper": "oidc-group-membership-mapper",
                    "consentRequired": false,
                    "config": {
                        "full.path": "false",
                        "id.token.claim": "true",
                        "access.token.claim": "true",
                        "claim.name": "groups",
                        "userinfo.token.claim": "true"
                    }
                },
                {
                    "name": "audience",
                    "protocol": "openid-connect",
                    "protocolMapper": "oidc-audience-mapper",
                    "consentRequired": false,
                    "config": {
                        "included.client.audience": "${CLIENT_ID}",
                        "id.token.claim": "false",
                        "access.token.claim": "true",
                        "included.custom.audience": "${CLIENT_ID}"
                    }
                }
            ],
            "frontchannelLogout": false
        }
    ],
    "users": [
        {
            "username": "${ADMIN_USER}",
            "email": "${ADMIN_USER}@local.cloud",
            "enabled": true,
            "credentials": [
                {
                    "type": "password",
                    "value": "${ADMIN_PASSWD}"
                }
            ]
         }
    ],
    "groups": [
        {
            "name": "admin"
        },
        {
            "name": "developers"
        }
    ]
}
EOF

cat << EOF > ${BASEDIR}/realm-add.sh
#!/bin/bash
# auth
/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user \${KEYCLOAK_ADMIN} --password \${KEYCLOAK_ADMIN_PASSWORD} --config=/tmp/kcadm.config
# create realm
/opt/keycloak/bin/kcadm.sh create realms --config=/tmp/kcadm.config -r ${REALM_NAME} -f /tmp/init.json
# create secret
REALM_KUBERNETES_ID=\$(/opt/keycloak/bin/kcadm.sh get clients --config /tmp/kcadm.config -r ${REALM_NAME} -q clientId=${CLIENT_ID} --fields id --format csv --noquotes)
/opt/keycloak/bin/kcadm.sh create --config=/tmp/kcadm.config clients/\${REALM_KUBERNETES_ID}/client-secret -r ${REALM_NAME} -s realm=${REALM_NAME}
# add user,group
GROUP_ID=\$(/opt/keycloak/bin/kcadm.sh get groups --config=/tmp/kcadm.config -r ${REALM_NAME} --fields name,id --format csv --noquotes | grep "admin" | awk -F, '{ print \$2 }')
USER_ID=\$(/opt/keycloak/bin/kcadm.sh get users --config=/tmp/kcadm.config -r ${REALM_NAME} -q username=${ADMIN_USER} --fields username,id --format csv --noquotes | grep "${ADMIN_USER}" | awk -F, '{ print \$2 }')
/opt/keycloak/bin/kcadm.sh update --config=/tmp/kcadm.config users/\${USER_ID}/groups/\${GROUP_ID} -r ${REALM_NAME} -s realm=${REALM_NAME} -s userId=\${USER_ID} -s groupId=\${GROUP_ID} -n
EOF
chmod 755 ${BASEDIR}/realm-add.sh

docker cp ${BASEDIR}/init.json playcecloud_keycloak:/tmp/init.json
docker cp ${BASEDIR}/realm-add.sh playcecloud_keycloak:/tmp/realm-add.sh
docker exec playcecloud_keycloak /tmp/realm-add.sh
rm -rf ${BASEDIR}/init.json ${BASEDIR}/realm-add.sh

