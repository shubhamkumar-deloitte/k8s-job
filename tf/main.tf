###########
# lookups
###########
# get any data required
data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

data "aws_region" "secondary" {
  provider = aws.secondary
}

# locals
locals {
  account_id = data.aws_caller_identity.this.account_id
  region     = data.aws_region.this.name
  vpc_name   = "core-shared-services-vpc"
  additional_tags = {
    owner = "XXXXXXXXX@svb.com"
  }
  tags = merge(jsondecode(var.mandatory_tags), local.additional_tags)
}

#######
# IAM #
#######

resource "aws_iam_user" "terraform_svc" {
  name = "terraform_svc"
  path = "/"

  tags = merge(
    local.tags,
    {
    "Name" = "Terraform Service User"
    "stack"     = var.stack
    "stack:env" = var.environment
    #"data_classification" = "SVB General Business"
    }
  )
}
/*
resource "aws_iam_access_key" "terraform_svc" {
  user   = aws_iam_user.terraform_svc.name
  status = var.terraform_svc_credential_status
}
*/
resource "aws_iam_user_policy_attachment" "terraform_svc" {
  user       = aws_iam_user.terraform_svc.name
  policy_arn = var.terraform_svc_user_policy_arn
}

############
# Route 53 #
############

# private zone with resolution

locals {
  subnet_list = var.environment == "preprod" ? module.vpc.private_subnets : module.vpc.public_subnets
  secondary_subnet_list = var.environment == "preprod" ? module.secondary_vpc.private_subnets : module.secondary_vpc.public_subnets
}

module "private_dns" {
  source                 = "./modules/private-dns"
  hosted_zone            = var.environment == "preprod" ? var.preprod_shared_services_domain_name : var.prod_shared_services_domain_name
  vpc_id                 = module.vpc.vpc_id
  resolver_endpoint_name = module.vpc.name
  ingress_cidr_blocks    = ["10.0.0.0/8"]
  subnets = [
    for subnet_id in local.subnet_list :
    subnet_id
  ]

  tags = merge(
    local.tags,
    {
    "stack"     = var.stack
    "stack:env" = var.environment
    #"data_classification" = "SVB General Business"
    }
  )
 /*
  tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
  }
*/
}

module "secondary_private_dns" {
  source = "./modules/private-dns"
  providers = {
    aws = aws.secondary
  }
  hosted_zone            = var.environment == "preprod" ? var.preprod_secondary_shared_services_domain_name : var.prod_secondary_shared_services_domain_name
  vpc_id                 = module.secondary_vpc.vpc_id
  resolver_endpoint_name = module.vpc.name
  ingress_cidr_blocks    = ["10.0.0.0/8"]
  subnets = [
    for subnet_id in local.secondary_subnet_list :
    subnet_id
  ]

  tags = merge(
    local.tags,
    {
    "stack"     = var.stack
    "stack:env" = var.environment
    #"data_classification" = "SVB General Business"
    }
  )
/*
  tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
  }
*/
}

resource "aws_route53_zone_association" "us-west-2-to-secondary" {
  provider = aws.secondary
  zone_id  = module.private_dns.zone_id
  vpc_id   = module.secondary_vpc.vpc_id
}

resource "aws_route53_zone_association" "us-east-1-to-primary" {
  zone_id  = module.secondary_private_dns.zone_id
  vpc_id   = module.vpc.vpc_id
}

resource "aws_route53_zone" "alias_zone" {
  name = var.alias_domain_name
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  tags = merge(
    local.tags,
    {
    "stack"     = var.stack
    "stack:env" = var.environment
    "data_classification" = "SVB General Business"
    }
  )

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone_association" "alias_secondary" {
  provider = aws.secondary
  zone_id  = aws_route53_zone.alias_zone.id
  vpc_id   = module.secondary_vpc.vpc_id
}

#######
# VPC #
#######
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v4.0.0"

  name                   = local.vpc_name
  cidr                   = var.environment == "preprod" ? var.preprod_vpc_cidr : var.prod_vpc_cidr
  azs                    = var.vpc_azs
  public_subnets         = var.environment == "preprod" ? var.preprod_vpc_public_subnets : var.prod_vpc_public_subnets
  private_subnets        = var.environment == "preprod" ? var.preprod_vpc_private_subnets : var.prod_vpc_private_subnets
  database_subnets       = var.environment == "preprod" ? var.preprod_vpc_database_subnets : var.prod_vpc_database_subnets
  intra_subnets          = var.environment == "preprod" ? var.preprod_vpc_intra_subnets : var.prod_vpc_intra_subnets
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  create_igw             = false
  map_public_ip_on_launch = true
  manage_default_network_acl = false
  manage_default_route_table = false
  manage_default_security_group = false
  enable_flow_log               = true
  create_flow_log_cloudwatch_log_group  = true
  flow_log_cloudwatch_log_group_retention_in_days = 365
  flow_log_cloudwatch_log_group_kms_key_id  = module.vpc_flow_logs_kms.kms_arn
  #create_flow_log_cloudwatch_iam_role = true
  flow_log_cloudwatch_log_group_name_prefix = "flowlogs"
  flow_log_cloudwatch_iam_role_arn  = aws_iam_role.vpc_flow_log_cloudwatch.arn

  default_security_group_ingress = []
  default_security_group_egress  = []

  tags = merge(
    local.tags,
    {
    "stack"     = var.stack
    "stack:env" = var.environment
    "data_classification" = "Internal"
    }
  )
