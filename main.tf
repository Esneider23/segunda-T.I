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

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
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
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "segunda_Ti" {
  name        = "Segunda-TI"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "SEGUNDA" {
  load_balancer_arn = aws_lb.default.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.segunda_Ti.id
    type             = "forward"
  }
}

resource "aws_security_group" "security_task" {
  name        = "example-task-security-group"
  vpc_id      = aws_vpc.default.id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "ecr_policy"
  description = "Permissions for accessing ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:GetRegistryCatalogData",
          "ecr:ListImages",
          "ecr:DescribeImages",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  policy_arn = aws_iam_policy.ecr_policy.arn
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_ecs_task_definition" "TI" {
  family                   = "Segunda_ti"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  

  container_definitions = <<DEFINITION
[
  {
    "image": "244410002174.dkr.ecr.us-east-1.amazonaws.com/t.i/segunda-actividad:${var.imagebuild}",
    "cpu": 1024,
    "memory": 2048,
    "name": "Segunda_ti",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_cluster" "main" {
  name = "example-cluster"
}

resource "aws_ecs_service" "Segunda_TI" {
  name            = "net-aplication"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.TI.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.security_task.id]
    subnets         = aws_subnet.private.*.id
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.segunda_Ti.id
    container_name = "Segunda_ti"
    container_port  = 3000
  }
  depends_on = [aws_lb_listener.SEGUNDA]
}

output "load_balancer_ip" {
  value = aws_lb.default.dns_name
}