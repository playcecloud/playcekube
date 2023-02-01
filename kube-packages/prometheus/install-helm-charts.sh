#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=kube-prometheus-stack
CHART_VERSION=35.3.1

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}

# installed-values.yaml private registry setting
sed -i "s|repository: quay\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: k8s\.gcr\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.local.cloud:5000/\1|g" ${BASEDIR}/installed-values.yaml

# admin info
sed -i "s/adminUser: .*/adminUser: playce-admin/" ${BASEDIR}/installed-values.yaml
sed -i "s/adminPassword: .*/adminPassword: vmffpdltm/" ${BASEDIR}/installed-values.yaml

# oidc config
# get keycloak kubernetes secret
REALM_KUBERNETES_SECRET=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get secrets keycloak-client-secret -o jsonpath={.data.kubernetes} | base64 --decode)
if [[ "${REALM_KUBERNETES_SECRET}" != "" ]]; then

cat << EOF > yamltemp.txt
    auth.generic_oauth:
      enabled: true
      name: KeyCloak
      allow_sign_up: true
      client_id: kubernetes
      client_secret: ${REALM_KUBERNETES_SECRET}
      scopes: openid
      tls_skip_verify_insecure: false
      tls_client_ca: /etc/grafana/ssl/root-ca.crt
      tls_client_cert: /etc/grafana/ssl/grafana.crt
      tls_client_key: /etc/grafana/ssl/grafana.key
      auth_url: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/protocol/openid-connect/auth
      token_url: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/protocol/openid-connect/token
      api_url: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/protocol/openid-connect/userinfo
      signout_redirect_url: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/protocol/openid-connect/logout?redirect_uri=https%3A%2F%2Fgrafana.${USING_CLUSTER}.${PLAYCE_DOMAIN}
      role_attribute_path: contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'developers') && 'Editor' || 'Viewer'
    server:
      root_url: https://grafana.${USING_CLUSTER}.${PLAYCE_DOMAIN}
EOF
YAML_TEMP=$(cat yamltemp.txt | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g' | sed "s/\&/\\\&/g")
rm -rf yamltemp.txt
sed -i "s/grafana.ini:/grafana.ini:\n${YAML_TEMP}/" ${BASEDIR}/installed-values.yaml
fi

# tls configmap
sed -i "s|extraConfigmapMounts: .*|extraConfigmapMounts:\n    - name: certs-configmap\n      mountPath: /etc/grafana/ssl/\n      subPath: \"\"\n      configMap: certs-configmap\n      readOnly: true|" ${BASEDIR}/installed-values.yaml

# timezone
sed -i "s/defaultDashboardsTimezone: .*/defaultDashboardsTimezone: Asia\/Seoul/" ${BASEDIR}/installed-values.yaml

# etcd metrics config
POD_NAME=$(kubectl --context=${USING_CONTEXT} -n kube-system get pods -o=jsonpath='{.items[0].metadata.name}' -l component=etcd)
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} create secret generic etcd-client-cert \
  --from-literal=etcd-ca="$(kubectl --context=${USING_CONTEXT} -n kube-system exec ${POD_NAME} -- cat /etc/kubernetes/ssl/etcd/ca.crt)" \
  --from-literal=etcd-client="$(kubectl --context=${USING_CONTEXT} -n kube-system exec ${POD_NAME} -- cat /etc/kubernetes/ssl/etcd/healthcheck-client.crt)" \
  --from-literal=etcd-client-key="$(kubectl --context=${USING_CONTEXT} -n kube-system exec ${POD_NAME} -- cat /etc/kubernetes/ssl/etcd/healthcheck-client.key)"
sed -i "s/    secrets: \[\]/    secrets:\n      - \"etcd-client-cert\"/g" ${BASEDIR}/installed-values.yaml

grep -A 50 -n "^kubeEtcd:" ${BASEDIR}/installed-values.yaml | grep -A 15 "  serviceMonitor:" | grep "scheme:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/scheme: .*/scheme: https/" ${BASEDIR}/installed-values.yaml
grep -A 50 -n "^kubeEtcd:" ${BASEDIR}/installed-values.yaml | grep -A 15 "  serviceMonitor:" | grep "caFile:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|caFile: .*|caFile: /etc/prometheus/secrets/etcd-client-cert/etcd-ca|" ${BASEDIR}/installed-values.yaml
grep -A 50 -n "^kubeEtcd:" ${BASEDIR}/installed-values.yaml | grep -A 15 "  serviceMonitor:" | grep "certFile:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|certFile: .*|certFile: /etc/prometheus/secrets/etcd-client-cert/etcd-client|" ${BASEDIR}/installed-values.yaml
grep -A 50 -n "^kubeEtcd:" ${BASEDIR}/installed-values.yaml | grep -A 15 "  serviceMonitor:" | grep "keyFile:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|keyFile: .*|keyFile: /etc/prometheus/secrets/etcd-client-cert/etcd-client-key|" ${BASEDIR}/installed-values.yaml

sed -i "s/  additionalScrapeConfigs: .*/  additionalScrapeConfigs:/g" ${BASEDIR}/installed-values.yaml
grep -A 27 -n "  additionalScrapeConfigs:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{},27s/# /  /g" ${BASEDIR}/installed-values.yaml
grep -A 27 -n "  additionalScrapeConfigs:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{},27s/targetLabel/target_label/g" ${BASEDIR}/installed-values.yaml

# create tls configmap
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} create configmap certs-configmap --from-file=root-ca.crt=${PLAYCE_DATADIR}/certificates/ca/playcecloud_rootca.crt --from-file=grafana.crt=${PLAYCE_DATADIR}/certificates/certs/wild.${USING_CLUSTER}.${PLAYCE_DOMAIN}.crt --from-file=grafana.key=${PLAYCE_DATADIR}/certificates/certs/wild.${USING_CLUSTER}.${PLAYCE_DOMAIN}.key

# prometheus ingress enable => disable
#grep -B 27 -A 7 -n "TLS configuration for Prometheus Ingress" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# prometheus ingress hosts
#grep -B 27 -A 7 -n "TLS configuration for Prometheus Ingress" ${BASEDIR}/installed-values.yaml | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts: .*/\1hosts:\n\1  - prometheus.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# prometheus ingress tls
#grep -B 27 -A 7 -n "TLS configuration for Prometheus Ingress" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: wild-tls\n\1    hosts:\n\1      - prometheus.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# grafana ingress enable
grep -B 1 -A 35 -n "Grafana Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# prometheus ingress hosts
grep -B 1 -A 35 -n "Grafana Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts: .*/\1hosts:\n\1  - grafana.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# prometheus ingress tls
grep -B 1 -A 35 -n "Grafana Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: wild-tls\n\1    hosts:\n\1      - grafana.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} -n ${CHART_NAMESPACE} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} \
 -f ${BASEDIR}/installed-values.yaml

