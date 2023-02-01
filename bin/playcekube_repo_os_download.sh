#!/bin/bash

# sh config
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# repository config
mkdir -p ${PLAYCE_DATADIR}/repositories/{centos7,rocky8,focal,jammy,focal-docker,jammy-docker}
cd ${PLAYCE_DATADIR}/repositories
unlink centos8
unlink almalinux8
ln -s rocky8 centos8
ln -s rocky8 almalinux8

# download os mode
OMODE=${1}
OMODE=${OMODE:=all}

if [ "${OMODE}" == "all" ] || [[ "${OMODE}" =~ .*centos7.* ]]; then

# centos7(rhel7) repo download
docker run -it --rm \
-v ${PLAYCE_DATADIR}/repositories/centos7:/download \
docker.io/library/centos:centos7.9.2009 \
bash -c \
"yum -y install createrepo yum-utils epel-release; \
echo '[INFO] centos 7 base download'; \
reposync -nm --download-metadata --repo base -p /download;
createrepo -v /download/base -o /download/base ; \
echo '[INFO] centos 7 extras download'; \
reposync -nm --download-metadata --repo extras -p /download;
createrepo -v /download/extras -o /download/extras ; \
echo '[INFO] centos 7 updates download'; \
reposync -nm --download-metadata --repo updates -p /download;
createrepo -v /download/updates -o /download/updates ; \
echo '[INFO] centos 7 epel download'; \
reposync -nm --download-metadata --repo epel -p /download;
createrepo -v /download/epel -o /download/epel ; \
echo '[INFO] centos 7 docker-ce download'; \
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo; \
reposync -m --download-metadata --repo docker-ce-stable -p /download; \
createrepo -v /download/docker-ce-stable -o /download/docker-ce-stable ; \
echo '[INFO] centos 7 cri-o download'; \
echo '[devel_kubic_libcontainers_stable]' > /etc/yum.repos.d/crio.repo; \
echo 'name=Stable Releases of Upstream github.com/containers packages (CentOS_7)' >> /etc/yum.repos.d/crio.repo; \
echo 'baseurl=https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_7/' >> /etc/yum.repos.d/crio.repo; \
echo 'enabled=1' >> /etc/yum.repos.d/crio.repo; \
echo 'gpgcheck=0' >> /etc/yum.repos.d/crio.repo; \
echo '[devel_kubic_libcontainers_stable_cri-o_1.22]' >> /etc/yum.repos.d/crio.repo; \
echo 'name=devel:kubic:libcontainers:stable:cri-o:1.22 (CentOS_7)' >> /etc/yum.repos.d/crio.repo; \
echo 'baseurl=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.22/CentOS_7/' >> /etc/yum.repos.d/crio.repo; \
echo 'enabled=1' >> /etc/yum.repos.d/crio.repo; \
echo 'gpgcheck=0' >> /etc/yum.repos.d/crio.repo; \
echo '[devel_kubic_libcontainers_stable_cri-o_1.23]' >> /etc/yum.repos.d/crio.repo; \
echo 'name=devel:kubic:libcontainers:stable:cri-o:1.23 (CentOS_7)' >> /etc/yum.repos.d/crio.repo; \
echo 'baseurl=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.23/CentOS_7/' >> /etc/yum.repos.d/crio.repo; \
echo 'enabled=1' >> /etc/yum.repos.d/crio.repo; \
echo 'gpgcheck=0' >> /etc/yum.repos.d/crio.repo; \
echo '[devel_kubic_libcontainers_stable_cri-o_1.24]' >> /etc/yum.repos.d/crio.repo; \
echo 'name=devel:kubic:libcontainers:stable:cri-o:1.24 (CentOS_7)' >> /etc/yum.repos.d/crio.repo; \
echo 'baseurl=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.24/CentOS_7/' >> /etc/yum.repos.d/crio.repo; \
echo 'enabled=1' >> /etc/yum.repos.d/crio.repo; \
echo 'gpgcheck=0' >> /etc/yum.repos.d/crio.repo; \
reposync -m --download-metadata --repo devel_kubic_libcontainers_stable -p /download; \
createrepo -v /download/devel_kubic_libcontainers_stable -o /download/devel_kubic_libcontainers_stable ; \
reposync -m --download-metadata --repo devel_kubic_libcontainers_stable_cri-o_1.22 -p /download; \
createrepo -v /download/devel_kubic_libcontainers_stable_cri-o_1.22 -o /download/devel_kubic_libcontainers_stable_cri-o_1.22 ; \
reposync -m --download-metadata --repo devel_kubic_libcontainers_stable_cri-o_1.23 -p /download; \
createrepo -v /download/devel_kubic_libcontainers_stable_cri-o_1.23 -o /download/devel_kubic_libcontainers_stable_cri-o_1.23 ; \
reposync -m --download-metadata --repo devel_kubic_libcontainers_stable_cri-o_1.24 -p /download; \
createrepo -v /download/devel_kubic_libcontainers_stable_cri-o_1.24 -o /download/devel_kubic_libcontainers_stable_cri-o_1.24"

