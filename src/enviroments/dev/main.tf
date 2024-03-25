terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "aim-ahead-tf-state-bucket-dev"
    key            = "tf-infra/terraform.tfstate"
    dynamodb_table = "aim-ahead-tf-state-locking-dev"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Environment = local.environment
      project     = local.project_name
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.project_name}-ecs-task-executor-${local.environment}"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

module "tf-state" {
  source = "../../modules/state"

  bucket_name    = "aim-ahead-tf-state-bucket-dev"
  dynamodb_table = "aim-ahead-tf-state-locking-dev"
}

module "service" {
  source = "../../modules/services"

  env                     = local.environment
  project_name            = local.project_name
  api_image_uri           = module.repository.api_image_uri
  app_image_uri           = module.repository.app_image_uri
  task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

module "repository" {
  source = "../../modules/repository"

  project_name = local.project_name
}

module "db" {
  source = "../../modules/db"

  env                            = local.environment
  project_name                   = local.project_name
  vpc_id                         = module.service.vpc_id
  subnet_ids                     = [module.service.private_subnet_1_id, module.service.private_subnet_2_id]
  from_subnet_cidr_blocks        = [module.service.private_subnet_1_cidr_block, module.service.private_subnet_2_cidr_block]
  bastion_host_subnet_cidr_block = module.service.public_subnet_1_cidr_block
  bastion_host_subnet_id         = module.service.public_subnet_1_id
}
