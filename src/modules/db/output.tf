output "database_url" {
  value     = "postgresql://${aws_db_instance.database.username}:${aws_db_instance.database.password}@${aws_db_instance.database.address}:${aws_db_instance.database.port}/${aws_db_instance.database.db_name}"
  sensitive = true
}