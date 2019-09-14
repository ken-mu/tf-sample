variable "aws_access_key" {}
variable "aws_access_secret" {}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_access_secret
}

resource "aws_vpc" "main" {
  cidr_block       = "10.1.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.1.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-1"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-1"
  }
}

resource "aws_eip" "public-1" {
  vpc = true
  
  tags {
    Name = "public-1"
  }
}

resource "aws_nat_gateway" "public-1" {
  allocation_id = "${aws_eip.public-1.id}"
  subnet_id = "${aws_subnet.public-1.id}"
  
  tags {
    Name = "public-1"
  }
}

resource "aws_route_table" "public-1" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
  
  tags {
    Name = "public-1"
  }
}

resource "aws_route_table" "private-1" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.public-1.id}"
  }
  
  tags {
    Name = "private-1"
  }
}

resource "aws_route_table_association" "public-1" {
  subnet_id = "${aws_subnet.public-1.id}"
  route_table_id = "${aws_route_table.public-1.id}"
  
  tags {
    Name = "public-1"
  }
}

resource "aws_route_table_association" "private-1" {
  subnet_id = "${aws_subnet.private-1.id}"
  route_table_id = "${aws_route_table.private-1.id}"
  
  tags {
    Name = "private-1"
  }
}
