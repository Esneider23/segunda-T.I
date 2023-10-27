terraform {
     required_providers{
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.16"
        }
    }
    backend "s3" {
        bucket         = "rgterraform"
        key            = "tfstatesdevops/terraform.tfstate"
    }
}

variable "imagebuild" {
  type = string
  description = "the latest image build version"
}

variable "app_count" {
  type = number
  default = 1
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}


resource "aws_ecs_cluster" "my_cluster" {
  name = "ACTIVIDAD-TI" 
}

data "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-first-task" 
  container_definitions    = <<DEFINITION
  [
    {
      "name": "app-first-task",
      "image": "244410002174.dkr.ecr.us-east-1.amazonaws.com/t.i/segunda-actividad:${var.imagebuild}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn 
}

resource "aws_vpc" "default" {
    cidr_block = "10.32.0.0/16"
}

resource "aws_subnet" "public" {
    count                   = 2
    cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, 2 + count.index)
    availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
    vpc_id                  = aws_vpc.default.id
    map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.default.id
}

resource "aws_security_group" "lb" {
  name        = "example-alb-security-group"
  vpc_id      = aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "default" {
  name            = "example-lb"
  load_balancer_type = "application"
  subnets         = [
    aws_subnet.public.*.id,
    aws_subnet.private.*.id
  ]
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "target_group" {
  name        = "Segunda-TI"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.default.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.segunda_Ti.id
    type             = "forward"
  }
}








