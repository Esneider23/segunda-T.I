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








