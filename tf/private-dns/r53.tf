###############
# r53.tf
###############

# private hosted zone

resource "aws_route53_zone" "this" {
  name = var.hosted_zone

  vpc {
    vpc_id = var.vpc_id
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [vpc]
  }
}
