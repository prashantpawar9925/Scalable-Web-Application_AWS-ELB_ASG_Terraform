#To create VPC

resource aws_vpc "vpc1"{
 cidr_block = "10.0.0.0/24"
 
 tags={
  Name="TF_prashant_vpc"
 }
}

#public Subnet

resource aws_subnet "sn1"{
 vpc_id=aws_vpc.vpc1.id
 cidr_block="10.0.0.0/25"
 availability_zone="ap-southeast-1a"
 map_public_ip_on_launch = true
 tags={
  Name="TF_pub"
 }
}

#private subnet

resource aws_subnet "sn2"{
 vpc_id=aws_vpc.vpc1.id
 cidr_block="10.0.0.128/25"
 availability_zone="ap-southeast-1b"
 
 tags={
  Name="TF_pvt"
 }
}

#internet gateway

resource "aws_internet_gateway" "igw"{
 vpc_id = aws_vpc.vpc1.id
 
 
 tags = {
  Name = "TF_IGW"
 }
}

#To create route table for public 

resource "aws_route_table" "rt1"{
 vpc_id = aws_vpc.vpc1.id
 tags = {
  Name = "TF_PUB_RT"
 }
}

#To create route table for private
 
resource "aws_route_table" "rt2"{
 vpc_id = aws_vpc.vpc1.id
 tags = {
  Name = "TF_PVT_RT"
 }
}

#To attach internet gateway to vpc1

resource "aws_route" "addigw"{
 route_table_id = aws_route_table.rt1.id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.igw.id
}

#To attach route table to public subnet

resource "aws_route_table_association" "sn1rt1"{
 subnet_id = aws_subnet.sn1.id
 route_table_id = aws_route_table.rt1.id
}

#To attach route table to private subnet

resource "aws_route_table_association" "sn2rt2"{
 subnet_id = aws_subnet.sn2.id
 route_table_id = aws_route_table.rt2.id
}

#To create security group

resource "aws_security_group" "sg1"{
 vpc_id = aws_vpc.vpc1.id
 name        = "TFSG1"
 description = "TFSG1"
 ingress {
    description      = "Allow incoming request"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   
  }
  ingress {
    description      = "Allow incoming request"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  tags = {
   Name = "TF_SG" 
  }

}

# To create key pair

resource "aws_key_pair" "prashant" {
  key_name   = "prashant"
  public_key = file("./prashant.pub")
}

#To launch instance and install apache in it.

resource aws_instance "i1"{
 count=2
 ami="ami-047126e50991d067b"
 instance_type="t2.micro"
 subnet_id=aws_subnet.sn1.id
 vpc_security_group_ids=[aws_security_group.sg1.id]
 key_name="prashant"
 user_data=file("./web.sh")
 tags={
  Name="TF_Webserver_${count.index + 1}"
  Env="Prod"
 }

}


# create Security Group for ELB

resource aws_security_group "elb_sg"{
 vpc_id = aws_vpc.vpc1.id
 name        = "TF_AELB_SG1"
 description = "TF_AELB_SG1"
 
  ingress {
    description      = "Allow incoming request"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  tags = {
   Name = "TF_AELB_SG" 
  }

}

# To create Application Load Balancer
resource "aws_lb" "web_elb" {
  name               = "web-AELB-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = [aws_subnet.sn1.id,aws_subnet.sn2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# To create a Target Group
resource "aws_lb_target_group" "web_TG" {
  name     = "web-AELB-tf-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id
  
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  } 
}

# Listener for ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_elb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_TG.arn
  }
}

# Target group attachment
resource "aws_lb_target_group_attachment" "test_TG" {
  count            = length(aws_instance.i1)
  target_group_arn = aws_lb_target_group.web_TG.arn
  target_id        = aws_instance.i1[count.index].id
  port             = 80
}


# To create launch_template

resource "aws_launch_template" "temp" {
  
  name = "TF_template"
  
  image_id="ami-047126e50991d067b"
  instance_type="t2.micro"
  vpc_security_group_ids=[aws_security_group.sg1.id]
  key_name= "prashant"
  
  user_data=filebase64("${path.module}/web.sh")
  
  tags={
   Name="TF_ln_tmp"
  }
}

# To Create Auto Scaling Group and attach to AELB

resource aws_autoscaling_group "ASG"{
 name = "ASG_1"
 launch_template {
    id      = aws_launch_template.temp.id
    version = "$Latest"
  }
 
 vpc_zone_identifier = [aws_subnet.sn1.id]
  desired_capacity   = 1
  max_size           = 5
  min_size           = 1
  
  tag {
    key                 = "Name"
    value               = "ASG_TF"
    propagate_at_launch = true
  }
 
}

# To attach ELB to Auto scaling group

resource aws_autoscaling_attachment "elb-as"{
 
 autoscaling_group_name = aws_autoscaling_group.ASG.id
 lb_target_group_arn    = aws_lb_target_group.web_TG.arn
 
}

# To Show the AELB DNS Name
output "AELB_dns" {
  value = aws_lb.web_elb.dns_name
}

