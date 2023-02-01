#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=linkerd-viz
CHART_VERSION=2.11.1

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
## linkerd-viz
sed -i "s|registry: \"\"|registry: registry.local.cloud:5000/linkerd|g" ${BASEDIR}/installed-values.yaml
sed -i "s|registry: prom|registry: registry.local.cloud:5000/prom|g" ${BASEDIR}/installed-values.yaml

# namespace setting
## linkerd2
sed -i "s/^namespace: .*/namespace: ${CHART_NAMESPACE}/" ${BASEDIR}/installed-values.yaml
sed -i "s/^linkerdNamespace: .*/linkerdNamespace: ${CHART_NAMESPACE}/" ${BASEDIR}/installed-values.yaml
sed -i "s/^installNamespace: .*/installNamespace: false/" ${BASEDIR}/installed-values.yaml
# enforce host
#sed -i "s/enforcedHostRegexp: .*/enforcedHostRegexp: linkerd.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

# ingress
kubectl --context=${USING_CONTEXT} apply -f - << EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/upstream-vhost: \$service_name.\$namespace.svc:8084
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Origin "";
      proxy_hide_header l5d-remote-ip;
      proxy_hide_header l5d-server-id;
    nginx.ingress.kubernetes.io/auth-signin: https://oauth2-proxy.${USING_CLUSTER}.${PLAYCE_DOMAIN}/oauth2/start?rd=\$scheme://\$host\$request_uri
    nginx.ingress.kubernetes.io/auth-url: https://oauth2-proxy.${USING_CLUSTER}.${PLAYCE_DOMAIN}/oauth2/auth?allowed_groups=admin
  name: linkerd-dashboard
  namespace: ${CHART_NAMESPACE}
spec:
  ingressClassName: nginx
  rules:
  - host: linkerd.${USING_CLUSTER}.${PLAYCE_DOMAIN}
    http:
      paths:
      - backend:
          service:
            name: web
            port:
              number: 8084
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - linkerd.${USING_CLUSTER}.${PLAYCE_DOMAIN}
    secretName: wild-tls
EOF

