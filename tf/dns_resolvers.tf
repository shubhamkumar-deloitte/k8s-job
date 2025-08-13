##################
# Security Groups
##################
resource "aws_security_group" "route53_resolver" {
  vpc_id = module.vpc.vpc_id
  tags                 = jsondecode(var.mandatory_tags)
}


resource "aws_security_group" "secondary_route53_resolver" {
  provider = aws.secondary
  vpc_id   = module.secondary_vpc.vpc_id
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_security_group_rule" "aws_central_outbound_dns_udp" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.route53_resolver.id
}

resource "aws_security_group_rule" "secondary_aws_central_outbound_dns_udp" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.secondary_route53_resolver.id
}

resource "aws_security_group_rule" "aws_central_outbound_dns_tcp" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.route53_resolver.id
}

resource "aws_security_group_rule" "secondary_aws_central_outbound_dns_tcp" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.secondary_route53_resolver.id
}

####################
# Route53 Resolvers
####################
resource "aws_route53_resolver_endpoint" "central_outbound_dns" {
  name      = "core-shared-services-vpc"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.route53_resolver.id,
  ]

  dynamic "ip_address" {
    for_each = module.vpc.private_subnets
    content {
      subnet_id = ip_address.value
    }
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_endpoint" "secondary_central_outbound_dns" {
  provider  = aws.secondary
  name      = "core-shared-services-vpc"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.secondary_route53_resolver.id,
  ]

  dynamic "ip_address" {
    for_each = module.secondary_vpc.private_subnets
    content {
      subnet_id = ip_address.value
    }
  }
  tags                 = jsondecode(var.mandatory_tags)
}

#################
# Resolver Rules
#################
resource "aws_route53_resolver_rule" "corp_svbank" {
  domain_name          = "corp.svbank.com"
  name                 = "corp-svbank"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_corp_svbank" {
  provider             = aws.secondary
  domain_name          = "corp.svbank.com"
  name                 = "corp-svbank"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "corp_svbank" {
  resolver_rule_id = aws_route53_resolver_rule.corp_svbank.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_corp_svbank" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_corp_svbank.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "corp_svbank_resolver" {
  name                      = "corp-svbank-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_corp_svbank_resolver" {
  provider                  = aws.secondary
  name                      = "corp-svbank-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "corp_svbank_resolver" {
  resource_arn       = aws_route53_resolver_rule.corp_svbank.arn
  resource_share_arn = aws_ram_resource_share.corp_svbank_resolver.arn
}

resource "aws_ram_resource_association" "secondary_corp_svbank_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_corp_svbank.arn
  resource_share_arn = aws_ram_resource_share.secondary_corp_svbank_resolver.arn
}

resource "aws_ram_principal_association" "corp_svbank_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.corp_svbank_resolver.arn
}

resource "aws_ram_principal_association" "secondary_corp_svbank_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_corp_svbank_resolver.arn
}


resource "aws_route53_resolver_rule" "dmz_local" {
  domain_name          = "dmz.local"
  name                 = "dmz-local"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_dmz_local" {
  provider             = aws.secondary
  domain_name          = "dmz.local"
  name                 = "dmz-local"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "dmz_local" {
  resolver_rule_id = aws_route53_resolver_rule.dmz_local.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_dmz_local" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_dmz_local.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "dmz_local_resolver" {
  name                      = "dmz-local-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_dmz_local_resolver" {
  provider                  = aws.secondary
  name                      = "dmz-local-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "dmz_local_resolver" {
  resource_arn       = aws_route53_resolver_rule.dmz_local.arn
  resource_share_arn = aws_ram_resource_share.dmz_local_resolver.arn
}

resource "aws_ram_resource_association" "secondary_dmz_local_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_dmz_local.arn
  resource_share_arn = aws_ram_resource_share.secondary_dmz_local_resolver.arn
}

resource "aws_ram_principal_association" "dmz_local_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.dmz_local_resolver.arn
}

