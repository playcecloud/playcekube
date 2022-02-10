# tekton pipeline example

gs-maven 이라는 maven 프로젝트 하나를 받아서 git 으로 다운로드 해서 이미지로 빌드 하고 사설 registry 서버에 올리고 실행해 보는 예제
tekton 은 k8s crd(custom resource define)를 이용하여 태스크 및 파이프라인을 정의하여 모듈형식의 사용 및 재사용이 좀 더 편리하다

## 공통 준비작업

```ShellSession

git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/tekton
cd usage/maven-example

```

## Example

#### create ns resources

tekton-example 란 namespace를 만들고 pipeline 에서 사용할 pv, pvc를 생성. 컴파일 및 이미지 빌드 푸시에 사용할 레지스트리 url 을 pipelineresource 로 생성

```ShellSession

# create namespace
kubectl apply -f 00-ns.yaml

# create pv,pvc
kubectl apply -f 01-pv_pvc.yaml

# create pipeline resources
kubectl apply -f 02-resource.yaml

```

#### create task

##### compile
gs-maven 이라는 maven 프로젝트를 받아서 가이드 대로 openjdk8 버전 컨테이너에서 컴파일 하도록 한다
여기서 리소스는 pipelineresource 로 생성해 둔걸 사용하도록 하고 특정 워크스페이스에 컴파일한 jar 파일을 복사해 둔다

##### build & push
jdk8 컨테이너 이미지를 기반으로 특정 워크스페이스에서 jar 파일을 복사하여 실행하는 Dockerfile 을 만들어 이미지를 생성
만들어진 이미지를 pipelineresource 에서 지정한 image url을 사용하여 태깅하고 푸시한다
또한 sidecar 로 컨테이너 빌드를 할 docker 서버를 dind 컨테이너 이미지를 이용하여 실행하며 private registry 를 사용하기 위한 insecure 설정까지 같이 해준다

```ShellSession

# create maven compile task
kubectl apply -f 10-maven-compile.yaml

# container image build & push
kubectl apply -f 11-image-build-push.yaml

```

#### create pipeline and run

소스를 컴파일하고 이미지를 빌드 & 푸시 하는 태스크들을 순서를 정하고 사용할 리소스 및 워크스페이스를 정의
pipeline run은 정의한 pipeline 의 리소스 및 워크스페이스를 매핑 해주는 설정을 한다. 또한 이 crd 리소스는 정의하면 pipeline 이 실행된다
tkn pipeline start <pipelinename> 으로 실행 할 수도 있는데 이 경우 매핑할 리소스에 대한 값을 키입력으로 받는다(파라메터를 옵션으로 줄수도 있음)
사용상 pipeline run 리소스를 사용하여 실행하는 것이 관리 및 운영이 쉬울듯 함

```ShellSession

# create pipeline
kubectl apply -f 20-maven-pipeline.yaml

# run pipeline
kubectl replace --force -f 21-maven-pipeline-run.yaml

```

#### check logs and result

해당 명령으로 태스크 순서대로 로그를 볼 수 있으며 실행 파드에서 직접 볼수도 있다. 이쪽이 보기 더 편함
실행하고 정상 동작한 결과 이미지를 실행해 보고 최종 확인
이후 추가 webapp,ingress 및 argocd 를 이용한 연동 예제를 작성할 예정

```ShellSession

# check pipeline run
tkn pipelinerun logs maven-pipeline-run -f
docker run 192.168.50.10:5000/tekton-example/result:v0.1

```


