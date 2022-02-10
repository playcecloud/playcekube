# tekton Usage

tekton에서는 Task, TaskRun, Pipeline, PipelineRun, PipelineResource 등의 crd(CustomResourceDefinition)를 정의하여 사용  
Task 를 한가지 작업의 단위로 정의 하고 Task 단위로 작업을 실행 할 수 있고 이 Task들을 엮어서 Pipeline 작업으로 사용할 수 있다  
Task나 Pipeline 에서 사용할 변수 값들은 Parameter 나 PipelineResource 를 정의하여 사용할 수 있다  
kubernetes의 crd로 정의되어 있어 kubectl 커맨드로 설정 및 수행을 하고 별도로 제공하는 tkn 커맨드로도 작업이 가능하다

## Example

- [maven example](maven-example)
- [python example](python-example)

