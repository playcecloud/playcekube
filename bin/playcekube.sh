#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

function playcekube_help()
{
cat << EOF
Playce Kube controls

Available Commands:
  k8s           Kubernetes control command
  addon         Playce Kube addon command

Usage:
  playcekube [command] [options]
EOF
}

function playcekube_k8s_help()
{
cat << EOF

Playce Kube Kubernetes controls

Available Commands:
  list              Kubernetes cluster list
  install           Kubernetes cluster install

Usage:
  playcekube k8s [subcommand] [options]

EOF
}

function playcekube_k8s_install_help()
{
cat << EOF

Playce Kube Kubernetes cluster installer

Examples:
  # install use env-file
  playcekube k8s install -f kubespray-sample.env

  # install use env-file and env values
  playcekube k8s install -f kubespray-sample.env -e MODE=UPGRADE


Options:
  -f: env file
  -e: env values 

Usage:
  playcekube k8s install [options]

EOF
}


function playcekube_addon_help()
{
cat << EOF

Playce Kube addon controls

Available Commands:
  list              Playce Kube addon list
  install-list      Playce Kube addon installed list

Usage:
  playcekube addon [subcommand] [options]

EOF
}


function playcekube_k8s()
{
  SUBCOMMAND=$1
  shift
  SUBPARAMS=$*

  case ${SUBCOMMAND} in
    list)
      kubectl config get-contexts
      ;;
    install)
      playcekube_k8s_install ${SUBPARAMS}
      ;;
    *)
      playcekube_k8s_help
      ;;
  esac
}

function playcekube_k8s_install()
{
  SUBPARAMS=$*

  if [ "${SUBPARAMS}" == "" ] || [ "${SUBPARAMS}" =~ "--help" ] ; then
    playcekube_k8s_install_help
  else
    ${PLAYCE_DIR}/playcekube/bin/playcekube_kubespray.sh ${SUBPARAMS}
  fi
}

function playcekube_addon()
{
  SUBCOMMAND=$1
  shift
  SUBPARAMS=$*

  case ${SUBCOMMAND} in
    list)
      helm search repo
      ;;
    install-list)
      helm list ${SUBPARAMS}
      ;;
    *)
      playcekube_addon_help
      ;;
  esac
}

# main commander
SUBCOMMAND=$1
shift
SUBPARAMS=$*

case ${SUBCOMMAND} in
  k8s | kubernetes | kubectl)
    playcekube_k8s ${SUBPARAMS}
    ;;
  addon | helm)
    playcekube_addon ${SUBPARAMS}
    ;;
  *)
    playcekube_help
    ;;
esac


