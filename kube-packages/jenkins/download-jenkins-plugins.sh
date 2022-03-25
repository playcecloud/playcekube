#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))
if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# plugin download
CURLTEMP=$(mktemp -d)
cd ${CURLTEMP}

JENKINS_VERSION=$(helm search repo | grep "playcekube/jenkins" | awk '{ print $3 }')

curl -L -o plugin-versions.json https://updates.jenkins.io/plugin-versions.json?version=${JENKINS_VERSION} 2> /dev/null
curl -L -o update-center.json https://updates.jenkins.io/update-center.json?version=${JENKINS_VERSION} 2> /dev/null
sed -i "3d" update-center.json
sed -i "1d" update-center.json

createPluginList()
{
  local LIST_FILENAME=$1
  local PLUG_NAME=$2
  local PLUG_VERSION=$3
  local SUBSTR

  if [[ "$(cat ${LIST_FILENAME} | grep ${PLUG_NAME} | grep ${PLUG_VERSION})" ]]; then
    return;
  fi

  echo "${PLUG_NAME}:${PLUG_VERSION}" >> ${LIST_FILENAME}
  cat plugin-versions.json | jq -r ".plugins.${PLUG_NAME}.${PLUG_VERSION}.dependencies[] | \"\\\"\" + .name + \"\\\":\\\"\" + .version +  \"\\\"\"" > temppluginlist.txt

  for SUBSTR in $(cat temppluginlist.txt)
  do
    local SUB_PLUG_NAME=${SUBSTR%:*}
    local SUB_PLUG_VERSION=${SUBSTR#*:}

    createPluginList ${LIST_FILENAME} ${SUB_PLUG_NAME} ${SUB_PLUG_VERSION}
  done
}

# create pluginlist
echo "Start create plugin list..."
touch pluginlist.txt

# helm chart default
for LISTSTR in $(grep -A 10 "installPlugins:" ${BASEDIR}/values.yaml | grep " - " | awk '{ print $2 }')
do
  PLUGNAME=${LISTSTR%:*}
  PLUGVERSION=${LISTSTR#*:}

  createPluginList pluginlist.txt \"${PLUGNAME}\" \"${PLUGVERSION}\"
done

cat pluginlist.txt | sort -V -u > temppluginlist2.txt
cat temppluginlist2.txt > pluginlist.txt

echo "add latest plugin list..."
# update-center latest list
cat pluginlist.txt | sort -V -t: -k1,1 -u > temp-latest-pluginlist.txt
touch latest-pluginlist.txt
for LISTSTR in $(cat temp-latest-pluginlist.txt)
do
  PLUGNAME=${LISTSTR%:*}

  echo "${PLUGNAME}:$(cat update-center.json | jq ".plugins.${PLUGNAME}.version")" >> latest-pluginlist.txt
done

for LISTSTR in $(cat latest-pluginlist.txt)
do
  PLUGNAME=${LISTSTR%:*}
  PLUGVERSION=${LISTSTR#*:}

  createPluginList pluginlist.txt ${PLUGNAME} ${PLUGVERSION}
done

cat pluginlist.txt | sort -V -u > temppluginlist2.txt
cat temppluginlist2.txt > pluginlist.txt

# update-center latest list 2
cat pluginlist.txt | sort -V -t: -k1,1 -u > temp-latest-pluginlist.txt
touch latest-pluginlist.txt
for LISTSTR in $(cat temp-latest-pluginlist.txt)
do
  PLUGNAME=${LISTSTR%:*}

  echo "${PLUGNAME}:$(cat update-center.json | jq ".plugins.${PLUGNAME}.version")" >> latest-pluginlist.txt
done

for LISTSTR in $(cat latest-pluginlist.txt)
do
  PLUGNAME=${LISTSTR%:*}
  PLUGVERSION=${LISTSTR#*:}

  echo "latest ${PLUGNAME} ${PLUGVERSION}"
  createPluginList pluginlist.txt ${PLUGNAME} ${PLUGVERSION}
done

cat pluginlist.txt | sort -V -u > temppluginlist2.txt
cat temppluginlist2.txt > pluginlist.txt


echo "cleanup json files..."
for LISTSTR in $(cat pluginlist.txt | sort -V -t: -k1,1 -u)
do
  PLUGNAME=${LISTSTR%:*}
  PLUGVERSION=${LISTSTR#*:}

  cat update-center.json | jq ".plugins.${PLUGNAME}.private=true" > update-center2.json
  cat update-center2.json > update-center.json
done

cat update-center.json | jq "del( .plugins[] | select( .private!=true ) )" > update-center2.json
cat update-center2.json > update-center.json

for LISTSTR in $(cat pluginlist.txt)
do
  PLUGNAME=${LISTSTR%:*}
  PLUGVERSION=${LISTSTR#*:}

  cat plugin-versions.json | jq ".plugins.${PLUGNAME}.${PLUGVERSION}.private=true" > plugin-versions2.json
  cat plugin-versions2.json > plugin-versions.json
done

cat plugin-versions.json | jq "del( .plugins[] | .[] | select( .private!=true ) )" > plugin-versions2.json
cat plugin-versions2.json > plugin-versions.json

# last plugin-versions.json
mkdir -p ${PLAYCE_DATADIR}/repositories/jenkins
sed -i "s|https://updates.jenkins.io|https://repositories.${PLAYCE_DOMAIN}/jenkins|g" plugin-versions.json

cat plugin-versions.json > ${PLAYCE_DATADIR}/repositories/jenkins/plugin-versions.json

# last update-center.json
mkdir -p ${PLAYCE_DATADIR}/repositories/jenkins
sed -i "s|https://updates.jenkins.io|https://repositories.${PLAYCE_DOMAIN}/jenkins|g" update-center.json

cat update-center.json | jq . -M -c > ${PLAYCE_DATADIR}/repositories/jenkins/update-center.json
sed -i "1i\updateCenter.post(" ${PLAYCE_DATADIR}/repositories/jenkins/update-center.json
echo ");" >> ${PLAYCE_DATADIR}/repositories/jenkins/update-center.json

# download start
echo "Start download plugins..."
for LISTSTR in $(cat pluginlist.txt)
do
  PLUGNAME=${LISTSTR%:*}
  PLUGNAME=${PLUGNAME//\"}
  PLUGVERSION=${LISTSTR#*:}
  PLUGVERSION=${PLUGVERSION//\"}

  mkdir -p ${PLAYCE_DATADIR}/repositories/jenkins/download/plugins/${PLUGNAME}/${PLUGVERSION}
  cd ${PLAYCE_DATADIR}/repositories/jenkins/download/plugins/${PLUGNAME}/${PLUGVERSION}
  curl -LO https://updates.jenkins.io/download/plugins/${PLUGNAME}/${PLUGVERSION}/${PLUGNAME}.hpi 2> /dev/null
done

cd ~

rm -rf ${CURLTEMP}


