#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=opendistro-es
CHART_VERSION=1.13.3

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
sed -i "s|imageRegistry: .*|imageRegistry: registry.local.cloud:5000|g" ${BASEDIR}/installed-values.yaml

# elasticsearch config
YAML_TEMP=$(cat ${BASEDIR}/config/elasticsearch.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
grep -A 320 -n "^elasticsearch:" ${BASEDIR}/installed-values.yaml | grep "\-  config:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/config: .*/config:\n${YAML_TEMP}/" ${BASEDIR}/installed-values.yaml
# security config
## openid url
sed -i "s|openid_connect_url: .*|openid_connect_url: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/.well-known/openid-configuration|" ${BASEDIR}/config/config.yml
sed -i "s|openid.connect_url: .*|openid.connect_url: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/.well-known/openid-configuration|" ${BASEDIR}/config/kibana.yml
## node dn


## keycloak secret
REALM_KUBERNETES_SECRET=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get secrets keycloak-client-secret -o jsonpath={.data.kubernetes} | base64 --decode)

sed -i "s|openid.client_secret: .*|openid.client_secret: \"${REALM_KUBERNETES_SECRET}\"|" ${BASEDIR}/config/kibana.yml

YAML_INDENT="\ \ \ \ \ \ \ \ "
YAML_TEMP="${YAML_INDENT}config.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/config.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")
YAML_TEMP="${YAML_TEMP}\\n${YAML_INDENT}internal_users.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/internal_users.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")
YAML_TEMP="${YAML_TEMP}\\n${YAML_INDENT}roles.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/roles.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")
YAML_TEMP="${YAML_TEMP}\\n${YAML_INDENT}roles_mapping.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/roles_mapping.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")
YAML_TEMP="${YAML_TEMP}\\n${YAML_INDENT}tenants.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/tenants.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")
YAML_TEMP="${YAML_TEMP}\\n${YAML_INDENT}action_groups.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/action_groups.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")
YAML_TEMP="${YAML_TEMP}\\n${YAML_INDENT}audit.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/audit.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")
YAML_TEMP="${YAML_TEMP}\\n${YAML_INDENT}nodes_dn.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/nodes_dn.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")
YAML_TEMP="${YAML_TEMP}\\n${YAML_INDENT}whitelist.yml: \|\-\n${YAML_INDENT}\ \ "
YAML_TEMP=${YAML_TEMP}$(cat ${BASEDIR}/config/whitelist.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z "s/\\n/\\\n${YAML_INDENT}\ \ /g")

grep -A 30 -n "^elasticsearch:" ${BASEDIR}/installed-values.yaml | grep "    data: {}" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/data: .*/data:\n${YAML_TEMP}/" ${BASEDIR}/installed-values.yaml
sed -i "s/securityConfigSecret:.*/securityConfigSecret: opendistro-es-secret-config/" ${BASEDIR}/installed-values.yaml

