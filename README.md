## Project : A Simple Scalable web application using AWS ELB and Auto Scaling Group with Terraform.

# Architecture Diagram :
![ELB and ASG Architecture](https://github.com/user-attachments/assets/609af09a-20d8-44b0-8a02-8e549ca21db1)

# Problem Statement :
There is an ABC client they have. An online retail business faced performance issues during peak traffic, leading to slow response times and occasional downtime.
They required a scalable and highly available solution to handle unpredictable traffic spikes and ensure optimal performance.


# Solution :
To Implement AWS Elastic Load Balancer (ELB) and Auto Scaling Group (ASG) to create a fault-tolerant and scalable web application.

1) AWS Elastic Load Balancer (ELB):  To distribute incoming traffic across EC2 Instance for optimal performance.

2) Auto Scaling Group (ASG): Automatically adjusted the number of EC2 instances based on traffic.


# Terraform : 
Terraform used to provision infrastructure as code (IaC), significantly reducing manual effort and deployment time.
Manually creating resources such as VPC, EC2 instances, ELB, and ASG took over 30 minutes.
Using Terraform, all resources were provisioned in under a minute.
