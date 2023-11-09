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
