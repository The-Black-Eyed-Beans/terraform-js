# terraform

Contains infrastructure for deploying the necessary network components. Currently expects an input.tfvars file with the following fields:

`vpc_cidr_block`
`private_cidr_block`
`public_cidr_block`
`aws-region`
`db-username`
`db-password`
`db-host`
`db-port`
`db-name`
`encrypt-secret-key`
`jwt-secret-key`