fi

if [ "${OMODE}" == "all" ] || [[ "${OMODE}" =~ .*rocky8.* ]]; then

# rockylinux 8(centos8, rhel8) repo download
docker run -it --rm \
-v ${PLAYCE_DATADIR}/repositories/rocky8:/download \
docker.io/rockylinux/rockylinux:8.5 \
bash -c \
"dnf -y install dnf-plugins-core yum-utils createrepo; \
echo '[INFO] rocky 8 baseos download'; \
reposync -nm --download-metadata --repo baseos -p /download; \
echo '[INFO] rocky 8 appstream download'; \
dnf -y module enable container-tools; \
reposync -nm --download-metadata --repo appstream -p /download; \
echo '[INFO] rocky 8 extras download'; \
reposync -nm --download-metadata --repo extras -p /download; \
echo '[INFO] rocky 8 docker-ce download'; \
dnf -y config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo; \
reposync -m --download-metadata --repo docker-ce-stable -p /download; \
createrepo --update -v /download/docker-ce-stable -o /download/docker-ce-stable ; \
echo '[INFO] rocky 8 cri-o download'; \
echo '[devel_kubic_libcontainers_stable]' > /etc/yum.repos.d/crio.repo; \
echo 'name=Stable Releases of Upstream github.com/containers packages (CentOS_8)' >> /etc/yum.repos.d/crio.repo; \
echo 'baseurl=https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_8/' >> /etc/yum.repos.d/crio.repo; \
echo 'enabled=1' >> /etc/yum.repos.d/crio.repo; \
echo 'gpgcheck=0' >> /etc/yum.repos.d/crio.repo; \
echo '[devel_kubic_libcontainers_stable_cri-o_1.22]' >> /etc/yum.repos.d/crio.repo; \
echo 'name=devel:kubic:libcontainers:stable:cri-o:1.22 (CentOS_8)' >> /etc/yum.repos.d/crio.repo; \
echo 'baseurl=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.22/CentOS_8/' >> /etc/yum.repos.d/crio.repo; \
echo 'enabled=1' >> /etc/yum.repos.d/crio.repo; \
echo 'gpgcheck=0' >> /etc/yum.repos.d/crio.repo; \
echo '[devel_kubic_libcontainers_stable_cri-o_1.23]' >> /etc/yum.repos.d/crio.repo; \
echo 'name=devel:kubic:libcontainers:stable:cri-o:1.23 (CentOS_8)' >> /etc/yum.repos.d/crio.repo; \
echo 'baseurl=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.23/CentOS_8/' >> /etc/yum.repos.d/crio.repo; \
echo 'enabled=1' >> /etc/yum.repos.d/crio.repo; \
echo 'gpgcheck=0' >> /etc/yum.repos.d/crio.repo; \
echo '[devel_kubic_libcontainers_stable_cri-o_1.24]' >> /etc/yum.repos.d/crio.repo; \
echo 'name=devel:kubic:libcontainers:stable:cri-o:1.24 (CentOS_8)' >> /etc/yum.repos.d/crio.repo; \
echo 'baseurl=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.24/CentOS_8/' >> /etc/yum.repos.d/crio.repo; \
echo 'enabled=1' >> /etc/yum.repos.d/crio.repo; \
echo 'gpgcheck=0' >> /etc/yum.repos.d/crio.repo; \
reposync -m --download-metadata --repo devel_kubic_libcontainers_stable -p /download; \
createrepo -v /download/devel_kubic_libcontainers_stable -o /download/devel_kubic_libcontainers_stable ; \
reposync -m --download-metadata --repo devel_kubic_libcontainers_stable_cri-o_1.22 -p /download; \
createrepo -v /download/devel_kubic_libcontainers_stable_cri-o_1.22 -o /download/devel_kubic_libcontainers_stable_cri-o_1.22 ; \
reposync -m --download-metadata --repo devel_kubic_libcontainers_stable_cri-o_1.23 -p /download; \
createrepo -v /download/devel_kubic_libcontainers_stable_cri-o_1.23 -o /download/devel_kubic_libcontainers_stable_cri-o_1.23 ; \
reposync -m --download-metadata --repo devel_kubic_libcontainers_stable_cri-o_1.24 -p /download; \
createrepo -v /download/devel_kubic_libcontainers_stable_cri-o_1.24 -o /download/devel_kubic_libcontainers_stable_cri-o_1.24"

