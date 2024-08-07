resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster-${var.env}"
}

resource "aws_secretsmanager_secret" "jwt_key" {
  name        = "${var.project_name}-secretsmanager-${var.env}"
  description = "JWT Key for generate access token"
}

resource "aws_secretsmanager_secret_version" "jwt_key_version" {
  secret_id     = aws_secretsmanager_secret.jwt_key.id
  secret_string = random_password.jwt_key.result
}

resource "aws_secretsmanager_secret" "database_url_key" {
  name        = "${var.project_name}-database-url-${var.env}"
  description = "database url"
}

resource "aws_secretsmanager_secret_version" "database_url_key_version" {
  secret_id     = aws_secretsmanager_secret.database_url_key.id
  secret_string = var.database_url
}

data "aws_secretsmanager_secret" "aws_access_key_id" {
  name = "aws-access-key-id"
}

data "aws_secretsmanager_secret_version" "aws_access_key_id_version" {
  secret_id = data.aws_secretsmanager_secret.aws_access_key_id.id
}

data "aws_secretsmanager_secret" "aws_secret_access_key" {
  name = "aws-secret-access-key"
}

data "aws_secretsmanager_secret_version" "aws_secret_access_key_version" {
  secret_id = data.aws_secretsmanager_secret.aws_secret_access_key.id
}


resource "aws_ecs_task_definition" "api_task" {
  family                   = "${var.project_name}-api-task-${var.env}"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.project_name}-api-task-${var.env}",
      "image": "${var.api_image_uri}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${local.api_container_binding_port},
          "hostPort": ${local.api_container_binding_port}
        }
      ],
      "memory": 512,
      "cpu": 256,
      "secrets": [
          {
              "name":"JWT_SECRET_KEY",
              "valueFrom":  "${aws_secretsmanager_secret.jwt_key.arn}"
          },
          {
              "name":"DATABASE_URL",
              "valueFrom":  "${aws_secretsmanager_secret.database_url_key.arn}"
          },
          {
              "name":"AWS_ACCESS_KEY_ID",
              "valueFrom":  "${data.aws_secretsmanager_secret_version.aws_access_key_id_version.arn}:aws-access-key-id::"
          },
          {
              "name":"AWS_SECRET_ACCESS_KEY",
              "valueFrom":  "${data.aws_secretsmanager_secret_version.aws_secret_access_key_version.arn}:aws-secret-access-key::"
          }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/fargate/service/${var.project_name}-${var.env}",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-app-task-${var.env}"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.project_name}-app-task-${var.env}",
      "image": "${var.app_image_uri}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${local.app_container_binding_port},
          "hostPort": ${local.app_container_binding_port}
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
}

#trivy:ignore:AVD-AWS-0053
resource "aws_lb" "application_load_balancer" {
  name                       = "${var.project_name}-lb-${var.env}"
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
  ]
  security_groups = [aws_security_group.load_balancer_security_group.id]
}

resource "aws_security_group" "load_balancer_security_group" {
  name   = "${var.project_name}-lb-sg-${var.env}"
  vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.env == "prod" ? [80, 443] : [80, 443, 8000]
    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
      # trivy:ignore:avd-aws-0107
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # trivy:ignore:avd-aws-0104
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "api_target_group" {
  name        = "${var.project_name}-api-target-group-${var.env}"
  port        = local.api_container_binding_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/api/healthcheck"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "8000"
  # trivy:ignore:avd-aws-0054
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target_group.arn
  }
}

resource "aws_lb_target_group" "app_target_group" {
  name        = "${var.project_name}-app-target-group-${var.env}"
  port        = local.app_container_binding_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold = "3"
    interval          = "30"
    protocol          = "HTTP"
    matcher           = "200"
    timeout           = "3"
    path              = "/"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  # trivy:ignore:avd-aws-0054
  protocol = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "app_listener_tls" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

resource "aws_lb_listener_rule" "app_forward_listener" {
  listener_arn = aws_lb_listener.app_listener_tls.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  tags = {
    name = "${var.project_name}-app-forward-${var.env}"
  }
}

resource "aws_lb_listener_rule" "admin_api_lb_listener_rule" {
  listener_arn = aws_lb_listener.app_listener_tls.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/admin/*"]
    }
  }

  condition {
    http_header {
      http_header_name = "X-API-KEY"
      values           = [random_string.admin_api_key.result]
    }
  }

  tags = {
    name = "${var.project_name}-admin-api-forward-${var.env}"
  }

}

resource "aws_ecs_service" "api_service" {
  name            = "${var.project_name}-api-service-${var.env}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.api_target_group.arn
    container_name   = "${var.project_name}-api-task-${var.env}"
    container_port   = local.api_container_binding_port
  }

  network_configuration {
    subnets = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_service_security_group.id]
  }
}

resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-app-service-${var.env}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name   = "${var.project_name}-app-task-${var.env}"
    container_port   = local.app_container_binding_port
  }

  network_configuration {
    subnets = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_service_security_group.id]
  }
}

# Application Serurity Group
resource "aws_security_group" "ecs_service_security_group" {
  name   = "${var.project_name}-ecs-service-sg-${var.env}"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = local.api_container_binding_port
    to_port         = local.api_container_binding_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    from_port       = local.app_container_binding_port
    to_port         = local.app_container_binding_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # trivy:ignore:avd-aws-0104
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_string" "admin_api_key" {
  length           = 8
  special          = true
  override_special = "@#$_="
}

resource "random_password" "jwt_key" {
  length  = 32
  special = true
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/fargate/service/${var.project_name}-${var.env}"
  retention_in_days = 30
}