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
