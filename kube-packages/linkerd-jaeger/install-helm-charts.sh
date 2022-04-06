#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall linkerd-jaeger -n linkerd-jaeger
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns linkerd-jaeger

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
## linkerd-jaeger
sed -i "s|name: otel|name: registry.${PLAYCE_DOMAIN}:5000/otel|g" ${BASEDIR}/installed-values.yaml
sed -i "s|name: omnition|name: registry.${PLAYCE_DOMAIN}:5000/omnition|g" ${BASEDIR}/installed-values.yaml
sed -i "s|name: jaegertracing|name: registry.${PLAYCE_DOMAIN}:5000/jaegertracing|g" ${BASEDIR}/installed-values.yaml
sed -i "s|name: cr.l5d.io|name: registry.${PLAYCE_DOMAIN}:5000|g" ${BASEDIR}/installed-values.yaml
sed -i "s|name: cr.l5d.io|name: registry.${PLAYCE_DOMAIN}:5000|g" ${BASEDIR}/installed-values.yaml

# namespace setting
## linkerd-jaeger
sed -i "s/^namespace: .*/namespace: linkerd-jaeger/" ${BASEDIR}/installed-values.yaml
sed -i "s/^linkerdNamespace: .*/linkerdNamespace: linkerd/" ${BASEDIR}/installed-values.yaml
sed -i "s/^installNamespace: .*/installNamespace: false/" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns linkerd-jaeger

# install
helm install linkerd-jaeger playcekube/linkerd-jaeger -n linkerd-jaeger -f ${BASEDIR}/installed-values.yaml

