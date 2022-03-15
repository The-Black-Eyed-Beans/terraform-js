output "aws_vpc" {
    description = "The id for the VPC"
    value = aws_vpc.app_vpc.id
}

output "public_subnet_1" {
    description = "The id for the first public subnet"
    value = aws_subnet.public_subnet_1.id
}

output "public_subnet_2" {
    description = "The id for the second public subnet"
    value = aws_subnet.public_subnet_2.id
}

output "private_subnet_1" {
    description = "The id for the first private subnet"
    value = aws_subnet.private_subnet_1.id
}

output "private_subnet_2" {
    description = "The id for the second private subnet"
    value = aws_subnet.private_subnet_2.id
}