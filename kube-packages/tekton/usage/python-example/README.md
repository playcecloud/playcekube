# tekton pipeline example

심플한 python flask webapp을 만들어github 에 올린 후 인증정보를 필요로 하게 설정 후 github 인증 정보를 적용해서 다운로드해서
이미지로 빌드 하고 사설 registry 서버에 올리고 실행해 보는 예제

## 공통 준비작업

```ShellSession

git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/tekton
cd usage/python-example

```

## Example

#### create ns resources

tekton-example 이란 namespace를 만들고 pipeline 에서 사용할 pv, pvc를 생성. 컴파일 및 이미지 빌드 푸시에 사용할 레지스트리 url 을 pipelineresource 로 생성
여기선 github 인증 정보를 시크릿 파일로 만들고 github 용 계정을 만들어 시크릿을 추가한다

```ShellSession

# create namespace
kubectl apply -f 00-ns.yaml

# create pv,pvc
kubectl apply -f 01-pv_pvc.yaml

# create pipeline resources
kubectl apply -f 02-resource.yaml

```

#### create task

##### app download & env create
flask app을 사용할 base image를 파라메터로 입력 받고 python 이미지를 사용할 경우 추가 라이브러리 환경 구성을 위해 virutalenv 를 설치하고 구성한다(flask 및 관련 라이브러리 설치)
이미지 빌드 후 사용시 path를 맞추기 위해 path 를 특정한다 (virtualenv 는 환경 구성시 절대 경로를 사용함)
환경구성 후 다음 태스크를 위하 워크스페이스로 복사

##### build & push
base image를 파라메터로 입력 받아 워크스페이스에 복사된 virtualenv 환경 및 flask app을 복사하고 실행하는 Dockerfile을 만들어 이미지를 생성
만들어진 이미지를 pipelineresource 에서 지정한 image url을 사용하여 태깅하고 푸시한다
또한 sidecar 로 컨테이너 빌드를 할 docker 서버를 dind 컨테이너 이미지를 이용하여 실행하며 private registry 를 사용하기 위한 insecure 설정까지 같이 해준다

```ShellSession

# create flaskapp task
kubectl apply -f 10-template-create-flaskapp.yaml

# container image build & push
kubectl apply -f 11-template-image-build-push.yaml

```

#### create pipeline and run

flask app 환경 구성을 하고 이미지를 빌드 & 푸시 하는 태스크들을 순서를 정하고 사용할 리소스 및 워크스페이스를 정의
pipeline run은 정의한 pipeline 의 리소스 및 워크스페이스를 매핑 해주는 설정을 한다. 또한 이 crd 리소스는 정의하면 pipeline 이 실행된다
tkn pipeline start <pipelinename> 으로 실행 할 수도 있는데 이 경우 매핑할 리소스에 대한 값을 키입력으로 받는다.(파라메터를 옵션으로 줄수도 있음)
사용상 pipeline run 리소스를 사용하여 실행하는 것이 관리 및 운영이 쉬울듯 함
* pipelinerun 에github 인증 secret을 사용하기 위해 serviceAccountName: github-bot 를 추가


```ShellSession

# create pipeline
kubectl apply -f 20-template-flaskapp-pipeline.yaml

# run pipeline
kubectl replace --force -f 21-template-flaskapp-pipeline-run.yaml

```

#### check logs and result

해당 명령으로 태스크 순서대로 로그를 볼 수 있으며 실행 파드에서 직접 볼수도 있다. 이쪽이 보기 더 편함
실행하고 정상 동작한 결과 이미지를 실행해 보고 최종 확인
이 예제는 flask app 심플 예제로 기본 listen 포트는 5000이다.


```ShellSession

# check pipeline run
tkn pipelinerun logs maven-pipeline-run -f

docker rm flasktest 
docker pull 192.168.50.10:5000/tekton-example/flaskapp:v0.1
docker run -it -d --name flasktest 192.168.50.10:5000/tekton-example/flaskapp:v0.1
sleep 3
docker exec -it flasktest curl localhost:5000


```