resource "aws_ram_principal_association" "secondary_dmz_local_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_dmz_local_resolver.arn
}
resource "aws_route53_resolver_rule" "uat" {
  domain_name          = "uat.svbank.com"
  name                 = "uat-svbank"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_uat" {
  provider             = aws.secondary
  domain_name          = "uat.svbank.com"
  name                 = "uat-svbank"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "uat" {
  resolver_rule_id = aws_route53_resolver_rule.uat.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_uat" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_uat.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "uat_resolver" {
  name                      = "uat-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_uat_resolver" {
  provider                  = aws.secondary
  name                      = "uat-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "uat_resolver" {
  resource_arn       = aws_route53_resolver_rule.uat.arn
  resource_share_arn = aws_ram_resource_share.uat_resolver.arn
}

resource "aws_ram_resource_association" "secondary_uat_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_uat.arn
  resource_share_arn = aws_ram_resource_share.secondary_uat_resolver.arn
}

resource "aws_ram_principal_association" "uat_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.uat_resolver.arn
}

resource "aws_ram_principal_association" "secondary_uat_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_uat_resolver.arn
}

resource "aws_route53_resolver_rule" "ppdmz" {
  domain_name          = "ppdmz.local"
  name                 = "ppdmz"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_ppdmz" {
  provider             = aws.secondary
  domain_name          = "ppdmz.local"
  name                 = "ppdmz"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "ppdmz" {
  resolver_rule_id = aws_route53_resolver_rule.ppdmz.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_ppdmz" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_ppdmz.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "ppdmz_resolver" {
  name                      = "ppdmz-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_ppdmz_resolver" {
  provider                  = aws.secondary
  name                      = "ppdmz-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "ppdmz_resolver" {
  resource_arn       = aws_route53_resolver_rule.ppdmz.arn
  resource_share_arn = aws_ram_resource_share.ppdmz_resolver.arn
}

resource "aws_ram_resource_association" "secondary_ppdmz_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_ppdmz.arn
  resource_share_arn = aws_ram_resource_share.secondary_ppdmz_resolver.arn
}

resource "aws_ram_principal_association" "ppdmz_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.ppdmz_resolver.arn
}

resource "aws_ram_principal_association" "secondary_ppdmz_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_ppdmz_resolver.arn
}

resource "aws_route53_resolver_rule" "qa" {
  domain_name          = "qa.svbank.com"
  name                 = "qa-svbank"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_qa" {
  provider             = aws.secondary
  domain_name          = "qa.svbank.com"
  name                 = "qa-svbank"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "qa" {
  resolver_rule_id = aws_route53_resolver_rule.qa.id
  vpc_id           = module.vpc.vpc_id
  
}

resource "aws_route53_resolver_rule_association" "secondary_qa" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_qa.id
  vpc_id           = module.secondary_vpc.vpc_id
  
}

resource "aws_ram_resource_share" "qa_resolver" {
  name                      = "qa-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_qa_resolver" {
  provider                  = aws.secondary
  name                      = "qa-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "qa_resolver" {
  resource_arn       = aws_route53_resolver_rule.qa.arn
  resource_share_arn = aws_ram_resource_share.qa_resolver.arn
}

resource "aws_ram_resource_association" "secondary_qa_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_qa.arn
  resource_share_arn = aws_ram_resource_share.secondary_qa_resolver.arn
}

resource "aws_ram_principal_association" "qa_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.qa_resolver.arn
}

resource "aws_ram_principal_association" "secondary_qa_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_qa_resolver.arn
}

resource "aws_route53_resolver_rule" "dev" {
  domain_name          = "dev.svbank.com"
  name                 = "dev-svbank"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_dev" {
  provider             = aws.secondary
  domain_name          = "dev.svbank.com"
  name                 = "dev-svbank"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "dev" {
  resolver_rule_id = aws_route53_resolver_rule.dev.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_dev" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_dev.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "dev_resolver" {
  name                      = "dev-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_dev_resolver" {
  provider                  = aws.secondary
  name                      = "dev-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "dev_resolver" {
  resource_arn       = aws_route53_resolver_rule.dev.arn
  resource_share_arn = aws_ram_resource_share.dev_resolver.arn
}

resource "aws_ram_resource_association" "secondary_dev_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_dev.arn
  resource_share_arn = aws_ram_resource_share.secondary_dev_resolver.arn
}

resource "aws_ram_principal_association" "dev_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.dev_resolver.arn
}