/*
  tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "data_classification" = "SVB General Business"
  }
*/
  public_subnet_tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "Network"   = "Public"
  }

  private_subnet_tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "Network"   = "Private"
  }

  database_subnet_tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "Network"   = "Database"
  }

  intra_subnet_tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "Network"   = "Intra"
  }
}

module "secondary_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  providers = {
    aws = aws.secondary
  }
  version = "~> v4.0"

  name                   = local.vpc_name
  cidr                   = var.environment == "preprod" ? var.preprod_secondary_vpc_cidr : var.prod_secondary_vpc_cidr
  azs                    = var.secondary_vpc_azs
  public_subnets         = var.environment == "preprod"? var.preprod_secondary_vpc_public_subnets : var.prod_secondary_vpc_public_subnets
  private_subnets        = var.environment == "preprod"? var.preprod_secondary_vpc_private_subnets : var.prod_secondary_vpc_private_subnets
  database_subnets       = var.environment == "preprod"? var.preprod_secondary_vpc_database_subnets : var.prod_secondary_vpc_database_subnets
  intra_subnets          = var.environment == "preprod"? var.preprod_secondary_vpc_intra_subnets : var.prod_secondary_vpc_intra_subnets
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  create_igw             = false
  map_public_ip_on_launch = true
  manage_default_network_acl = false
  manage_default_route_table = false
  manage_default_security_group = false
  enable_flow_log               = true
  create_flow_log_cloudwatch_log_group  = true
  flow_log_cloudwatch_log_group_retention_in_days = 365
  flow_log_cloudwatch_log_group_kms_key_id  = module.secondary_vpc_flow_logs_kms.kms_arn
  #create_flow_log_cloudwatch_iam_role = true
  flow_log_cloudwatch_log_group_name_prefix = "flowlogs"
  flow_log_cloudwatch_iam_role_arn  = aws_iam_role.vpc_flow_log_cloudwatch.arn


  default_security_group_ingress = []
  default_security_group_egress  = []

  tags = merge(
    local.tags,
    {
    "stack"     = var.stack
    "stack:env" = var.environment
    "data_classification" = "Internal"
    }
  )
/*
  tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "data_classification" = "SVB General Business"
  }
*/
  public_subnet_tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "Network"   = "Public"
  }

  private_subnet_tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "Network"   = "Private"
  }

  database_subnet_tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "Network"   = "Database"
  }

  intra_subnet_tags = {
    "stack"     = var.stack
    "stack:env" = var.environment
    "Network"   = "Intra"
  }
}

module "vpc_flow_logs_kms" {
  source = "./modules/kms"
  deletion_window_in_days = 7
  description = "VPC Flow logs encryption key"
  enable_key_rotation = true
  tags = jsondecode(var.mandatory_tags)
}

module "secondary_vpc_flow_logs_kms" {
  source = "./modules/kms"
  deletion_window_in_days = 7
  description = "VPC Flow logs encryption key"
  enable_key_rotation = true
  tags = jsondecode(var.mandatory_tags)
  providers = {
    aws = aws.secondary
  }
}

resource "aws_iam_role" "vpc_flow_log_cloudwatch" {
  assume_role_policy   = data.aws_iam_policy_document.flow_log_cloudwatch_assume_role.json
  tags = merge(jsondecode(var.mandatory_tags), tomap({ "role_type" = "platform" }))
}

data "aws_iam_policy_document" "flow_log_cloudwatch_assume_role" {
  
  statement {
    sid = "AWSVPCFlowLogsAssumeRole"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    effect = "Allow"

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "vpc_flow_log_cloudwatch" {
  role       = aws_iam_role.vpc_flow_log_cloudwatch.name
  policy_arn = aws_iam_policy.vpc_flow_log_cloudwatch.arn
}

resource "aws_iam_policy" "vpc_flow_log_cloudwatch" {
  name_prefix = "vpc-flow-log-to-cloudwatch"
  policy      = data.aws_iam_policy_document.vpc_flow_log_cloudwatch.json
  #tags        = merge(var.tags, var.vpc_flow_log_tags)
  tags = jsondecode(var.mandatory_tags)
}

data "aws_iam_policy_document" "vpc_flow_log_cloudwatch" {

  statement {
    sid = "AWSVPCFlowLogsPushToCloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:flowlogs*"]
  }
}
