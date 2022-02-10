# velero 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 공통 준비작업

```ShellSession
git clone -b dev https://github.com/OpenSourceConsulting/PlayceKube.git
cd PlayceKube
cd kube-packages/velero
```

## 설치

### velero install shell

사설 chart 의 minio  기본 설정에 velero 에서 사용할 수 있는 계정과 bucket 은 자동으로 생성 해준다  
velero 기본 설치에서는 해당 계정 및 bucket을 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/velero/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/velero/values.yaml /playcecloud/playcekube/kube-packages/velero/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns velero

# velero install
helm install velero playcekube/velero -n velero -f /playcecloud/playcekube/kube-packages/velero/installed-values.yaml
```

## 사용법

velero cli 를 사용하여 백업 및 복구를 한다  
다음은 servicetest namespace에 대한 백업 및 복구 예제

```ShellSession
# backup
velero backup create backup-test01 --include-namespaces servicetest --exclude-namespaces kube-system,default

# restore
velero restore create --from-backup backup-test01
```

