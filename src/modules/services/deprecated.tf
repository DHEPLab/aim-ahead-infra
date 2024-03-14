resource "aws_security_group" "api_service_security_group" {
  name   = "${var.project_name}-api-task-sg-${var.env}"
  vpc_id = aws_vpc.vpc.id

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

  tags = {
    "deprecated" = true
  }
}
