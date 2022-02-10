#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall curl -n default
rm -rf ${BASEDIR}/installed-values.yaml

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# installed-values.yaml private registry setting
## curl
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|" ${BASEDIR}/installed-values.yaml

# install
helm install curl playcekube/curl -n default -f ${BASEDIR}/installed-values.yaml

