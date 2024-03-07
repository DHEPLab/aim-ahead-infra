output "api_repository_url" {
  value = aws_ecr_repository.api_ecr_repo.repository_url
}

output "app_repository_url" {
  value = aws_ecr_repository.app_ecr_repo.repository_url
}