#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall ingress-nginx -n ingress-nginx 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns ingress-nginx 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|registry: .*|registry: registry.${PLAYCE_DOMAIN}:5000|g" ${BASEDIR}/installed-values.yaml
sed -i "s|digest: .*|digest: \"\"|g" ${BASEDIR}/installed-values.yaml

# extra arguments
grep -A 8 -n "arguments to pass to nginx-ingress-controller" ${BASEDIR}/installed-values.yaml | grep "extraArgs:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/extraArgs: .*/extraArgs: { enable-ssl-passthrough: true }/" ${BASEDIR}/installed-values.yaml

# nodeSelector
grep -A 2 -n "nodeSelector:" ${BASEDIR}/installed-values.yaml | grep "kubernetes.io/os:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|kubernetes.io/os: .*|node-role.kubernetes.io/ingress: \"\"|g" ${BASEDIR}/installed-values.yaml
sed -i "s|tolerations: \[\]|tolerations: \[operator: \"Exists\"\]|g" ${BASEDIR}/installed-values.yaml

# default ingress controller
grep -A 8 -n "ingressClassResource:" ${BASEDIR}/installed-values.yaml | grep "default:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/default: .*/default: true/" ${BASEDIR}/installed-values.yaml
sed -i "s|watchIngressWithoutClass: .*|watchIngressWithoutClass: true|g" ${BASEDIR}/installed-values.yaml

# no use service 
grep -A 5 -n "service:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: false/" ${BASEDIR}/installed-values.yaml

# daemonset
sed -i "s|kind: .*|kind: DaemonSet|g" ${BASEDIR}/installed-values.yaml

# hostPort
grep -A 5 -n "hostPort:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns ingress-nginx

# install
helm install ingress-nginx playcekube/ingress-nginx -n ingress-nginx -f ${BASEDIR}/installed-values.yaml

# ready check
POD_NAME=$(kubectl -n ingress-nginx get pod -o name -l app.kubernetes.io/name=ingress-nginx | head -n 1)
kubectl wait --for=condition=Ready ${POD_NAME} -n ingress-nginx

