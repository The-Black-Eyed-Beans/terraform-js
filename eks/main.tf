# VPC
resource "aws_vpc" "app_vpc" {
    cidr_block = var.vpc_cidr_block

    tags = {
        Name = "AlineVPC-js"
    }
}

#IAM Role
resource "aws_iam_role" "eks_cluster_iam_role" {
    name = "ClusterIAM-js"

    assume_role_policy = jsonencode({
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid = ""
                Principal = {
                    "Service": "eks.amazonaws.com"
                }
            },
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid = ""
                Principal = {
                    "Service": "ec2.amazonaws.com"
                }
            }
        ]
    })
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.eks_cluster_iam_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role = aws_iam_role.eks_cluster_iam_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_ec2_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks_cluster_iam_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks_cluster_iam_role.name
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


# Cluster EKS
resource "aws_eks_cluster" "eks_cluster" {
    name = "EKSCluster-js"
    role_arn = aws_iam_role.eks_cluster_iam_role.arn

    vpc_config {
        subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    }

    depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy, aws_iam_role_policy_attachment.eks_cluster_ecr_policy]
}

# Nodes
resource "aws_eks_node_group" "node_group" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    node_group_name = "default_node_group"
    node_role_arn = aws_iam_role.eks_cluster_iam_role.arn
    subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]


    scaling_config {
        desired_size = 1
        max_size     = 1
        min_size     = 1
    }

    labels = {
        nodeGroup = "default_node_group"
    }
}
resource "aws_eks_node_group" "public_node_group" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    node_group_name = "public_node_group"
    node_role_arn = aws_iam_role.eks_cluster_iam_role.arn
    subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

    scaling_config {
        desired_size = 1
        max_size     = 1
        min_size     = 1
    }

    labels = {
        nodeGroup = "public_node_group"
    }
}


# Load Balancer
resource "aws_lb" "load_balancer" {
    name = "LoadBalancer-js"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.all_traffic.id]
    subnets = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}
resource "aws_lb_target_group" "target_group" {
    name = "LoadBalancerTargetGroup-js"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.app_vpc.id
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