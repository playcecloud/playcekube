#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall linkerd-multicluster -n linkerd-multicluster 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns linkerd-multicluster 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
## linkerd-multicluster
sed -i "s|registry: gcr.io|registry: registry.${PLAYCE_DOMAIN}:5000|g" ${BASEDIR}/installed-values.yaml

# namespace setting
## linkerd2
sed -i "s/^namespace: .*/namespace: linkerd-multicluster/" ${BASEDIR}/installed-values.yaml
sed -i "s/^linkerdNamespace: .*/linkerdNamespace: linkerd/" ${BASEDIR}/installed-values.yaml
sed -i "s/^installNamespace: .*/installNamespace: false/" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns linkerd-multicluster

# install
helm install linkerd-multicluster playcekube/linkerd-multicluster -n linkerd-multicluster -f ${BASEDIR}/installed-values.yaml

