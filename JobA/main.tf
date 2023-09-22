terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			}
		}

}
provider "aws" {
	region = "us-east-1"
}
resource "aws_vpc" "JobA-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "JobA-VPC"
        }
}
resource "aws_subnet" "JobA-SUBNET-PUBLIC" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "JobA-SUBNET-PUBLIC"
        }
}
resource "aws_subnet" "JobA-SUBNET-AZ-A" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone = "us-east-1a"
        tags = {
                Name = "JobA-SUBNET-AZ-A"
        }
}
resource "aws_subnet" "JobA-SUBNET-AZ-B" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        cidr_block = "10.0.3.0/24"
        availability_zone = "us-east-1b"
        tags = {
                Name = "JobA-SUBNET-AZ-B"
        }
}
resource "aws_subnet" "JobA-SUBNET-AZ-C" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone = "us-east-1c"
        tags = {
                Name = "JobA-SUBNET-AZ-C"
        }
}
resource "aws_internet_gateway" "JobA-IGW" {
        tags = {
                Name = "JobA-IGW"
        }
}
resource "aws_internet_gateway_attachment" "JobA-IGW-ATTACH" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.JobA-IGW.id}"
}
resource "aws_route_table" "JobA-RTB-PUBLIC" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        route {
                cidr_block = "0.0.0.0/0"
                gateway_id = "${aws_internet_gateway.JobA-IGW.id}"
        }
        tags = {
                Name = "JobA-RTB-PUBLIC"
        }
}
resource "aws_route_table_association" "JobA-RTB-PUBLIC-ASSOC1" {
        subnet_id = "${aws_subnet.JobA-SUBNET-AZ-A.id}"
        route_table_id = "${aws_route_table.JobA-RTB-PUBLIC.id}"
}
resource "aws_route_table_association" "JobA-RTB-PUBLIC-ASSOC2" {
        subnet_id = "${aws_subnet.JobA-SUBNET-AZ-B.id}"
        route_table_id = "${aws_route_table.JobA-RTB-PUBLIC.id}"
}
resource "aws_route_table_association" "JobA-RTB-PUBLIC-ASSOC3" {
        subnet_id = "${aws_subnet.JobA-SUBNET-AZ-C.id}"
        route_table_id = "${aws_route_table.JobA-RTB-PUBLIC.id}"
}
resource "aws_route_table_association" "JobA-RTB-PUBLIC-ASSOC" {
        subnet_id = "${aws_subnet.JobA-SUBNET-PUBLIC.id}"
        route_table_id = "${aws_route_table.JobA-RTB-PUBLIC.id}"
}
resource "aws_security_group" "JobA-SG-PUBLIC" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        ingress {
                from_port = "22"
                to_port = "22"
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        ingress {
                from_port = "3128"
                to_port = "3128"
                protocol = "tcp"
                security_groups = ["${aws_security_group.JobA-SG-WEB.id}"]
        }
        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "JobA-SG-PUBLIC"
        }
}
resource "aws_security_group" "JobA-SG-LOAD-BALANCER" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        ingress {
                from_port = "80"
                to_port = "80"
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "JobA-SG-LOAD-BALANCER"
        }
}
resource "aws_security_group" "JobA-SG-WEB" {
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        ingress {
                from_port = "22"
                to_port = "22"
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        ingress {
                from_port = "80"
                to_port = "80"
                protocol = "tcp"
                security_groups = ["${aws_security_group.JobA-SG-LOAD-BALANCER.id}"]
        }
        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "JobA-SG-PUBLIC"
        }
}
resource "aws_instance" "JobA-INSTANCE-PUBLIC" {
        subnet_id = "${aws_subnet.JobA-SUBNET-PUBLIC.id}"
        instance_type = "t2.micro"
        ami = "ami-03a6eaae9938c858c"
        key_name = "vockey"
        vpc_security_group_ids = ["${aws_security_group.JobA-SG-PUBLIC.id}"]
        associate_public_ip_address = true
        user_data = file("squid.sh")
        tags = {
                Name = "JobA-INSTANCE-PUBLIC"
        }
}
resource "aws_instance" "JobA-INSTANCE-AZ-A" {
        subnet_id = "${aws_subnet.JobA-SUBNET-AZ-A.id}"
        instance_type = "t2.micro"
        ami = "ami-03a6eaae9938c858c"
        key_name = "vockey"
        vpc_security_group_ids = ["${aws_security_group.JobA-SG-WEB.id}"]
        associate_public_ip_address = false
        user_data = "${templatefile("web.sh", { SQUID_IP = "${aws_instance.JobA-INSTANCE-PUBLIC.private_ip}" })}"
        tags = {
                Name = "JobA-INSTANCE-AZ-A"
        }
}
resource "aws_instance" "JobA-INSTANCE-AZ-B" {
        subnet_id = "${aws_subnet.JobA-SUBNET-AZ-B.id}"
        instance_type = "t2.micro"
        ami = "ami-03a6eaae9938c858c"
        key_name = "vockey"
        vpc_security_group_ids = ["${aws_security_group.JobA-SG-WEB.id}"]
        associate_public_ip_address = false
        user_data = "${templatefile("web.sh", { SQUID_IP = "${aws_instance.JobA-INSTANCE-PUBLIC.private_ip}" })}"
        tags = {
                Name = "JobA-INSTANCE-AZ-B"
        }
}
resource "aws_instance" "JobA-INSTANCE-AZ-C" {
        subnet_id = "${aws_subnet.JobA-SUBNET-AZ-C.id}"
        instance_type = "t2.micro"
        ami = "ami-03a6eaae9938c858c"
        key_name = "vockey"
        vpc_security_group_ids = ["${aws_security_group.JobA-SG-WEB.id}"]
        associate_public_ip_address = false
        user_data = "${templatefile("web.sh", { SQUID_IP = "${aws_instance.JobA-INSTANCE-PUBLIC.private_ip}" })}"
        tags = {
                Name = "JobA-INSTANCE-AZ-C"
        }
}
resource "aws_lb" "JobA-LB" {
        name = "JobA-LB"
        subnets = ["${aws_subnet.JobA-SUBNET-AZ-A.id}", "${aws_subnet.JobA-SUBNET-AZ-B.id}", "${aws_subnet.JobA-SUBNET-AZ-C.id}"]
        security_groups = ["${aws_security_group.JobA-SG-LOAD-BALANCER.id}"]
}
resource "aws_lb_target_group" "JobA-LB-TG2" {
        name = "JobA-LB-TG2"
        port = 80
        protocol = "HTTP"
        vpc_id = "${aws_vpc.JobA-VPC.id}"
        target_type = "instance"
}
resource "aws_lb_target_group_attachment" "JobA-LB-TG2-ATTACH-1" {
        target_group_arn = "${aws_lb_target_group.JobA-LB-TG2.arn}"
        target_id = "${aws_instance.JobA-INSTANCE-AZ-A.id}"
        port = 80
}
resource "aws_lb_target_group_attachment" "JobA-LB-TG2-ATTACH-2" {
        target_group_arn = "${aws_lb_target_group.JobA-LB-TG2.arn}"
        target_id = "${aws_instance.JobA-INSTANCE-AZ-B.id}"
        port = 80
}
resource "aws_lb_target_group_attachment" "JobA-LB-TG2-ATTACH-3" {
        target_group_arn = "${aws_lb_target_group.JobA-LB-TG2.arn}"
        target_id = "${aws_instance.JobA-INSTANCE-AZ-C.id}"
        port = 80
}
resource "aws_lb_listener" "JobA-LB-LISTENER" {
        load_balancer_arn = "${aws_lb.JobA-LB.arn}"
        port = "80"
        protocol = "HTTP"
        default_action {
                type = "forward"
                target_group_arn = "${aws_lb_target_group.JobA-LB-TG2.arn}"
        }
}
