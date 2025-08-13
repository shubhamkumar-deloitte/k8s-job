###############
# resolver.tf
###############

# route53 resolver inbound endpoint
resource "aws_route53_resolver_endpoint" "this" {
  name               = var.resolver_endpoint_name
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.resolver.id]

  dynamic "ip_address" {
    for_each = toset(var.subnets)

    content {
      subnet_id = ip_address.value
    }
  }

  tags = var.tags
}
