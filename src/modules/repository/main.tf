terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_ecr_repository" "ecr_repo" {
  name = "${var.project_name}-repository"

  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "aim_ahead_api_repo" {
  name = local.api_image_name
  #trivy:ignore:avd-aws-0031
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = ""
  }
}


resource "aws_ecr_repository" "aim_ahead_app_repo" {
  name = local.app_image_name
  #trivy:ignore:avd-aws-0031
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = ""
  }
}
