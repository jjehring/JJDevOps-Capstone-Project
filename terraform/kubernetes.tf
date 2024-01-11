variable "aws_region" {

        default = "us-east-1"

}



variable "vpc_cidr" {

        default = "10.20.0.0/16"

}



variable "subnets_cidr" {

        default = "10.20.1.0/24"

}



variable "azs" {

        default = "us-east-1a"

}





provider "aws" {

        region = var.aws_region  

       access_key = "AKIAZCS4MXJO4OQ62A33"



       secret_key = "zGlG4ZgypW+f8rWRFephSm6Q6WbiyH1zRcCwl8ir"



	

}





# VPC

resource "aws_vpc" "terra_vpc" {

  cidr_block       = var.vpc_cidr

  tags = {

    Name = "TerraVPC"

  }

}



# Internet Gateway

resource "aws_internet_gateway" "terra_igw" {

  vpc_id = aws_vpc.terra_vpc.id

  tags = {

    Name = "main"

  }

}



# Subnets : public

resource "aws_subnet" "public" {

  vpc_id = aws_vpc.terra_vpc.id

  cidr_block = var.subnets_cidr

  availability_zone = var.azs

  map_public_ip_on_launch = true

  tags = {

    Name = "Subnet"

  }

}



# Route table: attach Internet Gateway 

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.terra_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.terra_igw.id

  }

  tags = {

    Name = "publicRouteTable"

  }

}



# Route table association with public subnets

resource "aws_route_table_association" "a" {

  subnet_id      = aws_subnet.public.id

  route_table_id = aws_route_table.public_rt.id

}





resource "aws_security_group" "my_security_group" {

  name = "mysg"

  description = "my security group."

  vpc_id = aws_vpc.terra_vpc.id

}



resource "aws_security_group_rule" "ssh_ingress_access" {

  type = "ingress"

  from_port = 22

  to_port = 22

  protocol = "tcp"

  cidr_blocks = [ "0.0.0.0/0" ] 

  security_group_id = "${aws_security_group.my_security_group.id}"

}



resource "aws_security_group_rule" "egress_access" {

  type = "egress"

  from_port = 0

  to_port = 65535

  protocol = "tcp"

  cidr_blocks = [ "0.0.0.0/0" ]

  security_group_id = "${aws_security_group.my_security_group.id}"

}



data "aws_ami" "latest-ubuntu" {

most_recent = true



  filter {

      name   = "name"

      values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230517"]

  }



  filter {

      name   = "virtualization-type"

      values = ["hvm"]

  }

}





resource "aws_launch_configuration" "aws_autoscale_conf" {

  name          = "web_config"

  image_id      = "${data.aws_ami.latest-ubuntu.id}"

  instance_type = "t2.micro"

  security_groups =  [ "${aws_security_group.my_security_group.id}" ]

}





resource "aws_autoscaling_group" "mygroup" {

#  availability_zones        =  ["${var.azs}"]

  name                      = "autoscalegroup"

  max_size                  = 1

  min_size                  = 1

  health_check_grace_period = 30

  health_check_type         = "EC2"

 force_delete              = true

  vpc_zone_identifier       = ["${aws_subnet.public.id}"]

  termination_policies      = ["OldestInstance"]

  launch_configuration      = aws_launch_configuration.aws_autoscale_conf.name

}
