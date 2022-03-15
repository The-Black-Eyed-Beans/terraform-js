pipeline {
  agent any
  
  environment{
    
  }
  
  tools{
    terraform "Terraform1.1.7"  
  }
  
  stages{
    stage('terraform-init') {
      steps {
        sh 'terraform init -backend-config=backend.hcl' 
      }
    }
    stage('terraform-plan') {
      steps {
        withAWS(credentials: 'jenkins.aws.credentials.js', region: credentials("deployment.region")){
          sh 'terraform plan -var-file=input.tfvars -no-color'
        }
      }
    }
    stage('terraform-apply') {
      steps {
        withAWS(credentials: 'jenkins.aws.credentials.js', region: credentials("deployment.region")){
          sh 'terraform apply -var-file=input.tfvars -auto-approve -no-color'
        }
      }
    }
  }
}
