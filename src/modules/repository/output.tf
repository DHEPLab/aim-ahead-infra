output "api_image_uri" {
  value = aws_ecr_repository.aim_ahead_api_repo.repository_url
}

output "app_image_uri" {
  value = aws_ecr_repository.aim_ahead_app_repo.repository_url
}
