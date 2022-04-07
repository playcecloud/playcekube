#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall prometheus -n monitoring 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns monitoring 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|repository: quay\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: k8s\.gcr\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# admin password
sed -i "s/adminPassword: .*/adminPassword: oscadmin/" ${BASEDIR}/installed-values.yaml

# timezone
sed -i "s/defaultDashboardsTimezone: .*/defaultDashboardsTimezone: Asia\/Seoul/" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns monitoring

# etcd metrics config
POD_NAME=$(kubectl get pods -o=jsonpath='{.items[0].metadata.name}' -l component=etcd -n kube-system)
kubectl create secret generic etcd-client-cert -n monitoring \
  --from-literal=etcd-ca="$(kubectl exec ${POD_NAME} -n kube-system -- cat /etc/kubernetes/ssl/etcd/ca.crt)" \
  --from-literal=etcd-client="$(kubectl exec ${POD_NAME} -n kube-system -- cat /etc/kubernetes/ssl/etcd/healthcheck-client.crt)" \
  --from-literal=etcd-client-key="$(kubectl exec ${POD_NAME} -n kube-system -- cat /etc/kubernetes/ssl/etcd/healthcheck-client.key)"
sed -i "s/    secrets: \[\]/    secrets:\n      - \"etcd-client-cert\"/g" ${BASEDIR}/installed-values.yaml

grep -A 50 -n "^kubeEtcd:" ${BASEDIR}/installed-values.yaml | grep -A 15 "  serviceMonitor:" | grep "scheme:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/scheme: .*/scheme: https/" ${BASEDIR}/installed-values.yaml
grep -A 50 -n "^kubeEtcd:" ${BASEDIR}/installed-values.yaml | grep -A 15 "  serviceMonitor:" | grep "caFile:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|caFile: .*|caFile: /etc/prometheus/secrets/etcd-client-cert/etcd-ca|" ${BASEDIR}/installed-values.yaml
grep -A 50 -n "^kubeEtcd:" ${BASEDIR}/installed-values.yaml | grep -A 15 "  serviceMonitor:" | grep "certFile:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|certFile: .*|certFile: /etc/prometheus/secrets/etcd-client-cert/etcd-client|" ${BASEDIR}/installed-values.yaml
grep -A 50 -n "^kubeEtcd:" ${BASEDIR}/installed-values.yaml | grep -A 15 "  serviceMonitor:" | grep "keyFile:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|keyFile: .*|keyFile: /etc/prometheus/secrets/etcd-client-cert/etcd-client-key|" ${BASEDIR}/installed-values.yaml

sed -i "s/  additionalScrapeConfigs: .*/  additionalScrapeConfigs:/g" ${BASEDIR}/installed-values.yaml
grep -A 27 -n "  additionalScrapeConfigs:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{},27s/# /  /g" ${BASEDIR}/installed-values.yaml
grep -A 27 -n "  additionalScrapeConfigs:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{},27s/targetLabel/target_label/g" ${BASEDIR}/installed-values.yaml

# create tls prometheus
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}
# create tls grafana
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create tls secret
# prometheus
kubectl -n monitoring create secret tls prometheus-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key
# grafana
kubectl -n monitoring create secret tls grafana-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# prometheus ingress enable
grep -B 27 -A 7 -n "TLS configuration for Prometheus Ingress" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# prometheus ingress hosts
grep -B 27 -A 7 -n "TLS configuration for Prometheus Ingress" ${BASEDIR}/installed-values.yaml | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts: .*/\1hosts:\n\1  - prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# prometheus ingress tls
grep -B 27 -A 7 -n "TLS configuration for Prometheus Ingress" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: prometheus-tls\n\1    hosts:\n\1      - prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# grafana ingress enable
grep -B 1 -A 35 -n "Grafana Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# prometheus ingress hosts
grep -B 1 -A 35 -n "Grafana Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts: .*/\1hosts:\n\1  - grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# prometheus ingress tls
grep -B 1 -A 35 -n "Grafana Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: grafana-tls\n\1    hosts:\n\1      - grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm install prometheus playcekube/kube-prometheus-stack -n monitoring -f ${BASEDIR}/installed-values.yaml