# kibana config
sed -i "s|openid.connect_url: .*|openid.connect_url: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/.well-known/openid-configuration|" ${BASEDIR}/config/kibana.yml
sed -i "s|openid.base_redirect_url: .*|openid.base_redirect_url: https://kibana.${USING_CLUSTER}.${PLAYCE_DOMAIN}|" ${BASEDIR}/config/kibana.yml
YAML_TEMP=$(cat ${BASEDIR}/config/kibana.yml | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
grep -A 100 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep "config:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/config: .*/config: ${YAML_TEMP}/" ${BASEDIR}/installed-values.yaml
grep -A 5 -n "elasticsearchAccount:" ${BASEDIR}/installed-values.yaml | grep "secret:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/secret: .*/secret: elastic-credentials/" ${BASEDIR}/installed-values.yaml
## readinessProbe
cat << EOF > yamltemp.txt
    exec:
      command:
      - bash
      - -c
      - |
        #!/bin/sh
        KIBANA_URL=https://localhost:5601
        [[ "\$(curl -k -u \${ELASTICSEARCH_USERNAME}:\${ELASTICSEARCH_PASSWORD} -s -o /dev/null -w '%{http_code}\n' \${KIBANA_URL}/app/kibana)" == "200" ]];
    initialDelaySeconds: 10
    periodSeconds: 5
EOF
YAML_TEMP=$(cat yamltemp.txt | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
rm -rf yamltemp.txt
grep -A 50 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep "readinessProbe:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/readinessProbe: .*/readinessProbe:\n${YAML_TEMP}/" ${BASEDIR}/installed-values.yaml

# secret mount
sed -i "s|\(.*\)extraVolumes: .*|\1extraVolumes:\n\1  - name: elastic-certificate-crt\n\1    secret:\n\1      defaultMode: 420\n\1      secretName: elastic-certificate-crt|g" ${BASEDIR}/installed-values.yaml
sed -i "s|\(.*\)extraVolumeMounts: .*|\1extraVolumeMounts:\n\1  - name: elastic-certificate-crt\n\1    mountPath: /usr/share/elasticsearch/config/certs|g" ${BASEDIR}/installed-values.yaml

# create tls secret
${PLAYCE_DIR}/playcekube/certificates/create-certs.sh elasticsearch.${USING_CLUSTER}.${PLAYCE_DOMAIN} DNS:elasticsearch.${USING_CLUSTER}.${PLAYCE_DOMAIN},DNS:localhost,IP:${PLAYCE_DEPLOY},IP:127.0.0.1
#kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} delete secret elastic-certificate-crt
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} create secret generic elastic-certificate-crt \
 --from-file=elasticsearch.crt=${PLAYCE_DATADIR}/certificates/certs/elasticsearch.${USING_CLUSTER}.${PLAYCE_DOMAIN}.crt \
 --from-file=elasticsearch.key=${PLAYCE_DATADIR}/certificates/certs/elasticsearch.${USING_CLUSTER}.${PLAYCE_DOMAIN}.key \
 --from-file=kibana.crt=${PLAYCE_DATADIR}/certificates/certs/wild.${USING_CLUSTER}.${PLAYCE_DOMAIN}.crt \
 --from-file=kibana.key=${PLAYCE_DATADIR}/certificates/certs/wild.${USING_CLUSTER}.${PLAYCE_DOMAIN}.key \
 --from-file=root-ca.crt=${PLAYCE_DATADIR}/certificates/ca/playcecloud_rootca.crt
ELASTICSEARCH_USERNAME=kibanaserver
ELASTICSEARCH_PASSWORD=vmffpdltmkibana
COOKIE_SECRET=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\n' | tr -- '+/' '-_'; echo)
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} delete secret elastic-credentials
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} create secret generic elastic-credentials --from-literal=password=${ELASTICSEARCH_PASSWORD} --from-literal=username=${ELASTICSEARCH_USERNAME} --from-literal=cookie=${COOKIE_SECRET}

# kibana ingress enable
grep -A 100 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep -A 20 "  ingress:" | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# kibana ingress hosts
grep -A 100 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep -A 20 "  ingress:" | grep " - chart-example.local" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|- chart-example.local|- kibana.${USING_CLUSTER}.${PLAYCE_DOMAIN}|" ${BASEDIR}/installed-values.yaml
# kibana ingress tls
grep -A 100 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep -A 20 "  ingress:" | grep "tls: .*" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: wild-tls\n\1    hosts:\n\1    - kibana.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 100 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep -A 20 "  ingress:" | grep "annotations: .*" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)annotations: .*/\1annotations:\n\1  nginx.ingress.kubernetes.io\/backend-protocol: \"HTTPS\"/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

# ready check
POD_NAME=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get pod -l app=opendistro-es,role=kibana -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{ end }' | head -n 1)
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} wait --for=condition=Ready pod/${POD_NAME} --timeout=300s

# add default index pattern
cat << EOF > add-indexpattern.sh
#!/bin/bash
KIBANA_URL=https://localhost:5601
curl -f -k -u playce-admin:vmffpdltm -X POST --header 'Content-Type: application/json' --header 'kbn-xsrf: this_is_required_header' "\${KIBANA_URL}/api/saved_objects/index-pattern/logstash-*?overwrite=true" --data '{"attributes":{"title":"logstash-*","timeFieldName":"@timestamp"}}' "\${KIBANA_URL}/api/saved_objects/index-pattern/logstash-*?overwrite=true"
EOF
chmod 755 add-indexpattern.sh
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} cp add-indexpattern.sh ${POD_NAME}:/tmp/add-indexpattern.sh
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} exec ${POD_NAME} -- /tmp/add-indexpattern.sh
rm -rf add-indexpattern.sh

