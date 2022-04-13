output "aws_vpc" {
    description = "The id for the VPC"
    value = aws_vpc.app_vpc.id
}