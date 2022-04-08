# VPC
resource "aws_vpc" "app_vpc" {
    cidr_block = var.vpc_cidr_block

    tags = {
        Name = "AlineVPC-js"
    }
}

#IAM Role
resource "aws_iam_role" "task-execution-role" {
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
resource "aws_iam_role_policy_attachment" "ecr_read_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.task-execution-role.name
}
resource "aws_iam_role_policy_attachment" "task_execution_policy" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    role = aws_iam_role.task-execution-role.name
}


# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.app_vpc.id

    tags = {
        Name = "AlineIG-js"
    }
    depends_on = [aws_vpc.app_vpc]
}

# Nat Gateway
resource "aws_nat_gateway" "nat_gateway" {
    connectivity_type = "public"
    subnet_id = aws_subnet.public_subnet_1.id
    allocation_id = aws_eip.nat_ip.id

    tags = { Name = "NATGateway-js"}
}
resource "aws_eip" "nat_ip" {
    tags = { Name = "NATGatewayEIP-js"}
    depends_on = [aws_internet_gateway.internet_gateway] 
}


# Public subnet and route table
resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.public_cidr_block_1
    map_public_ip_on_launch = true
    tags = {
        Name = "AlinePublicSubnet1-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.public_cidr_block_2
    map_public_ip_on_launch = true
    tags = {
        Name = "AlinePublicSubnet2-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.app_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }

    tags = {
        Name = "AlinePublicRT-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}




# Private subnet and route table
resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.private_cidr_block_1
    availability_zone = "us-west-1a"
    tags = {
        Name = "AlinePrivateSubnet1-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.private_cidr_block_2
    availability_zone = "us-west-1c"
    tags = {
        Name = "AlinePrivateSubnet2-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.app_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }

    tags = {
        Name = "AlinePrivateRT-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table_association" "private_route_table_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association" "private_route_table_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}


# ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
    name = "ECScluster-js"
}

resource "aws_ecs_task_definition" "transaction-task" {
    family = "transaction-task"

    container_definitions = <<DEFINITION
    [
        {
            "name": "transaction-container-js",
            "image": "086620157175.dkr.ecr.us-west-1.amazonaws.com/transaction-microservice-js",
            "entryPoint": [],
            "essential": true,
            "portMappings": [
                {
                    "containerPort": 8073,
                    "hostPort": 8073
                }
            ],
            "cpu": 512,
            "memory": 1024,
            "networkMode": "awsvpc"
        }
    ]
    DEFINITION

    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    memory = "1024"
    cpu = "512"
    execution_role_arn = aws_iam_role.task-execution-role.arn
    task_role_arn      = aws_iam_role.task-execution-role.arn 

}

resource "aws_ecs_service" "transaction_service" {
    name = "TransactionService-js"
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.transaction-task.arn
    desired_count = 1
    launch_type = "FARGATE"
    scheduling_strategy = "REPLICA"
    force_new_deployment = true

    network_configuration {
        subnets = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
        assign_public_ip = true
        security_groups = [
            aws_security_group.all_traffic.id
        ]
    }

    load_balancer {
      target_group_arn = aws_lb_target_group.transaction_target_group.arn
      container_name = "transaction-container-js"
      container_port = 8073
    }
}


# Load Balancer
resource "aws_lb" "load_balancer" {
    name = "TransactionLoadBalancer-js"
    internal = false
    load_balancer_type = "network"
    subnets = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}
# Target Group
resource "aws_lb_target_group" "transaction_target_group" {
    name = "TransactionTargetGroup-js"
    port = 8073
    protocol = "TCP"
    target_type = "ip"
    vpc_id = aws_vpc.app_vpc.id

    health_check {
      protocol = "TCP"
      healthy_threshold = "3"
      unhealthy_threshold = "3"
      interval = "30"
    }
}
# Listener
resource "aws_lb_listener" "transaction_listener" {
    load_balancer_arn = aws_lb.load_balancer.arn
    port = 8073
    protocol = "TCP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.transaction_target_group.id
    }
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