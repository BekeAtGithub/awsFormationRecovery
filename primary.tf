provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

# VPC for us-east-1
resource "aws_vpc" "main_vpc_east" {
  provider  = aws.us-east-1
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc_us-east-1"
  }
}

# VPC for us-west-2
resource "aws_vpc" "main_vpc_west" {
  provider  = aws.us-west-2
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "main_vpc_us-west-2"
  }
}

# Subnet for us-east-1
resource "aws_subnet" "public_subnet_east" {
  provider           = aws.us-east-1
  vpc_id             = aws_vpc.main_vpc_east.id
  cidr_block         = "10.0.1.0/24"
  availability_zone  = data.aws_availability_zones.east.names[0]

  tags = {
    Name = "public_subnet_us-east-1"
  }
}

# Subnet for us-west-2
resource "aws_subnet" "public_subnet_west" {
  provider           = aws.us-west-2
  vpc_id             = aws_vpc.main_vpc_west.id
  cidr_block         = "10.1.1.0/24"
  availability_zone  = data.aws_availability_zones.west.names[0]

  tags = {
    Name = "public_subnet_us-west-2"
  }
}

# Internet Gateway for us-east-1
resource "aws_internet_gateway" "main_igw_east" {
  provider = aws.us-east-1
  vpc_id   = aws_vpc.main_vpc_east.id

  tags = {
    Name = "main_igw_us-east-1"
  }
}

# Internet Gateway for us-west-2
resource "aws_internet_gateway" "main_igw_west" {
  provider = aws.us-west-2
  vpc_id   = aws_vpc.main_vpc_west.id

  tags = {
    Name = "main_igw_us-west-2"
  }
}

# Route Table for us-east-1
resource "aws_route_table" "public_route_table_east" {
  provider = aws.us-east-1
  vpc_id   = aws_vpc.main_vpc_east.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw_east.id
  }

  tags = {
    Name = "public_route_table_us-east-1"
  }
}

# Route Table for us-west-2
resource "aws_route_table" "public_route_table_west" {
  provider = aws.us-west-2
  vpc_id   = aws_vpc.main_vpc_west.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw_west.id
  }

  tags = {
    Name = "public_route_table_us-west-2"
  }
}

# Route Table Association for us-east-1
resource "aws_route_table_association" "public_subnet_association_east" {
  provider       = aws.us-east-1
  subnet_id      = aws_subnet.public_subnet_east.id
  route_table_id = aws_route_table.public_route_table_east.id
}

# Route Table Association for us-west-2
resource "aws_route_table_association" "public_subnet_association_west" {
  provider       = aws.us-west-2
  subnet_id      = aws_subnet.public_subnet_west.id
  route_table_id = aws_route_table.public_route_table_west.id
}

# ECS Cluster for us-east-1
resource "aws_ecs_cluster" "ecs_cluster_east" {
  provider = aws.us-east-1
  name     = "ecs-cluster-us-east-1"
}

# ECS Cluster for us-west-2
resource "aws_ecs_cluster" "ecs_cluster_west" {
  provider = aws.us-west-2
  name     = "ecs-cluster-us-west-2"
}

# Security Group for us-east-1
resource "aws_security_group" "allow_all_east" {
  provider = aws.us-east-1
  vpc_id   = aws_vpc.main_vpc_east.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all_us-east-1"
  }
}

# Security Group for us-west-2
resource "aws_security_group" "allow_all_west" {
  provider = aws.us-west-2
  vpc_id   = aws_vpc.main_vpc_west.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all_us-west-2"
  }
}

# ECS Service for us-east-1
resource "aws_ecs_service" "node_service_east" {
  provider         = aws.us-east-1
  name             = "node-service-us-east-1"
  cluster          = aws_ecs_cluster.ecs_cluster_east.id
  task_definition  = aws_ecs_task_definition.node_task_east.arn
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet_east.id]
    security_groups = [aws_security_group.allow_all_east.id]
    assign_public_ip = true
  }
}

# ECS Service for us-west-2
resource "aws_ecs_service" "node_service_west" {
  provider         = aws.us-west-2
  name             = "node-service-us-west-2"
  cluster          = aws_ecs_cluster.ecs_cluster_west.id
  task_definition  = aws_ecs_task_definition.node_task_west.arn
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet_west.id]
    security_groups = [aws_security_group.allow_all_west.id]
    assign_public_ip = true
  }
}

# ECR Repository (shared)
resource "aws_ecr_repository" "node_app_repo" {
  name = "node-app"
}

# ECS Task Definition for us-east-1
resource "aws_ecs_task_definition" "node_task_east" {
  provider                = aws.us-east-1
  family                  = "node-app-task-us-east-1"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = "256"
  memory                  = "512"
  execution_role_arn      = aws_iam_role.ecs_task_execution_role_east.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "node-app",
    "image": "${aws_ecr_repository.node_app_repo.repository_url}:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
DEFINITION
}

# ECS Task Definition for us-west-2
resource "aws_ecs_task_definition" "node_task_west" {
  provider                = aws.us-west-2
  family                  = "node-app-task-us-west-2"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = "256"
  memory                  = "512"
  execution_role_arn      = aws_iam_role.ecs_task_execution_role_west.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "node-app",
    "image": "${aws_ecr_repository.node_app_repo.repository_url}:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
DEFINITION
}


# IAM Role for us-east-1
resource "aws_iam_role" "ecs_task_execution_role_east" {
  name = "ecsTaskExecutionRole-us-east-1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# IAM Role for us-west-2
resource "aws_iam_role" "ecs_task_execution_role_west" {
  name = "ecsTaskExecutionRole-us-west-2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# IAM Role Policy Attachment for both regions
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_east" {
  role       = aws_iam_role.ecs_task_execution_role_east.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_west" {
  role       = aws_iam_role.ecs_task_execution_role_west.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_availability_zones" "east" {
  provider = aws.us-east-1
}

data "aws_availability_zones" "west" {
  provider = aws.us-west-2
}

output "primary_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster_east.name
}

output "secondary_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster_west.name
}

output "primary_subnet_ids" {
  value = aws_subnet.public_subnet_east.id
}

output "secondary_subnet_ids" {
  value = aws_subnet.public_subnet_west.id
}

output "primary_security_group_ids" {
  value = aws_security_group.allow_all_east.id
}

output "secondary_security_group_ids" {
  value = aws_security_group.allow_all_west.id
}

output "primary_vpc_id" {
  value = aws_vpc.main_vpc_east.id
}

output "secondary_vpc_id" {
  value = aws_vpc.main_vpc_west.id
}
