pipeline {
  agent any
  stages{
    stage('terraform-plan') {
      steps {
        sh './terraformw plan -var-file=input.tfvars -no-color'
      }
    }
    stage('terraform-apply') {
      steps {
        sh './terraformw apply -var-file=input.tfvars -auto-approve -no-color'
      }
    }
  }
}
