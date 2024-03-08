resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "${var.project_name}-db-subnet-group-${var.env}"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.env}"
  }
}

resource "aws_security_group" "database_security_group" {
  name   = "${var.project_name}-db-security-group-${var.env}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.from_subnet_cidr_blocks
  }

  tags = {
    Name = "${var.project_name}-db-security-group-${var.env}"
  }
}

resource "aws_db_parameter_group" "database_parameter" {
  name   = "aim-ahead"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "database" {
  identifier            = "masterdb${var.env}"
  instance_class        = "db.t4g.large"
  allocated_storage     = 20
  max_allocated_storage = 100
  engine                = "postgres"
  engine_version        = "14"

  db_name  = "aimahead${var.env}"
  username = "aim_ahead"
  password = random_password.password.result

  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  storage_encrypted      = true

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 1
  skip_final_snapshot     = true

  parameter_group_name = aws_db_parameter_group.database_parameter.name
}

resource "aws_db_instance" "database_replica" {
  identifier             = "replicadb${var.env}"
  replicate_source_db    = aws_db_instance.database.identifier
  instance_class         = "db.t4g.large"
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  parameter_group_name   = aws_db_parameter_group.database_parameter.name

  maintenance_window              = "Tue:00:00-Tue:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 0
  skip_final_snapshot     = true

  lifecycle {
    ignore_changes = [storage_encrypted, max_allocated_storage]
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
