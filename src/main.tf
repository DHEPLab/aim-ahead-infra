terraform {
  # backend "s3" {
  #   region         = var.region
  #   bucket         = "${var.proj_name}-tf-state-bucket-${var.env}"
  #   key            = "tf-infra/terraform.tfstate" 
  #   dynamodb_table = "${var.proj_name}-tf-state-locking-${var.env}"
  #   encrypt        = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}


module "tf-state" {
  source = "./modules/state"

  bucket_name    = "${var.proj_name}-tf-state-bucket-${var.env}"
  dynamodb_table = "${var.proj_name}-tf-state-locking-${var.env}"
}