#!/bin/bash

## playcekube env
PLAYCE_DIR=${PLAYCE_DIR:=/playcecloud}
PLAYCE_DOMAIN=${PLAYCE_DOMAIN:=playce.cloud}
DEPLOY_SERVER=${DEPLOY_SERVER:=127.0.0.1}
CURRENT_DIR=${CURRENT_DIR:=/playcecloud}
#KUBESPRAY_ENV=

## require env
#MODE [DEPLOY, UPGRADE, RESET, SCALE, REMOVE-NODE, JUST-INVENTORY]
MODE=${MODE:=DEPLOY}
# network mode [public private]
NETWORK_MODE=${NETWORK_MODE:=public}
CREATE_INVENTORY=${CREATE_INVENTORY:=true}
FORCE_CREATE_INVENTORY=${FORCE_CREATE_INVENTORY:=false}
# kubernetes version
#KUBERNETES_VERSION=v1.22.5
# cluster name, inventory name
#CLUSTER_NAME=
ANSIBLE_USER=${ANSIBLE_USER:=root}
#ANSIBLE_PASSWD=
BECOME_USER=${BECOME_USER:=root}
#BECOME_PASSWD=
# node password deprecated
#NODE_PASSWD=
if [[ "${NODE_PASSWD}" != "" ]] && [[ "${ANSIBLE_PASSWD}" == "" ]]; then
  ANSBILE_PASSWD=${NODE_PASSWD}
fi

## create inventory env
CLUSTER_RUNTIME=${CLUSTER_RUNTIME:=containerd}
SERVICE_NETWORK=${SERVICE_NETWORK:=10.233.0.0/18}
POD_NETWORK=${POD_NETWORK:=10.233.64.0/18}
PRIVATE_DNS=${PRIVATE_DNS:=${DEPLOY_SERVER}}
PRIVATE_REPO=${PRIVATE_REPO:=${DEPLOY_SERVER}}
PRIVATE_REGISTRY=${PRIVATE_REGISTRY:=${DEPLOY_SERVER}:5000}
PRIVATE_NTP=${PRIVATE_NTP:=${DEPLOY_SERVER}}
#PROXY_SERVER=127.0.0.1:3128
#MASTERS=
#WORKERS=
#INGRESSES=
#LOGGING=
#INFRA=
#CICD=
LIMIT_NODES=${LIMIT_NODES:=all}
#NEW_WORKERS=
#REMOVE_NODES=

if [[ "${CLUSTER_NAME}" == "" ]]; then
 echo "[ERROR] ENV CLUSTER_NAME require"
 exit 1;
fi

KUBESPRAY_DIR=/kubespray
K8S_INVENTORY_DIR=${KUBESPRAY_DIR}/inventory/${CLUSTER_NAME}
K8S_INVENTORY_HOSTS=${K8S_INVENTORY_DIR}/inventory.ini
export ANSIBLE_LOG_PATH=${K8S_INVENTORY_DIR}/playce-kubespray.log

if [[ "${CREATE_INVENTORY}" == "true" ]]; then
  if [[ "${MASTERS}" == "" ]] || [[ "${WORKERS}" == "" ]]; then
    echo "[ERROR] ENV require MASTERS and WORKERS"
    exit 1;
  fi
  if [[ -d ${K8S_INVENTORY_DIR} ]] && [[ "${FORCE_CREATE_INVENTORY}" == "true" ]]; then
    mv ${K8S_INVENTORY_DIR} ${K8S_INVENTORY_DIR}.$(date +%Y%m%d%H%M)
  fi
else
  if [[ ! -d ${K8S_INVENTORY_DIR} ]]; then
    echo "[ERROR] inventory directory not exist";
    exit 1;
  fi
fi

# set kubespray dns setting
echo "nameserver ${PRIVATE_DNS}" > /etc/resolv.conf

