output "repository_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

output "api_image_uri" {
  value = "${aws_ecr_repository.ecr_repo.repository_url}:${local.api_image_name}"
}

output "app_image_uri" {
  value = "${aws_ecr_repository.ecr_repo.repository_url}:${local.app_image_name}"
}