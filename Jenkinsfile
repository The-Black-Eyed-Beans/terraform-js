pipeline {
  agent any
  stages{
    stage('terraform-init') {
      steps {
        sh 'init -backend-config=backend.hcl' 
      }
    }
    stage('terraform-plan') {
      steps {
        sh 'terraform plan -var-file=input.tfvars -no-color'
      }
    }
    stage('terraform-apply') {
      steps {
        sh 'terraform apply -var-file=input.tfvars -auto-approve -no-color'
      }
    }
  }
}
