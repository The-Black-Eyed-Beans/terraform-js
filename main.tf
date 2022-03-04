# VPC
resource "aws_vpc" "app_vpc" {
    cidr_block = var.vpc_cidr_block

    tags = {
        Name = "AlineVPC-js"
    }
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
    cidr_block = var.public_subnet_cidr_block
    tags = {
        Name = "AlinePublicSubnet-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.app_vpc.id

    route {
        cidr_block = var.public_subnet_cidr_block
        gateway_id = aws_internet_gateway.gateway.id
    }

    tags = {
        Name = "AlinePublicRT-js"
    }
    depends_on = [aws_vpc.app_vpc]
}

# Private subnet and route table
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.private_subnet_cidr_block
    tags = {
        Name = "AlinePrivateSubnet-js"
    }
    depends_on = [aws_vpc.app_vpc]
}
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.app_vpc.id

    route {
        cidr_block = var.private_subnet_cidr_block
        gateway_id = aws_internet_gateway.gateway.id
    }

    tags = {
        Name = "AlinePrivateRT-js"
    }
    depends_on = [aws_vpc.app_vpc]
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
        Name = "AlineAllowHTTP-js"
    }
    
    depends_on = [aws_vpc.app_vpc]
}