resource "aws_ram_principal_association" "secondary_dev_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_dev_resolver.arn
}


###################
# C4EP-3367 - Start
###################
resource "aws_route53_resolver_rule" "api_svb" {
  domain_name          = "api.svb.com"
  name                 = "api-svb"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_api_svb" {
  provider             = aws.secondary
  domain_name          = "api.svb.com"
  name                 = "api-svb"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "api_svb" {
  resolver_rule_id = aws_route53_resolver_rule.api_svb.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_api_svb" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_api_svb.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "api_svb_resolver" {
  name                      = "api-svb-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_api_svb_resolver" {
  provider                  = aws.secondary
  name                      = "api-svb-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "api_svb_resolver" {
  resource_arn       = aws_route53_resolver_rule.api_svb.arn
  resource_share_arn = aws_ram_resource_share.api_svb_resolver.arn
}

resource "aws_ram_resource_association" "secondary_api_svb_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_api_svb.arn
  resource_share_arn = aws_ram_resource_share.secondary_api_svb_resolver.arn
}

resource "aws_ram_principal_association" "api_svb_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.api_svb_resolver.arn
}

resource "aws_ram_principal_association" "secondary_api_svb_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_api_svb_resolver.arn
}

###################
# C4EP-3367 - End
###################

###################
# C4EP-3565 - Start
###################
resource "aws_route53_resolver_rule" "svbank_com" {
  domain_name          = "svbank.com"
  name                 = "svbank-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)

}

resource "aws_route53_resolver_rule" "secondary_svbank_com" {
  provider             = aws.secondary
  domain_name          = "svbank.com"
  name                 = "svbank-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "svbank_com" {
  resolver_rule_id = aws_route53_resolver_rule.svbank_com.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_svbank_com" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_svbank_com.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "svbank_com_resolver" {
  name                      = "svbank-com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_svbank_com_resolver" {
  provider                  = aws.secondary
  name                      = "svbank-com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "svbank_com_resolver" {
  resource_arn       = aws_route53_resolver_rule.svbank_com.arn
  resource_share_arn = aws_ram_resource_share.svbank_com_resolver.arn
}

resource "aws_ram_resource_association" "secondary_svbank_com_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_svbank_com.arn
  resource_share_arn = aws_ram_resource_share.secondary_svbank_com_resolver.arn
}

resource "aws_ram_principal_association" "svbank_com_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.svbank_com_resolver.arn
}

resource "aws_ram_principal_association" "secondary_svbank_com_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_svbank_com_resolver.arn
}

###################
# C4EP-3565 - End
###################

###################
# C4EP-4085 - Start
###################

resource "aws_route53_resolver_rule" "developer_svb_com" {
  domain_name          = "developer.svb.com"
  name                 = "developer-svb-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_developer_svb_com" {
  provider             = aws.secondary
  domain_name          = "developer.svb.com"
  name                 = "developer-svb-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "developer_svb_com" {
  resolver_rule_id = aws_route53_resolver_rule.developer_svb_com.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_developer_svb_com" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_developer_svb_com.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "developer_svb_com_resolver" {
  name                      = "developer-svb-com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_developer_svb_com_resolver" {
  provider                  = aws.secondary
  name                      = "developer-svb-com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "developer_svb_com_resolver" {
  resource_arn       = aws_route53_resolver_rule.developer_svb_com.arn
  resource_share_arn = aws_ram_resource_share.developer_svb_com_resolver.arn
}

resource "aws_ram_resource_association" "secondary_developer_svb_com_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_developer_svb_com.arn
  resource_share_arn = aws_ram_resource_share.secondary_developer_svb_com_resolver.arn
}

resource "aws_ram_principal_association" "developer_svb_com_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.developer_svb_com_resolver.arn
}

