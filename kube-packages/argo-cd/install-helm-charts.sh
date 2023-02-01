#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube-dev
CHART_NAME=argo-cd
CHART_VERSION=4.9.11

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
grep -n "repository:" ${BASEDIR}/installed-values.yaml | grep -Ev "ghcr.io|docker.io|k8s.gcr.io|quay.io|gcr.io" | grep -v "/" | grep -v '""' | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i  "{}s/repository: \(.*\)/repository: docker.io\/library\/\1/g" ${BASEDIR}/installed-values.yaml
grep -n "repository:" ${BASEDIR}/installed-values.yaml | grep -Ev "ghcr.io|docker.io|k8s.gcr.io|quay.io|gcr.io" | grep "/" | grep -v '""' | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i  "{}s/repository: \(.*\)/repository: docker.io\/\1/g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \"\?[^/\"]*/\([^\"]*\)\"\?|repository: registry.local.cloud:5000/\1|g" ${BASEDIR}/installed-values.yaml

# insecure options
grep -A 5 -n "Additional command line arguments to pass to Argo CD server" ${BASEDIR}/installed-values.yaml | grep "extraArgs" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/extraArgs:.*/extraArgs:\n    - --insecure/g" ${BASEDIR}/installed-values.yaml

# auth keycloak
grep -A 3 -n "externally facing base URL" ${BASEDIR}/installed-values.yaml | grep "url:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/url: .*/url: https\:\/\/argo.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 3 -n "rbacConfig:" ${BASEDIR}/installed-values.yaml | grep "{}" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}d" ${BASEDIR}/installed-values.yaml
sed -i "s/rbacConfig:/rbacConfig:\n    policy.csv: |\n      g, admin, role:admin/" ${BASEDIR}/installed-values.yaml

# get keycloak kubernetes secret & create secret
REALM_KUBERNETES_SECRET=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get secrets keycloak-client-secret -o jsonpath={.data.kubernetes} | base64 --decode)
if [[ "${REALM_KUBERNETES_SECRET}" != "" ]]; then
cat << EOF > yamltemp.txt
    oidc.config: |
      name: KeyCloak
      issuer: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}
      clientID: kubernetes
      clientSecret: ${REALM_KUBERNETES_SECRET}
      requestedScopes: ["openid"]
      logoutURL: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/protocol/openid-connect/logout?redirect_uri=https%3A%2F%2Fargo.${USING_CLUSTER}.${PLAYCE_DOMAIN}
EOF
YAML_TEMP=$(cat yamltemp.txt | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g' | sed "s/\&/\\\&/g")
rm -rf yamltemp.txt
sed -i "/oidc.config:/i\ \n${YAML_TEMP}" ${BASEDIR}/installed-values.yaml
fi

# password
#htpasswd -nbBC 10 "" $ARGO_PWD | tr -d ':\n' | sed 's/$2y/$2a/'
#$2a$10$SerAuRrwcXSaFsQtdtk9rOSwN/8Z.E12UBAuIXaCXza5C2JdNl9Y6
sed -i "s/argocdServerAdminPassword: .*/argocdServerAdminPassword: \$2a\$10\$SerAuRrwcXSaFsQtdtk9rOSwN\/8Z.E12UBAuIXaCXza5C2JdNl9Y6/" ${BASEDIR}/installed-values.yaml

# playcekube ca mount
sed -i "s|volumeMounts: \[\]|volumeMounts:\n    - name: root-ca\n      mountPath: /etc/ssl/certs|g" ${BASEDIR}/installed-values.yaml
sed -i "s|volumes: \[\]|volumes:\n    - name: root-ca\n      secret:\n        secretName: os-root-ca|g" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} -n ${CHART_NAMESPACE} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} \
 -f ${BASEDIR}/installed-values.yaml \
 --set server.ingress.enabled=true \
 --set server.ingress.hosts[0]=argo.${USING_CLUSTER}.${PLAYCE_DOMAIN} \
 --set server.ingress.tls[0].hosts[0]=argo.${USING_CLUSTER}.${PLAYCE_DOMAIN} \
 --set server.ingress.tls[0].secretName=wild-tls

rm -rf /usr/local/bin/argocd
cp -rp ${PLAYCE_DATADIR}/repositories/kubernetes/argocd/argocd /usr/local/bin/argocd
chmod 755 /usr/local/bin/argocd

