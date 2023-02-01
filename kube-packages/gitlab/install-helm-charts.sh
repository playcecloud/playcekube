#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube-dev
CHART_NAME=gitlab
CHART_VERSION=6.1.1

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
sed -i "s|repository: registry.gitlab.com|repository: registry.local.cloud:5000|g" ${BASEDIR}/installed-values.yaml
cat << EOF >> ${BASEDIR}/installed-values.yaml

  global:
    communityImages:
      # Default repositories used to pull Gitlab Community Edition images.
      # See the image.repository and workhorse.repository template helpers.
      migrations:
        repository: registry.local.cloud:5000/gitlab-org/build/cng/gitlab-toolbox-ce
      sidekiq:
        repository: registry.local.cloud:5000/gitlab-org/build/cng/gitlab-sidekiq-ce
      toolbox:
        repository: registry.local.cloud:5000/gitlab-org/build/cng/gitlab-toolbox-ce
      webservice:
        repository: registry.local.cloud:5000/gitlab-org/build/cng/gitlab-webservice-ce
      workhorse:
        repository: registry.local.cloud:5000/gitlab-org/build/cng/gitlab-workhorse-ce

  gitlab-exporter:
    image:
      repository: registry.local.cloud:5000/gitlab-org/build/cng/gitlab-exporter

  gitlab-shell:
    image:
      repository: registry.local.cloud:5000/gitlab-org/build/cng/gitlab-shell

  gitaly:
    image:
      repository: registry.local.cloud:5000/gitlab-org/build/cng/gitaly

  praefect:
    image:
      repository: registry.local.cloud:5000/gitlab-org/build/cng/gitaly

registry:
  image:
    repository: registry.local.cloud:5000/gitlab-org/build/cng/gitlab-container-registry

redis:
  image:
    registry: registry.local.cloud:5000

  metrics:
    image:
      registry: registry.local.cloud:5000

postgresql:
  image:
    registry: registry.local.cloud:5000

  metrics:
    image:
      registry: registry.local.cloud:5000

minio:
  image: registry.local.cloud:5000/minio/minio
  
  minioMc:
     image: registry.local.cloud:5000/minio/mc

EOF
sed -i "/^gitlab-runner:/a\  image: registry.local.cloud:5000/gitlab/gitlab-runner:alpine-v14.8.0" ${BASEDIR}/installed-values.yaml
sed -i "/^gitlab-runner:/a\  gitlabUrl: http://gitlab-webservice-default:8080" ${BASEDIR}/installed-values.yaml

# subchart disable
grep -A 3 -n "^nginx-ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: false/g" ${BASEDIR}/installed-values.yaml
grep -A 3 -n "^prometheus:" ${BASEDIR}/installed-values.yaml | grep "install:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/install: .*/install: false/g" ${BASEDIR}/installed-values.yaml
grep -A 6 -n "^certmanager:" ${BASEDIR}/installed-values.yaml | grep "install:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/install: .*/install: false/g" ${BASEDIR}/installed-values.yaml

# default config
sed -i "s/initialRootPassword: .*/initialRootPassword: {key: vmffpdltm}/g" ${BASEDIR}/installed-values.yaml
sed -i "s/  edition: .*/  edition: ce/g" ${BASEDIR}/installed-values.yaml
grep -A 10 -n "  ingress:" ${BASEDIR}/installed-values.yaml | grep "configureCertmanager:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/configureCertmanager: .*/configureCertmanager: false/g" ${BASEDIR}/installed-values.yaml

# ingress class
grep -A 8 -n "^  ingress:" ${BASEDIR}/installed-values.yaml | grep "class:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/.*class:.*/    class: nginx/" ${BASEDIR}/installed-values.yaml

# ingress hosts setting
grep -A 3 -n "^  hosts:" ${BASEDIR}/installed-values.yaml | grep "domain:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/domain: .*/domain: gitlab.${USING_CLUSTER}.${PLAYCE_DOMAIN}/g" ${BASEDIR}/installed-values.yaml
grep -A 12 -n "^  hosts:" ${BASEDIR}/installed-values.yaml | grep "gitlab:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/gitlab: .*/gitlab: {name: gitlab.${USING_CLUSTER}.${PLAYCE_DOMAIN}}/g" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^  ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls:/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^  ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\      enabled: true\n      secretName: wild-tls\n" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml


