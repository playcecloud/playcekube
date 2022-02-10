# csi-driver-nfs 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 공통 준비작업

```ShellSession
git clone -b dev https://github.com/OpenSourceConsulting/PlayceKube.git
cd PlayceKube
cd kube-packages/csi-driver-nfs
```

## 설치

### csi-driver-nfs install shell

```ShellSession
# install
/playcecloud/playcekube/kube-packages/csi-driver-nfs/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/csi-driver-nfs/values.yaml /playcecloud/playcekube/kube-packages/csi-driver-nfs/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns csi-driver-nfs

# csi-driver-nfs install
helm install csi-driver-nfs playcekube/csi-driver-nfs -n csi-driver-nfs -f /playcecloud/playcekube/kube-packages/csi-driver-nfs/installed-values.yaml
```