fi

if [ "${OMODE}" == "all" ] || [[ "${OMODE}" =~ .*focal.* ]]; then

# ubuntu focal repo download
MIRROR_PROTOCOL=http
#MIRROR_HOST=mirror.kakao.com
MIRROR_HOST=kr.archive.ubuntu.com
MIRROR_URL=ubuntu
RELEASE_NAME=focal
# mirror conf
cat << EOF > /tmp/mirror-${RELEASE_NAME}.conf
set mirror_path /data/apt-mirror
set nthreads 20
set _tilde 0

deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME} main restricted
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-updates main restricted
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME} universe
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-updates universe
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-backports main restricted universe
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-security main restricted
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-security universe
EOF

# download go
docker run -it --rm \
-v /tmp/mirror-${RELEASE_NAME}.conf:/tmp/mirror.conf \
-v ${PLAYCE_DATADIR}/repositories/${RELEASE_NAME}:/data/apt-mirror/${MIRROR_HOST} \
docker.io/library/ubuntu:${RELEASE_NAME} \
bash -c \
"apt update && apt -y install apt-mirror curl; \
curl -LO https://raw.githubusercontent.com/Stifler6996/apt-mirror/master/apt-mirror; \
mv /usr/bin/apt-mirror /usr/bin/apt-mirror.backup; \
cp apt-mirror /usr/bin/apt-mirror; \
chmod 755 /usr/bin/apt-mirror; \
chown root:root /usr/bin/apt-mirror; \
apt-mirror /tmp/mirror.conf"

# ubuntu focal docker ce repo download
MIRROR_HOST=download.docker.com
# mirror conf
cat << EOF > /tmp/mirror-${RELEASE_NAME}.conf
set mirror_path /data/apt-mirror
set nthreads 20
set _tilde 0

deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://${MIRROR_HOST}/linux/ubuntu ${RELEASE_NAME} stable
EOF

# download go
docker run -it --rm \
-v /tmp/mirror-${RELEASE_NAME}.conf:/tmp/mirror.conf \
-v ${PLAYCE_DATADIR}/repositories/${RELEASE_NAME}-docker:/data/apt-mirror/${MIRROR_HOST}/linux \
docker.io/library/ubuntu:${RELEASE_NAME} \
bash -c \
"apt update && apt -y install curl gnupg apt-mirror && mkdir -p /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; cp -rp /etc/apt/keyrings/docker.gpg /data/apt-mirror/${MIRROR_HOST}/linux/docker.gpg; apt-mirror /tmp/mirror.conf"

fi

