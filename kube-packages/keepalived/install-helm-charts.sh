#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall kubeapi-keepalived -n kube-system
rm -rf ${BASEDIR}/installed-values.yaml

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# installed-values.yaml private registry setting
## keepalived
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|" ${BASEDIR}/installed-values.yaml

# node selector
sed -i "/^nodeSelector/d" ${BASEDIR}/installed-values.yaml
cat << EOF >> ${BASEDIR}/installed-values.yaml

nodeSelector:
  node-role.kubernetes.io/master: ""
EOF

# install
helm install kubeapi-keepalived playcekube/keepalived -n kube-system -f ${BASEDIR}/installed-values.yaml \
 --set keepalived.vrouter_interface="enp1s0" \
 --set keepalived.virtual_ip="172.30.1.51"