resource "aws_ram_principal_association" "secondary_developer_svb_com_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_developer_svb_com_resolver.arn
}
###################
# C4EP-4085 - End
###################

###################
# C4EP-4471 - Start
###################

resource "aws_route53_resolver_rule" "svbconnect_com" {
  domain_name          = "svbconnect.com"
  name                 = "svbconnect-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_svbconnect_com" {
  provider             = aws.secondary
  domain_name          = "svbconnect.com"
  name                 = "svbconnect-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "svbconnect_com" {
  resolver_rule_id = aws_route53_resolver_rule.svbconnect_com.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_svbconnect_com" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_svbconnect_com.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "svbconnect_com_resolver" {
  name                      = "svbconnect-com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_svbconnect_com_resolver" {
  provider                  = aws.secondary
  name                      = "svbconnect-com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "svbconnect_com_resolver" {
  resource_arn       = aws_route53_resolver_rule.svbconnect_com.arn
  resource_share_arn = aws_ram_resource_share.svbconnect_com_resolver.arn
}

resource "aws_ram_resource_association" "secondary_svbconnect_com_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_svbconnect_com.arn
  resource_share_arn = aws_ram_resource_share.secondary_svbconnect_com_resolver.arn
}

resource "aws_ram_principal_association" "svbconnect_com_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.svbconnect_com_resolver.arn
}

resource "aws_ram_principal_association" "secondary_svbconnect_com_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_svbconnect_com_resolver.arn
}
###################
## C4EP-4471 - End
###################

###################
## C4OPS-2263 - Start - Add Outbound resolvers for svbsignon.svb.com
###################
resource "aws_route53_resolver_rule" "svbsignon_svb_com" {
  domain_name          = "svbsignon.svb.com"
  name                 = "svbsignon-svb-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_svbsignon_svb_com" {
  provider             = aws.secondary
  domain_name          = "svbsignon.svb.com"
  name                 = "svbsignon-svb-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "svbsignon_svb_com" {
  resolver_rule_id = aws_route53_resolver_rule.svbsignon_svb_com.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_svbsignon_svb_com" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_svbsignon_svb_com.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "svbsignon_svb_com_resolver" {
  name                      = "svbsignon_svb_com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_svbsignon_svb_com_resolver" {
  provider                  = aws.secondary
  name                      = "svbsignon_svb_com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "svbsignon_svb_com_resolver" {
  resource_arn       = aws_route53_resolver_rule.svbsignon_svb_com.arn
  resource_share_arn = aws_ram_resource_share.svbsignon_svb_com_resolver.arn
}

resource "aws_ram_resource_association" "secondary_svbsignon_svb_com_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_svbsignon_svb_com.arn
  resource_share_arn = aws_ram_resource_share.secondary_svbsignon_svb_com_resolver.arn
}

resource "aws_ram_principal_association" "svbsignon_svb_com_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.svbsignon_svb_com_resolver.arn
}

resource "aws_ram_principal_association" "secondary_svbsignon_svb_com_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_svbsignon_svb_com_resolver.arn
}

###################
## C4OPS-3146 - Start - Add Outbound resolvers for svbsignon-dev.svb.com
###################
resource "aws_route53_resolver_rule" "svbsignon-dev_svb_com" {
  domain_name          = "svbsignon-dev.svb.com"
  name                 = "svbsignon-dev-svb-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_svbsignon-dev_svb_com" {
  provider             = aws.secondary
  domain_name          = "svbsignon-dev.svb.com"
  name                 = "svbsignon-dev-svb-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "svbsignon-dev_svb_com" {
  resolver_rule_id = aws_route53_resolver_rule.svbsignon-dev_svb_com.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_svbsignon-dev_svb_com" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_svbsignon-dev_svb_com.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "svbsignon-dev_svb_com_resolver" {
  name                      = "svbsignon-dev_svb_com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_svbsignon-dev_svb_com_resolver" {
  provider                  = aws.secondary
  name                      = "svbsignon-dev_svb_com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "svbsignon-dev_svb_com_resolver" {
  resource_arn       = aws_route53_resolver_rule.svbsignon-dev_svb_com.arn
  resource_share_arn = aws_ram_resource_share.svbsignon-dev_svb_com_resolver.arn
}

resource "aws_ram_resource_association" "secondary_svbsignon-dev_svb_com_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_svbsignon-dev_svb_com.arn
  resource_share_arn = aws_ram_resource_share.secondary_svbsignon-dev_svb_com_resolver.arn
}

resource "aws_ram_principal_association" "svbsignon-dev_svb_com_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.svbsignon-dev_svb_com_resolver.arn
}

