#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall prometheus -n monitoring
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns monitoring

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|repository: quay\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: k8s\.gcr\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# installed-values.yaml persistence volume false settting
grep -A 6 -n "persistentVolume:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}s/enabled:.*/enabled: false/g" ${BASEDIR}/installed-values.yaml

# create tls prometheus
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}
# create tls grafana
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns monitoring

# create tls secret
# prometheus
kubectl -n monitoring create secret tls prometheus-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key
# grafana
kubectl -n monitoring create secret tls grafana-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# prometheus ingress enable
grep -B 1 -A 45 -n "Prometheus server Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# prometheus ingress hosts
grep -B 1 -A 45 -n "Prometheus server Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts: .*/\1hosts:\n\1  - prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# prometheus ingress tls
grep -B 1 -A 45 -n "Prometheus server Ingress will be created" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: prometheus-tls\n\1    hosts:\n\1      - prometheus.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# grafana ingress
sed -i "/^grafana:/a\  ingress:\n    enabled: true\n    hosts:\n      - grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}\n    tls:\n      - secretName: grafana-tls\n        hosts:\n          - grafana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml

# install
helm install prometheus playcekube/prometheus -n monitoring -f ${BASEDIR}/installed-values.yaml --set nodeExporter.tolerations[0].operator=Exists

