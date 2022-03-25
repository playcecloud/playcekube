#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall gitlab -n gitlab
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns gitlab

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# change clusterDomain
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|repository: registry.gitlab.com|repository: registry.${PLAYCE_DOMAIN}:5000|g" ${BASEDIR}/installed-values.yaml
cat << EOF >> ${BASEDIR}/installed-values.yaml

  global:
    communityImages:
      # Default repositories used to pull Gitlab Community Edition images.
      # See the image.repository and workhorse.repository template helpers.
      migrations:
        repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitlab-toolbox-ce
      sidekiq:
        repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitlab-sidekiq-ce
      toolbox:
        repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitlab-toolbox-ce
      webservice:
        repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitlab-webservice-ce
      workhorse:
        repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitlab-workhorse-ce

  gitlab-exporter:
    image:
      repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitlab-exporter

  gitlab-shell:
    image:
      repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitlab-shell

  gitaly:
    image:
      repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitaly

  praefect:
    image:
      repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitaly

registry:
  image:
    repository: registry.${PLAYCE_DOMAIN}:5000/gitlab-org/build/cng/gitlab-container-registry

redis:
  image:
    registry: registry.${PLAYCE_DOMAIN}:5000

  metrics:
    image:
      registry: registry.${PLAYCE_DOMAIN}:5000
  
postgresql:
  image:
    registry: registry.${PLAYCE_DOMAIN}:5000

  metrics:
    image:
      registry: registry.${PLAYCE_DOMAIN}:5000

minio:
  image: registry.${PLAYCE_DOMAIN}:5000/minio/minio
  
  minioMc:
     image: registry.${PLAYCE_DOMAIN}:5000/minio/mc

EOF
sed -i "/^gitlab-runner:/a\  image: registry.${PLAYCE_DOMAIN}:5000/gitlab/gitlab-runner:alpine-v14.8.0" ${BASEDIR}/installed-values.yaml
sed -i "/^gitlab-runner:/a\  gitlabUrl: http://gitlab-webservice-default:8080" ${BASEDIR}/installed-values.yaml

# subchart disable
grep -A 3 -n "^nginx-ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: false/g" ${BASEDIR}/installed-values.yaml
grep -A 3 -n "^prometheus:" ${BASEDIR}/installed-values.yaml | grep "install:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/install: .*/install: false/g" ${BASEDIR}/installed-values.yaml
grep -A 6 -n "^certmanager:" ${BASEDIR}/installed-values.yaml | grep "install:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/install: .*/install: false/g" ${BASEDIR}/installed-values.yaml

# default config
sed -i "s/  edition: .*/  edition: ce/g" ${BASEDIR}/installed-values.yaml
grep -A 10 -n "  ingress:" ${BASEDIR}/installed-values.yaml | grep "configureCertmanager:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/configureCertmanager: .*/configureCertmanager: false/g" ${BASEDIR}/installed-values.yaml

# installed-values.yaml persistence volume false settting
grep -A 3 -n "persistence:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}d" ${BASEDIR}/installed-values.yaml
sed -i "s/\(.*\)persistence:.*/\1persistence:\n\1  enabled: false/g" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns gitlab

# create root ca
kubectl create secret generic os-root-ca --from-file=ca-bundle.crt=/etc/ssl/certs/ca-bundle.crt --from-file=ca-certificates.crt=/etc/ssl/certs/ca-bundle.crt -n gitlab

# create tls gitlab
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh gitlab.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:gitlab.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create tls secret
kubectl -n gitlab create secret tls gitlab-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/gitlab.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/gitlab.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# ingress class
grep -A 8 -n "^  ingress:" ${BASEDIR}/installed-values.yaml | grep "class:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/.*class:.*/    class: nginx/" ${BASEDIR}/installed-values.yaml

# ingress hosts setting
grep -A 3 -n "^  hosts:" ${BASEDIR}/installed-values.yaml | grep "domain:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/domain: .*/domain: gitlab.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/g" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^  ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls:/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^  ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\      enabled: true\n      secretName: gitlab-tls\n" ${BASEDIR}/installed-values.yaml

# install
helm install gitlab playcekube/gitlab -n gitlab -f ${BASEDIR}/installed-values.yaml

