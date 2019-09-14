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
