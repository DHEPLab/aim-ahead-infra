resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster-${var.env}"
}

resource "aws_ecs_task_definition" "api_task" {
  family                   = "${var.project_name}-task-family-${var.env}"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.project_name}-api-task-${var.env}",
      "image": "${var.api_image_uri}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000
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
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-executor-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    # trivy:ignore:avd-aws-0107
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    # trivy:ignore:avd-aws-0107
    cidr_blocks = ["0.0.0.0/0"]
  }
  # APP entrypoint
  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    # trivy:ignore:avd-aws-0107
    cidr_blocks = ["0.0.0.0/0"]
  }
  # API entrypoint
  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    # trivy:ignore:avd-aws-0107
    cidr_blocks = ["0.0.0.0/0"]
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
  port        = "5000"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
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

resource "aws_ecs_service" "api_service" {
  name            = "${var.project_name}-api-service-${var.env}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.api_target_group.arn
    container_name   = "${var.project_name}-api-task-${var.env}"
    container_port   = "5000"
  }

  network_configuration {
    subnets = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.api_service_security_group.id]
  }
}

resource "aws_security_group" "api_service_security_group" {
  ingress {
    from_port       = 5000
    to_port         = 5000
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