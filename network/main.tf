resource "aws_vpc" "capstone_vpc" {
    cidr_block = "10.2.0.0/24"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "capstone-vpc"
        Project = "Capstone"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.capstone_vpc.id
    tags = {
        Name = "capstone-igw"
        Project = "Capstone"
    }
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.capstone_vpc.id
    cidr_block = "10.2.0.0/26"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = false

    tags = {
        Name = "capstone-public-subnet"
        Project = "Capstone"
    }
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.capstone_vpc.id
    cidr_block = "10.2.0.64/26"
    availability_zone = "us-east-1a"

    tags = {
        Name = "capstone-private-subnet"
        Project = "Capstone"
    }
}

resource "aws_subnet" "monitoring" {
    vpc_id = aws_vpc.capstone_vpc.id
    cidr_block = "10.2.0.128/26"
    availability_zone = "us-east-1a"

    tags = {
        Name = "capstone-monitoring-subnet"
        Project = "Capstone"
        Type = "monitoring"
    }
}

resource "aws_eip" "nat" {
    tags = {
        Name = "capstone-nat-eip"
        Project = "Capstone"
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public.id

    tags = {
        Name = "capstone-nat-gateway"
        Project = "Capstone"
    }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.capstone_vpc.id

    tags = {
        Name = "capstone-public-rt"
        Project = "Capstone"
    }
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.capstone_vpc.id
    tags = {
        Name = "capstone-private-rt"
        Project = "Capstone"
    }
}

resource "aws_route" "public_to_internet" {
    route_table_id = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  
}

resource "aws_route" "private_to_internet" {
    route_table_id = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public_assoc" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "monitoring_assoc" {
    subnet_id = aws_subnet.monitoring.id
    route_table_id = aws_route_table.private_rt.id
}

