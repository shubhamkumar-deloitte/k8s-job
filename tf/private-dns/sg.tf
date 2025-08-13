###############
# sg.tf
###############

# security group
resource "aws_security_group" "resolver" {
  name   = join("-", [var.resolver_endpoint_name, "resolver"])
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = toset(var.ingress_security_groups)

    content {
      from_port       = 53
      to_port         = 53
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.ingress_security_groups)

    content {
      from_port       = 53
      to_port         = 53
      protocol        = "udp"
      security_groups = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.ingress_cidr_blocks)

    content {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.ingress_cidr_blocks)

    content {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = var.tags
}
