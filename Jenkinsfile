pipeline {
  agent any
  
  
  tools{
    terraform "Terraform1.1.7"  
  }
  
  
  environment{
    AWS_ACCOUNT_ID = credentials('aws.id')
    AWS_ACCESS_KEY = credentials('aws.access.key')
    AWS_SECRET_KEY = credentials('aws.secret.key')
  }
  
  
  stages{
    stage('terraform-init') {
      steps {
        sh 'terraform init -backend-config=backend.hcl' 
      }
    }
    stage('set-tf-vars'){
      steps{
        sh 'sh 'chown -R root:jenkins .'
        withCredentials([file(credentialsId: 'input.tfvars', variable: 'tfvars')]){
          writeFile file: 'input.tfvars', text: readFile(tfvars)
        }
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