resource "aws_ram_principal_association" "secondary_svbsignon-dev_svb_com_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_svbsignon-dev_svb_com_resolver.arn
}

###################
## ECP-342 - Start
################### 

resource "aws_route53_resolver_rule" "baas_svb_com" {
  domain_name          = "baas.svb.com"
  name                 = "baas-svb-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_baas_svb_com" {
  provider             = aws.secondary
  domain_name          = "baas.svb.com"
  name                 = "baas-svb-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "baas_svb_com" {
  resolver_rule_id = aws_route53_resolver_rule.baas_svb_com.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_baas_svb_com" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_baas_svb_com.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "baas_svb_com_resolver" {
  name                      = "baas-svb-com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_baas_svb_com_resolver" {
  provider                  = aws.secondary
  name                      = "baas-svb-com-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "baas_svb_com_resolver" {
  resource_arn       = aws_route53_resolver_rule.baas_svb_com.arn
  resource_share_arn = aws_ram_resource_share.baas_svb_com_resolver.arn
}

resource "aws_ram_resource_association" "secondary_baas_svb_com_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_baas_svb_com.arn
  resource_share_arn = aws_ram_resource_share.secondary_baas_svb_com_resolver.arn
}

resource "aws_ram_principal_association" "baas_svb_com_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.baas_svb_com_resolver.arn
}

resource "aws_ram_principal_association" "secondary_baas_svb_com_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_baas_svb_com_resolver.arn
}
###################
## ECP-342 - End
################### 



###################
## ECPI-222 - Start - Add resolvers for managed AD domains
###################
resource "aws_route53_resolver_rule" "managed_ad" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  domain_name          = var.managed_ad_domain
  name                 = "managed_ad"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = var.managed_ad_primary_region_1
  }
  target_ip {
    ip = var.managed_ad_primary_region_2
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_managed_ad" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  provider             = aws.secondary
  domain_name          = var.managed_ad_domain
  name                 = "managed_ad"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = var.managed_ad_secondary_region_1
  }
    target_ip {
    ip = var.managed_ad_secondary_region_2
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "managed_ad" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  resolver_rule_id = aws_route53_resolver_rule.managed_ad[0].id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_managed_ad" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_managed_ad[0].id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "managed_ad_resolver" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  name                      = "managed_ad-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_managed_ad_resolver" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  provider                  = aws.secondary
  name                      = "managed_ad-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "managed_ad_resolver" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  resource_arn       = aws_route53_resolver_rule.managed_ad[0].arn
  resource_share_arn = aws_ram_resource_share.managed_ad_resolver[0].arn
}

resource "aws_ram_resource_association" "secondary_managed_ad_resolver" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_managed_ad[0].arn
  resource_share_arn = aws_ram_resource_share.secondary_managed_ad_resolver[0].arn
}

resource "aws_ram_principal_association" "managed_ad_resolver" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.managed_ad_resolver[0].arn
}

resource "aws_ram_principal_association" "secondary_managed_ad_resolver" {
  count = var.enable_managed_ad_resolver == "Y" ? 1 : 0
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_managed_ad_resolver[0].arn
}

###################
## ECPI-222 - End - Add resolvers for managed AD domains
###################

###################
## TASK2905137- Start
################### 


