variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
variable "AWS_DEFAULT_REGION" {}

provider "aws" {
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
  region     = var.AWS_DEFAULT_REGION
}


# Create VPC
# isolated network within our region spanning multiple AZ
resource "aws_vpc" "terraform-test-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-test-vpc"
  }
}

# Create Internet Gateway for both ingress and egress traffic between VPC and WWW
resource "aws_internet_gateway" "terraform-test-igw" {
  vpc_id = aws_vpc.terraform-test-vpc.id

  tags = {
    Name = "terraform-test-internet-gateway"
  }
}

# Create custom route table
resource "aws_route_table" "terraform-test-rt" {
  vpc_id = aws_vpc.terraform-test-vpc.id

  route {
    # Route all IPv4 traffic to Internet gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-test-igw.id # Target
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.terraform-test-igw.id
  }

  tags = {
    Name = "terraform-test-route-table"
  }
}


# Create subnet in AZ
resource "aws_subnet" "terraform-test-subnet-1" {
  vpc_id            = aws_vpc.terraform-test-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "terraform-test-subnet-1"
  }
}


# Associate subnet to with Route Table
resource "aws_route_table_association" "subnet-1-rt" {
  subnet_id      = aws_subnet.terraform-test-subnet-1.id
  route_table_id = aws_route_table.terraform-test-rt.id
}


# Security Group (Firewall)
# Open port 22 for inbound traffic for SSH
# Open port 80 and 443 for inbound and outbound traffic
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow SSH, HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.terraform-test-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443 # Port range start
    to_port     = 443 # Port range end
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow inbound HTTPS traffic from everywhere
  }

  ingress {
    description = "HTTP"
    from_port   = 80 # Port range start
    to_port     = 80 # Port range end
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow inbound HTTP traffic from everywhere
  }

  ingress {
    description = "SSH"
    from_port   = 22 # Port range start
    to_port     = 22 # Port range end
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow inbound HTTPS traffic from everywhere
  }

  egress {
    from_port   = 0 # All ports
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


# Create network interace
resource "aws_network_interface" "terraform-test-web-server-nic" {
  subnet_id       = aws_subnet.terraform-test-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# Create Elastic IP for network interface
resource "aws_eip" "terraform-test-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.terraform-test-web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.terraform-test-igw] # EIP Cannot be created before igw has been deployed
}


# Create Ubuntu EC2 instance for Web server
resource "aws_instance" "terraform-test-webserver-instnace" {
  ami               = "ami-00c90dbdc12232b58"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-1a"
  key_name          = "main-key" # Key-pair for SSH

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.terraform-test-web-server-nic.id
  }

  # Script to execute on first launch
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo "Hello from Web Server" > var/www/html/index.html'
              EOF
  tags = {
    Name = "terraform-test-webserver"
  }
}