if [ "${OMODE}" == "all" ] || [[ "${OMODE}" =~ .*jammy.* ]]; then

# ubuntu jammy repo download
MIRROR_PROTOCOL=http
#MIRROR_HOST=mirror.kakao.com
MIRROR_HOST=kr.archive.ubuntu.com
MIRROR_URL=ubuntu
RELEASE_NAME=jammy
# mirror conf
cat << EOF > /tmp/mirror-${RELEASE_NAME}.conf
set mirror_path /data/apt-mirror
set nthreads 20
set _tilde 0

deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME} main restricted
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-updates main restricted
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME} universe
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-updates universe
#deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-backports main restricted
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-backports main restricted universe
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-security main restricted
deb ${MIRROR_PROTOCOL}://${MIRROR_HOST}/${MIRROR_URL} ${RELEASE_NAME}-security universe
EOF

# download go
docker run -it --rm \
-v /tmp/mirror-${RELEASE_NAME}.conf:/tmp/mirror.conf \
-v ${PLAYCE_DATADIR}/repositories/${RELEASE_NAME}:/data/apt-mirror/${MIRROR_HOST} \
docker.io/library/ubuntu:${RELEASE_NAME} \
bash -c \
"apt update && apt -y install apt-mirror curl; \
curl -LO https://raw.githubusercontent.com/Stifler6996/apt-mirror/master/apt-mirror; \
mv /usr/bin/apt-mirror /usr/bin/apt-mirror.backup; \
cp apt-mirror /usr/bin/apt-mirror; \
chmod 755 /usr/bin/apt-mirror; \
chown root:root /usr/bin/apt-mirror; \
apt-mirror /tmp/mirror.conf"

# ubuntu jammy docker ce repo download
MIRROR_HOST=download.docker.com
# mirror conf
cat << EOF > /tmp/mirror-${RELEASE_NAME}.conf
set mirror_path /data/apt-mirror
set nthreads 20
set _tilde 0

deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://${MIRROR_HOST}/linux/ubuntu ${RELEASE_NAME} stable
EOF

# download go
docker run -it --rm \
-v /tmp/mirror-${RELEASE_NAME}.conf:/tmp/mirror.conf \
-v ${PLAYCE_DATADIR}/repositories/${RELEASE_NAME}-docker:/data/apt-mirror/${MIRROR_HOST}/linux \
docker.io/library/ubuntu:${RELEASE_NAME} \
bash -c \
"apt update && apt -y install curl gnupg apt-mirror && mkdir -p /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; cp -rp /etc/apt/keyrings/docker.gpg /data/apt-mirror/${MIRROR_HOST}/linux/docker.gpg; apt-mirror /tmp/mirror.conf"

fi

echo "[INFO] pull & push rancher agent image"
docker run --name download_registry \
  --rm -d \
  -v ${PLAYCE_DATADIR}/registry:/var/lib/registry \
  -p 5001:5000 \
  docker.io/library/registry:2.7.1

cat << EOF > /tmp/tmpimagelist.txt
docker.io/rancher/rancher-agent:v2.6.6
docker.io/rancher/shell:v0.1.16
docker.io/rancher/fleet-agent:v0.3.9
docker.io/rancher/fleet:v0.3.9
docker.io/rancher/gitjob:v0.1.26
docker.io/rancher/rancher-webhook:v0.2.5
docker.io/rancher/rancher-webhook:v0.2.7
docker.io/rancher/mirrored-coredns-coredns:1.9.1
EOF

# pull & push
for cimg in $(cat ${PLAYCE_DIR}/playcedeploy/rancher/imagelist.txt)
do
  docker pull -q ${cimg}
  docker tag ${cimg} $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/127.0.0.1:5001\/\2/g")
  docker push -q $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/127.0.0.1:5001\/\2/g")
done

# rmi
for cimg in $(cat ${PLAYCE_DIR}/playcedeploy/rancher/imagelist.txt)
do
  docker rmi $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/127.0.0.1:5001\/\2/g")
done

docker stop download_registry