resource "aws_route53_resolver_rule" "fcpd_fcbint_net" {
  domain_name          = "fcpd.fcbint.net"
  name                 = "fcpd-fcbint-net"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_fcpd_fcbint_net" {
  provider             = aws.secondary
  domain_name          = "fcpd.fcbint.net"
  name                 = "fcpd-fcbint-net"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "fcpd_fcbint_net" {
  resolver_rule_id = aws_route53_resolver_rule.fcpd_fcbint_net.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_fcpd_fcbint_net" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_fcpd_fcbint_net.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "fcpd_fcbint_net_resolver" {
  name                      = "fcpd-fcbint-net-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_fcpd_fcbint_net_resolver" {
  provider                  = aws.secondary
  name                      = "secondary-fcpd-fcbint-net-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "fcpd_fcbint_net_resolver" {
  resource_arn       = aws_route53_resolver_rule.fcpd_fcbint_net.arn
  resource_share_arn = aws_ram_resource_share.fcpd_fcbint_net_resolver.arn
}

resource "aws_ram_resource_association" "secondary_fcpd_fcbint_net_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_fcpd_fcbint_net.arn
  resource_share_arn = aws_ram_resource_share.secondary_fcpd_fcbint_net_resolver.arn
}

resource "aws_ram_principal_association" "fcpd_fcbint_net_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.fcpd_fcbint_net_resolver.arn
}

resource "aws_ram_principal_association" "secondary_fcpd_fcbint_net_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_fcpd_fcbint_net_resolver.arn
}

###################
## TASK2905137- End
################### 


###################
## TASK2990132 - PCO-1726 Start
################### 

resource "aws_route53_resolver_rule" "fcbint_net" {
  domain_name          = "fcbint.net"
  name                 = "fcbint-net"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule" "secondary_fcbint_net" {
  provider             = aws.secondary
  domain_name          = "fcbint.net"
  name                 = "fcbint-net"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.secondary_central_outbound_dns.id

  target_ip {
    ip = "10.10.10.10"
  }
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_route53_resolver_rule_association" "fcbint_net" {
  resolver_rule_id = aws_route53_resolver_rule.fcbint_net.id
  vpc_id           = module.vpc.vpc_id
}

resource "aws_route53_resolver_rule_association" "secondary_fcbint_net" {
  provider         = aws.secondary
  resolver_rule_id = aws_route53_resolver_rule.secondary_fcbint_net.id
  vpc_id           = module.secondary_vpc.vpc_id
}

resource "aws_ram_resource_share" "fcbint_net_resolver" {
  name                      = "fcbint-net-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_share" "secondary_fcbint_net_resolver" {
  provider                  = aws.secondary
  name                      = "secondary-fcbint-net-resolver"
  allow_external_principals = false
  permission_arns       = ["arn:aws:ram::aws:permission/AWSRAMDefaultPermissionResolverRule"]
  tags                 = jsondecode(var.mandatory_tags)
}

resource "aws_ram_resource_association" "fcbint_net_resolver" {
  resource_arn       = aws_route53_resolver_rule.fcbint_net.arn
  resource_share_arn = aws_ram_resource_share.fcbint_net_resolver.arn
}

resource "aws_ram_resource_association" "secondary_fcbint_net_resolver" {
  provider           = aws.secondary
  resource_arn       = aws_route53_resolver_rule.secondary_fcbint_net.arn
  resource_share_arn = aws_ram_resource_share.secondary_fcbint_net_resolver.arn
}

resource "aws_ram_principal_association" "fcbint_net_resolver" {
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.fcbint_net_resolver.arn
}

resource "aws_ram_principal_association" "secondary_fcbint_net_resolver" {
  provider           = aws.secondary
  principal          = "arn:aws:organizations::${var.master_payer_account}:organization/${var.master_payer_org_id}"
  resource_share_arn = aws_ram_resource_share.secondary_fcbint_net_resolver.arn
}
###################
## TASK2990132 - PCO-1726 End
################### 