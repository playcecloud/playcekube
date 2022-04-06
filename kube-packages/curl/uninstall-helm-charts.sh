#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall curl -n default
rm -rf ${BASEDIR}/installed-values.yaml

