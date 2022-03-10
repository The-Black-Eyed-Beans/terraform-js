# VPC
resource "aws_vpc" "app_vpc" {
    cidr_block = var.vpc_cidr_block

    tags = {
        Name = "AlineVPC-js"
    }
}

#IAM Role
resource "aws_iam_role" "cluster_iam_role" {
    name = "ClusterIAM-js"

    assume_role_policy = jsonencode({
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid = ""
                Principal = {
                    "Service": "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })
}


# Internet Gateway
resource "aws_internet_gateway" "gateway" {
    vpc_id = aws_vpc.app_vpc.id

    tags = {
        Name = "AlineIG-js"
    }
    depends_on = [aws_vpc.app_vpc]
}

# Public subnet and route table
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.public_cidr_block
    tags = {
        Name = "AlinePublicSubnet-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.app_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gateway.id
    }

    tags = {
        Name = "AlinePublicRT-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Private subnet and route table
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.private_cidr_block
    tags = {
        Name = "AlinePrivateSubnet-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.app_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        network_interface_id = aws_ecs_service.user_task_definition_service.id
    }

    tags = {
        Name = "AlinePrivateRT-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# Cluster ECS
resource "aws_ecs_cluster" "ecs_cluster" {
    name = "ECS-Cluster-js"
}
resource "aws_ecs_task_definition" "user_microservice" {
    family = "user-task"
    execution_role_arn = aws_iam_role.cluster_iam_role.arn
    container_definitions = jsonencode([
        {
            name = "UserMicroservice-js"
            image = "086620157175.dkr.ecr.us-west-1.amazonaws.com/user-microservice-js"
            essential = true
            memory = 1024
            cpu = 512
            environment = [
                {"name": "ENCRYPT_SECRET_KEY",  "value": "${var.encrypt-secret-key}"},
                {"name": "JWT_SECRET_KEY",      "value": "${var.jwt-secret-key}"},
                {"name": "DB_USERNAME",         "value": "${var.db-username}"},
                {"name": "DB_PASSWORD",         "value": "${var.db-password}"},
                {"name": "DB_HOST",             "value": "${var.db-host}"},
                {"name": "DB_PORT",             "value": "${var.db-port}"},
                {"name": "DB_NAME",             "value": "${var.db-name}"},
                {"name": "APP_PORT",            "value": "8070"}
            ]
            portMappings = [
                {
                    containerPort = 8070
                    hostPort = 8070
                }
            ]
        }
    ])
}
resource "aws_ecs_service" "user_task_definition_service" {
    name = "UserTaskDefinitionService-js"
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.user_microservice.arn
    desired_count = 1
}

# Security Groups
resource "aws_security_group" "all_traffic" {
    description = "Allows all inbound traffic"
    vpc_id = aws_vpc.app_vpc.id

    ingress {
        from_port = 0
        to_port = 0
        protocol = "all"
        cidr_blocks = [aws_vpc.app_vpc.cidr_block]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "AlineAllowAll-js"
    }
    
    depends_on = [aws_vpc.app_vpc]
}