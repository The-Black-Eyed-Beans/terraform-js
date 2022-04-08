variable "vpc_cidr_block" {
    type = string
    description = "The CIDR block for the VPC"
}

variable "private_cidr_block_1" {
    type = string
    description = "The CIDR block for the first private subnet"
}

variable "private_cidr_block_2" {
    type = string
    description = "The CIDR block for the second private subnet"
}

variable "public_cidr_block_1" {
    type = string
    description = "The first CIDR block for the public resources"
}

variable "public_cidr_block_2" {
    type = string
    description = "The second CIDR block for the public resources"
}

variable "aws-region" {
    type = string
    description = "The region to deploy our application"
}

variable "db-username" {
    type = string
    description = "username for database credentials"
}

variable "db-password" {
    type = string
    description = "password for database credentials"
}

variable "db-host" {
    type = string
    description = "Location of the database"
}

variable "db-port" {
    type = string
    description = "Port where the database can  be found"
}

variable "db-name" {
    type = string
    description = "Name of the specific database to reference"
}

variable "encrypt-secret-key" {
    type = string
    description = "Key for encryption in internal microservice communication"
}

variable "jwt-secret-key" {
    type = string
    description = "Encryption key for Java applications"
}