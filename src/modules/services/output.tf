output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnet_2_id" {
  value = aws_subnet.private_subnet_2.id
}

output "private_subnet_1_cidr_block" {
  value = aws_subnet.private_subnet_1.cidr_block
}