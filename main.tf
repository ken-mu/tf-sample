variable "aws_access_key" {}
variable "aws_access_secret" {}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_access_secret
}

module "mod_main_vpc" {
  source = "module-sample/aws"
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
  
  tags = {
    Name = "public-1"
  }
}

resource "aws_nat_gateway" "public-1" {
  allocation_id = "${aws_eip.public-1.id}"
  subnet_id = "${aws_subnet.public-1.id}"
  
  tags = {
    Name = "public-1"
  }
}

resource "aws_route_table" "public-1" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
  
  tags = {
    Name = "public-1"
  }
}

resource "aws_route_table" "private-1" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.public-1.id}"
  }
  
  tags = {
    Name = "private-1"
  }
}

resource "aws_route_table_association" "public-1" {
  subnet_id = "${aws_subnet.public-1.id}"
  route_table_id = "${aws_route_table.public-1.id}"
}

resource "aws_route_table_association" "private-1" {
  subnet_id = "${aws_subnet.private-1.id}"
  route_table_id = "${aws_route_table.private-1.id}"
}

resource "aws_elb" "bar" {
  name               = "foobar-terraform-elb"
  availability_zones = ["us-east-1a"]
  
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
  
  instances                   = ["${aws_instance.foo.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  
  tags = {
    Name = "foobar-terraform-elb"
  }
}

data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners           = ["amazon"]

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_instance" "foo" {
    ami = "${data.aws_ami.amazon-linux-2.id}"
    instance_type = "t2.micro"
    security_groups = ["${aws_security_group.instance.id}"]
    subnet_id = "${aws_subnet.private-1.id}"

    user_data = <<-EOF
                #! /bin/bash
                sudo yum update
                sudo yum install -y httpd
                sudo chkconfig httpd on
                sudo service httpd start
                echo "<h1>hello world</h1>" | sudo tee /var/www/html/index.html
                EOF
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    vpc_id = "${aws_vpc.main.id}"    

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
      create_before_destroy = true
  }
}
