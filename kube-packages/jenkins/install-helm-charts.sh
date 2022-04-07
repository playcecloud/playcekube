#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall jenkins -n jenkins 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns jenkins 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
grep -n "image:" ${BASEDIR}/installed-values.yaml | grep -Ev "ghcr.io|docker.io|k8s.gcr.io|quay.io|gcr.io" | grep -v "/" | grep -v '""' | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i  "{}s/image: \"\?\([^\"]*\)\"\?/image: docker.io\/library\/\1/g" ${BASEDIR}/installed-values.yaml
grep -n "image:" ${BASEDIR}/installed-values.yaml | grep -Ev "ghcr.io|docker.io|k8s.gcr.io|quay.io|gcr.io" | grep "/" | grep -v '""' | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i  "{}s/image: \"\?\([^\"]*\)\"\?/image: docker.io\/\1/g" ${BASEDIR}/installed-values.yaml
sed -i "s|image: [^/]*/\(.*\)|image: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# installed-values.yaml persistence volume false settting
grep -A 3 -n "^persistence:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}s/enabled:.*/enabled: false/g" ${BASEDIR}/installed-values.yaml

# root-ca volume mount
grep -A 33 -n "^persistence:" ${BASEDIR}/installed-values.yaml | grep "volumes:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}s|\(.*\)volumes:.*|\1volumes:\n\1  - name: root-ca\n\1    secret:\n\1      secretName: os-root-ca\n\1  - name: java-keystore\n\1    secret:\n\1      secretName: os-java-keystore|g" ${BASEDIR}/installed-values.yaml
grep -A 33 -n "^persistence:" ${BASEDIR}/installed-values.yaml | grep "mounts:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}s|\(.*\)mounts:.*|\1mounts:\n\1  - name: root-ca\n\1    mountPath: /etc/ssl/certs/ca-certificates.crt\n\1    subPath: ca-certificates.crt\n\1  - name: java-keystore\n\1    mountPath: /opt/java/openjdk/lib/security/cacerts\n\1    subPath: cacerts|g" ${BASEDIR}/installed-values.yaml

# adminPassword
sed -i "s/.*adminPassword:.*/  adminPassword: oscadmin/g" ${BASEDIR}/installed-values.yaml

# set offline plugin
#sed -i "s/installLatestPlugins: true/installLatestPlugins: false/g" ${BASEDIR}/installed-values.yaml
#sed -i "s/installLatestSpecifiedPlugins: .*/installLatestSpecifiedPlugins: true/g" ${BASEDIR}/installed-values.yaml
sed -i "s/.*javaOpts: .*/  javaOpts: \"-Dhudson.model.DownloadService.noSignatureCheck=true\"/g" ${BASEDIR}/installed-values.yaml

## plugin update site setting
cat << EOF > tempyaml.yaml
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: " Private Network 환경을 고려한 Jenkins 설정으로 업데이트는 자체 update-center 를 업데이트 해야 가능합니다 "

      default-updatecenter: |
        jenkins:
          updateCenter:
            sites:
            - id: "default"
              url: "https://repositories.${PLAYCE_DOMAIN}/jenkins/update-center.json"
EOF
sed -i "s|.*configScripts:.*|$(cat tempyaml.yaml | sed 's/"/\\"/g' | sed 's/|/\\|/g' | sed -z 's/\n/\\n/g')|g" ${BASEDIR}/installed-values.yaml
rm -rf tempyaml.yaml

sed -i "/initContainerEnv:/i\  initContainerEnv:\n    - name: JENKINS_PLUGIN_INFO\n      value: \"https://repositories.${PLAYCE_DOMAIN}/jenkins/plugin-versions.json\"\n    - name: JENKINS_UC\n      value: \"https://repositories.${PLAYCE_DOMAIN}/jenkins/update-center.json\"\n    - name: JENKINS_UC_DOWNLOAD\n      value: \"https://repositories.${PLAYCE_DOMAIN}/jenkins/download\"\n    - name: JENKINS_UC_EXPERIMENTAL\n      value: \"https://repositories.${PLAYCE_DOMAIN}/jenkins/update-center.json\"" ${BASEDIR}/installed-values.yaml
sed -i "/containerEnv:/i\  containerEnv:\n    - name: JENKINS_PLUGIN_INFO\n      value: \"https://repositories.${PLAYCE_DOMAIN}/jenkins/plugin-versions.json\"\n    - name: JENKINS_UC\n      value: \"https://repositories.${PLAYCE_DOMAIN}/jenkins/update-center.json\"\n    - name: JENKINS_UC_DOWNLOAD\n      value: \"https://repositories.${PLAYCE_DOMAIN}/jenkins/download\"\n    - name: JENKINS_UC_EXPERIMENTAL\n      value: \"https://repositories.${PLAYCE_DOMAIN}/jenkins/update-center.json\"" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns jenkins

# create root ca
kubectl create secret generic os-root-ca --from-file=ca-bundle.crt=/etc/ssl/certs/ca-bundle.crt --from-file=ca-certificates.crt=/etc/ssl/certs/ca-bundle.crt -n jenkins
kubectl create secret generic os-java-keystore --from-file=cacerts=/etc/pki/java/cacerts -n jenkins

# create tls jenkins
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh jenkins.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:jenkins.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}
kubectl -n jenkins create secret tls jenkins-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/jenkins.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/jenkins.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# ingress enable
grep -A 30 -n " ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# prometheus ingress hosts
grep -A 30 -n " ingress:" ${BASEDIR}/installed-values.yaml | grep "hostName:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hostName:.*/\1hostName: jenkins.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# prometheus ingress tls
grep -A 30 -n " ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls:.*/\1tls:\n\1  - secretName: jenkins-tls\n\1    hosts:\n\1      - jenkins.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm upgrade -i jenkins playcekube/jenkins -n jenkins -f ${BASEDIR}/installed-values.yaml

