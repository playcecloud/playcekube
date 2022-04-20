#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall kubernetes-dashboard -n kubernetes-dashboard 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns kubernetes-dashboard 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|repository: quay\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: k8s\.gcr\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: docker\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# create tls kubernetes-dashboard
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns kubernetes-dashboard

# create tls secret
kubectl -n kubernetes-dashboard create secret tls dashboard-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# kubernetes-dashboard ingress enable
grep -A 5 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# kubernetes-dashboard ingress hosts
grep -n "^ingress:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\  hosts:\n    - dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml
# kubernetes-dashboard ingress tls
grep -n "^ingress:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\  tls:\n    - secretName: dashboard-tls\n      hosts:\n        - dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml

## ingress auth config add
# create serice account (dashboard-admin)
kubectl create serviceaccount dashboard-admin -n default
# create cluster role binding (cluster admin)
kubectl create clusterrolebinding --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin dashboard-admin
# get token
SECRET_NAME=$(kubectl get serviceaccounts dashboard-admin -n default -o jsonpath='{.secrets[0].name}')
SECRET_TOKEN=$(kubectl get secrets ${SECRET_NAME} -n default -o jsonpath='{.data.token}' | base64 --decode)
cat << EOF > ingress-temp.annotations
    nginx.ingress.kubernetes.io/auth-signin: https://oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/oauth2/start?rd=\$scheme://\$host\$request_uri
    nginx.ingress.kubernetes.io/auth-url: https://oauth2-proxy.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/oauth2/auth
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Authorization "Bearer ${SECRET_TOKEN}";
    nginx.ingress.kubernetes.io/proxy-buffer-size: 64k
    nginx.ingress.kubernetes.io/upstream-vhost: \$service_name.\$namespace:443
EOF
ANNOTATIONS=$(cat ingress-temp.annotations | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
grep -n "^ingress:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\  annotations:\n${ANNOTATIONS}" ${BASEDIR}/installed-values.yaml
rm -rf ingress-temp.annotations

# install
helm install kubernetes-dashboard playcekube/kubernetes-dashboard -n kubernetes-dashboard -f ${BASEDIR}/installed-values.yaml