# create inventory
if [[ "${CREATE_INVENTORY}" == "true" ]]; then
  cp -rp ${KUBESPRAY_DIR}/inventory.template ${K8S_INVENTORY_DIR}

  K8S_TEMPDIR=$(mktemp -d)

  for HOSTINFO in ${MASTERS//,/ }
  do
    HOSTINFOARRAY=(${HOSTINFO//:/ })
    echo "${HOSTINFOARRAY[0]} ansible_host=${HOSTINFOARRAY[1]} ip=${HOSTINFOARRAY[1]} access_ip=${HOSTINFOARRAY[1]}" >> ${K8S_TEMPDIR}/hosts_masters
  done

  for HOSTINFO in ${WORKERS//,/ }
  do
    HOSTINFOARRAY=(${HOSTINFO//:/ })
    echo "${HOSTINFOARRAY[0]} ansible_host=${HOSTINFOARRAY[1]} ip=${HOSTINFOARRAY[1]} access_ip=${HOSTINFOARRAY[1]}" >> ${K8S_TEMPDIR}/hosts_workers
  done

  declare -A NODELABELS

  for HOSTINFO in ${INGRESSES//,/ }
  do
    NODELABELS[${HOSTINFO}]="${NODELABELS[${HOSTINFO}]},\"node-role.kubernetes.io\/ingress\": \"\""
  done

  for HOSTINFO in ${EGRESSES//,/ }
  do
    NODELABELS[${HOSTINFO}]="${NODELABELS[${HOSTINFO}]},\"node-role.kubernetes.io\/egress\": \"\""
  done

  for HOSTINFO in ${LOGGING//,/ }
  do
    NODELABELS[${HOSTINFO}]="${NODELABELS[${HOSTINFO}]},\"node-role.kubernetes.io\/logging\": \"\""
  done

  for HOSTINFO in ${INFRA//,/ }
  do
    NODELABELS[${HOSTINFO}]="${NODELABELS[${HOSTINFO}]},\"node-role.kubernetes.io\/infra\": \"\""
  done

  for HOSTINFO in ${CICD//,/ }
  do
    NODELABELS[${HOSTINFO}]="${NODELABELS[${HOSTINFO}]},\"node-role.kubernetes.io\/cicd\": \"\""
  done

  for HOSTINFO in ${!NODELABELS[@]}
  do
    NODELABELS[${HOSTINFO}]="node_labels='{${NODELABELS[${HOSTINFO}]:1}}'"
  done

  for HOSTINFO in ${!NODELABELS[@]}
  do
    sed -i "s/${HOSTINFO}/${HOSTINFO} ${NODELABELS[${HOSTINFO}]}/g" ${K8S_TEMPDIR}/hosts_masters
    sed -i "s/${HOSTINFO}/${HOSTINFO} ${NODELABELS[${HOSTINFO}]}/g" ${K8S_TEMPDIR}/hosts_workers
  done

  # make inventory
  echo "[all]" > ${K8S_INVENTORY_HOSTS}
  cat ${K8S_TEMPDIR}/hosts_* | sort | uniq >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  # ansible user
  echo "[all:vars]" >> ${K8S_INVENTORY_HOSTS}
  echo "ansible_ssh_user=${ANSIBLE_USER}" >> ${K8S_INVENTORY_HOSTS}
  # set become
  echo "ansible_become=yes" >> ${K8S_INVENTORY_HOSTS}
  echo "ansible_become_user=${BECOME_USER}" >> ${K8S_INVENTORY_HOSTS}
  if [ "${BECOME_PASSWD}" != "" ]; then
    echo "ansible_become_password=${BECOME_PASSWD}" >> ${K8S_INVENTORY_HOSTS}
  fi

  # v1.15.1
  echo "[kube-master:children]" >> ${K8S_INVENTORY_HOSTS}
  echo "kube_control_plane" >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  echo "[kube_control_plane]" >> ${K8S_INVENTORY_HOSTS}
  cat ${K8S_TEMPDIR}/hosts_masters | awk '{ print $1 }' >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}
   
  echo "[etcd]" >> ${K8S_INVENTORY_HOSTS}
  cat ${K8S_TEMPDIR}/hosts_masters | awk '{ print $1 }' >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  # v1.15.1
  echo "[kube-node:children]" >> ${K8S_INVENTORY_HOSTS}
  echo "kube_node" >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  echo "[kube_node]" >> ${K8S_INVENTORY_HOSTS}
  cat ${K8S_TEMPDIR}/hosts_workers | awk '{ print $1 }' >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  # v1.15.1
  echo "[calico-rr]" >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  echo "[calico_rr]" >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  # v1.15.1
  echo "[k8s-cluster:children]" >> ${K8S_INVENTORY_HOSTS}
  echo "k8s_cluster" >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  echo "[k8s_cluster:children]" >> ${K8S_INVENTORY_HOSTS}
  echo "kube_control_plane" >> ${K8S_INVENTORY_HOSTS}
  echo "kube_node" >> ${K8S_INVENTORY_HOSTS}
  echo "calico_rr" >> ${K8S_INVENTORY_HOSTS}
  echo "" >> ${K8S_INVENTORY_HOSTS}

  rm -rf ${K8S_TEMPER}
fi

# variable update env setting
K8S_CLUSTER_PATH=${K8S_INVENTORY_DIR}/group_vars/k8s-cluster/k8s-cluster.yml
if [ ! -f "${K8S_CLUSTER_PATH}" ]; then
  K8S_CLUSTER_PATH=${K8S_INVENTORY_DIR}/group_vars/k8s_cluster/k8s-cluster.yml
fi
MASTER_SAN_STR="master.${CLUSTER_NAME}.${PLAYCE_DOMAIN}"
if [ "${MASTER_VIP}" != "" ]; then
  MASTER_SAN_STR="${MASTER_SAN_STR},${MASTER_VIP}"
fi
if [ "${MASTER_SANS}" != "" ]; then
  MASTER_SAN_STR="${MASTER_SAN_STR},${MASTER_SANS}"
fi

# kubernetes version setting
# v2.15.1
if [[ "${KUBERNETES_VERSION}" != "" ]]; then
  sed -i "s|^kube_version: .*|kube_version: ${KUBERNETES_VERSION}|" ${K8S_CLUSTER_PATH}
fi

# variable update
if [[ "${CREATE_INVENTORY}" == "true" ]]; then
  if [[ "${NETWORK_MODE}" != "public" ]]; then
    ### offline.yml ###
    # base repo url & registry setting
    sed -i "s/\(# \)\?registry_host:.*/registry_host: \"${PRIVATE_REGISTRY}\"/" ${K8S_INVENTORY_DIR}/group_vars/all/offline.yml
    sed -i "s/\(# \)\?files_repo:.*/files_repo: \"http:\/\/${PRIVATE_REPO}\"/" ${K8S_INVENTORY_DIR}/group_vars/all/offline.yml
    sed -i "s/\(# \)\?yum_repo:.*/yum_repo: \"http:\/\/${PRIVATE_REPO}\/{{ ansible_distribution | lower }}{{ ansible_distribution_major_version }}\"/" ${K8S_INVENTORY_DIR}/group_vars/all/offline.yml
    sed -i "s/\(# \)\?ubuntu_repo:.*/ubuntu_repo: \"http:\/\/${PRIVATE_REPO}\"/" ${K8S_INVENTORY_DIR}/group_vars/all/offline.yml

    ### containerd.yml ###
    echo "containerd_registries:" >> ${K8S_INVENTORY_DIR}/group_vars/all/containerd.yml
    echo " \"${PRIVATE_REGISTRY}\": \"https://${PRIVATE_REGISTRY}\"" >> ${K8S_INVENTORY_DIR}/group_vars/all/containerd.yml
  else
    rm -rf ${K8S_INVENTORY_DIR}/group_vars/all/offline.yml
    cp -rp ${K8S_INVENTORY_DIR}/group_vars/all/online.yml ${K8S_INVENTORY_DIR}/group_vars/all/offline.yml
  fi

  ### K8S-cluster.yml ###
  # v2.15.1
  sed -i "s/container_manager: .*/container_manager: ${CLUSTER_RUNTIME}/" ${K8S_CLUSTER_PATH}
  sed -i "s/cluster_name: .*/cluster_name: ${CLUSTER_NAME}/" ${K8S_CLUSTER_PATH}
  sed -i "s/dns_domain: .*/dns_domain: cluster.local/" ${K8S_CLUSTER_PATH}
  sed -i "s|kube_service_addresses: .*|kube_service_addresses: ${SERVICE_NETWORK}|" ${K8S_CLUSTER_PATH}
  sed -i "s|kube_pods_subnet: .*|kube_pods_subnet: ${POD_NETWORK}|" ${K8S_CLUSTER_PATH}
  sed -i "s/\(# \)\?supplementary_addresses_in_ssl_keys: .*/supplementary_addresses_in_ssl_keys: [${MASTER_SAN_STR}]/" ${K8S_CLUSTER_PATH}

  ### oidc url ###
  sed -i "s|\(# \)\?kube_oidc_url: .*|kube_oidc_url: https://keycloak.${CLUSTER_NAME}.${PLAYCE_DOMAIN}/auth/realms/${CLUSTER_NAME}|" ${K8S_CLUSTER_PATH}

  ### proxy config ###
  if [[ "${PROXY_SERVER}" != "" ]]; then
    sed -i "s|^ssh_args.*|ssh_args = -o ControlMaster=auto -o ControlPersist=30m -o ConnectionAttempts=100 -o UserKnownHostsFile=/dev/null -o \"ProxyCommand=nc --proxy ${PROXY_SERVER} %h %p\"|g" ${KUBESPRAY_DIR}/ansible.cfg

    sed -i "s/\$(# \)\?http_proxy: .*/http_proxy: \"http:\/\/${PROXY_SERVER}\"/" ${K8S_INVENTORY_DIR}/group_vars/all/all.yml
    sed -i "s/\$(# \)\?https_proxy: .*/https_proxy: \"http:\/\/${PROXY_SERVER}\"/" ${K8S_INVENTORY_DIR}/group_vars/all/all.yml
    sed -i "s|\$(# \)\?no_proxy: .*|no_proxy: \"localhost,127.0.0.1,${SERVICE_NETWORK},${POD_NETWORK}\"|" ${K8S_INVENTORY_DIR}/group_vars/all/all.yml
  fi
fi

# set ssh keyfile
sed -i "/^private_key_file =.*/d" /kubespray/ansible.cfg
sed -i "/\[defaults\]/a\private_key_file = \/kubespray\/kubespray_ssh" ansible.cfg
# set warning false
sed -i "/^command_warnings = .*/d" /kubespray/ansible.cfg
sed -i "/\[defaults\]/a\command_warnings = False" ansible.cfg

# pre setup
if [[ "${MODE}" != "JUST-INVENTORY" ]] && [[ "${MODE}" != "RESET" ]]; then
  # keycopy
  if [ "${ANSIBLE_PASSWD}" != "" ]; then
    echo "[INFO] ### ssh key copy..."
    ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/extfiles/keycopy.yaml -e ansible_ssh_pass=${ANSIBLE_PASSWD}
  fi

  # pre setup
  echo "[INFO] ### pre setup..."
  ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/extfiles/pre-setup.yaml

  ANSIBLE_RESULT=$?
  if [[ "${ANSIBLE_RESULT}" != "0" ]]; then
    exit ${ANSIBLE_RESULT};
  fi
fi

# bug fix
## jammy aufs-tools not exists ignore
cp -rp ${KUBESPRAY_DIR}/roles/kubernetes/preinstall/vars/ubuntu.yml ${KUBESPRAY_DIR}/roles/kubernetes/preinstall/vars/ubuntu-22.yml
sed -i "/- aufs-tools/d" ${KUBESPRAY_DIR}/roles/kubernetes/preinstall/vars/ubuntu-22.yml

### ansible run part ###
if [[ "${MODE}" == "DEPLOY" ]]; then
  ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/cluster.yml
elif [[ "${MODE}" == "UPGRADE" ]]; then
  ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/upgrade-cluster.yml --limit ${LIMIT_NODES} -f 1
elif [[ "${MODE}" == "SCALE" ]]; then
  ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/facts.yml
  ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/scale.yml --limit ${LIMIT_NODES}
elif [[ "${MODE}" == "REMOVE-NODE" ]]; then
  ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/remove-node.yml -e delete_nodes_confirmation=yes -e node=${LIMIT_NODES}
elif [[ "${MODE}" == "RESET" ]]; then
  ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/reset.yml -e reset_confirmation=yes

  # post reset
  echo "[INFO] ### post reset..."
  ansible-playbook -i ${K8S_INVENTORY_HOSTS} ${KUBESPRAY_DIR}/extfiles/post-reset.yaml
fi

### result part ###
ANSIBLE_RESULT=$?

if [[ "${ANSIBLE_RESULT}" == "0" ]]; then
  SSH_OPTIONS="-i ${KUBESPRAY_DIR}/kubespray_ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  if [[ "${PROXY_SERVER}" != "" ]]; then
    SSH_OPTIONS="${SSH_OPTIONS} -o \"ProxyCommand=nc --proxy ${PROXY_SERVER} %h %p\""
  fi

  if [[ "${MODE}" == "DEPLOY" ]]; then
    ansible -i ${K8S_INVENTORY_HOSTS} kube_control_plane[0] -m fetch -a "flat=yes src=/etc/kubernetes/ssl/ca.crt dest=${K8S_INVENTORY_DIR}/${CLUSTER_NAME}-ca.crt"
    ansible -i ${K8S_INVENTORY_HOSTS} kube_control_plane[0] -m fetch -a "flat=yes src=/etc/kubernetes/ssl/apiserver-kubelet-client.crt dest=${K8S_INVENTORY_DIR}/${CLUSTER_NAME}-admin.crt"
    ansible -i ${K8S_INVENTORY_HOSTS} kube_control_plane[0] -m fetch -a "flat=yes src=/etc/kubernetes/ssl/apiserver-kubelet-client.key dest=${K8S_INVENTORY_DIR}/${CLUSTER_NAME}-admin.key"
    ssh ${SSH_OPTIONS} ${DEPLOY_SERVER} "cd ${CURRENT_DIR};KUBESPRAY_ENV=${KUBESPRAY_ENV} ${PLAYCE_DIR}/playcekube/bin/playcekube_initcluster.sh -f ${KUBESPRAY_ENV}"
  elif [[ "${MODE}" == "RESET" ]]; then
    ssh ${SSH_OPTIONS} ${DEPLOY_SERVER} "kubectl config delete-context admin@${CLUSTER_NAME}"
    ssh ${SSH_OPTIONS} ${DEPLOY_SERVER} "kubectl config delete-user ${CLUSTER_NAME}-admin"
    ssh ${SSH_OPTIONS} ${DEPLOY_SERVER} "kubectl config delete-cluster ${CLUSTER_NAME}"
  fi
fi

exit ${ANSIBLE_RESULT};

