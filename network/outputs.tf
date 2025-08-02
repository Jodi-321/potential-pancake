output "vpc_id" {
    value = aws_vpc.capstone_vpc.id
}

output "public_subnet_id" {
    value = aws_subnet.public.id
}

output "private_subnet_id" {
    value = aws_subnet.private.id
}

output "private_monitor_subnet_id" {
    value = aws_subnet.monitoring.id
}


