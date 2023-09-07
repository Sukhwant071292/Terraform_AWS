provider "aws" {
  region = "us-east-1"
  access_key = "*****************"
  secret_key = "*****************"

}
#Creating VPC
resource "aws_vpc" "first_vpc"{
    cidr_block= "10.0.0.0/16"
    tags={
        Name= "MyVPC" 
    }
}
#Creating Internet gateway
resource "aws_internet_gateway" "gw"{
    vpc_id = aws_vpc.first_vpc.id
}
#Creating Route table
resource "aws_route_table" "first_vpc_route_table" {
  vpc_id = aws_vpc.first_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
   ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "first_vpc_route_table"
  }
}
#Creating Subnet
resource "aws_subnet" "first_subnet" {
    vpc_id = aws_vpc.first_vpc.id
    cidr_block="10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags={
        Name="first_subnet"
    }
  
}
#Associate Subnet with Route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.first_subnet.id
  route_table_id = aws_route_table.first_vpc_route_table.id
}

#For security groups
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.first_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_Web"
  }
}
#Creating network Interface
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.first_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}
#Assigning Elastiv Ip
resource "aws_eip" "One" {
    vpc =true
    network_interface = aws_network_interface.test.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [ aws_internet_gateway.gw ]

}
#Creating an instance
resource "aws_instance" "Web_Server"{
    ami ="ami-051f7e7f6c2f40dc1"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.test.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y 
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c'echo your very first webserver > /var/www/html/index.html' 
                EOF

                tags = {
                  Name= "MyWebServer"
                }

}
