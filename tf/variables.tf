variable "profile" {
  type        = string
  description = "AWS CLI profile for terraform to execute with"
  default     = null
}

variable "account_id" {}

variable "subnet_list" {
  type        = list
  default     = []
}

variable "region" {
  type        = string
  description = "Region to use for the AWS provider"
}

variable "secondary_region" {
  type        = string
  description = "Secondary region to use for the AWS provider"
}

variable "arn_format" {
  type        = string
  default     = "arn:aws"
  description = "ARN format to be used. May be changed to support deployment in GovCloud/China regions."
}

variable "stack" {
  type        = string
  description = "Name of the stack to use in tagging"
  default     = ""
}

variable "environment" {
  type        = string
  description = "Environment type this will be deploying (Dev/Prod?)"
}

variable "vpc_name" {
  default = ""
}

variable "master_payer_account" {
  type        = string
  description = "Account number for the master payer account. Needed for sharing DNS resolver rules."
}

variable "master_payer_org_id" {
  type        = string
  description = "Master Payer Organization ID. Needed for sharing DNS resolver rules"
}

variable "shared_services_account_number" {
  type        = string
  description = "Account number for the shared services account. Needed because we are jumping through an assumed role."
}

variable "shared_svcs_admin_role" {
  description = "Name of the admin role establishing the trust between the master payer account and the shared services account"
  type        = string
  default     = ""
}

variable "terraform_svc_user_policy_arn" {
  type        = string
  description = "Arn for the policy to attach to the terraform service account for shared services"
}

variable "terraform_svc_credential_status" {
  type        = string
  description = "Status of the API key for terraform_svc. Set to Inactive to disable if needed"
  default     = ""
}

variable "vpc_azs" {
  type        = list
  description = "List of AZs to provision subnets into"
}

variable "secondary_vpc_azs" {
  type        = list
  description = "List of AZs to provision subnets into"
}

variable "preprod_shared_services_domain_name" {
  type        = string
  description = "DNS domain to use for shared services resources"
  default     = "preprod.us-west-2.tlz.svbank.com"
}

variable "prod_shared_services_domain_name" {
  type        = string
  description = "DNS domain to use for shared services resources"
  default     = "prod.us-west-2.tlz.svbank.com"
}

variable "preprod_secondary_shared_services_domain_name" {
  type        = string
  description = "DNS domain to use for shared services resources"
  default     = "preprod.us-east-1.tlz.svbank.com"
}

variable "prod_secondary_shared_services_domain_name" {
  type        = string
  description = "DNS domain to use for shared services resources"
  default     = "prod.us-east-1.tlz.svbank.com"
}

variable "alias_domain_name" {
  type        = string
  description = "DNS domain to use for DR"
}

variable "verify_shared_services_domain" {
  type        = bool
  description = "Do we set a verification txt record to prove domain ownership for SSL cerfiticate issuance"
  default     = false
}

variable "shared_services_domain_prefix_list" {
  type        = list
  description = "List of prefixes for the domain used for the SSL certificate(eg prod if the cert is prod.asdf.com)"
  default     = []
}

variable "shared_services_domain_verification_record_list" {
  type        = list
  description = "List of values for a TXT record to use for the verification in var.verify_shared_services_domain. Index of value should equal index of associated prefix."
  default     = []
}

######################################################## Section 1 ##############################################################

variable "preprod_vpc_cidr" {
  type        = string
  description = "CIDR to use for the core shared services VPC"
}

variable "prod_vpc_cidr" {
  type        = string
  description = "CIDR to use for the core shared services VPC"
}

variable "preprod_secondary_vpc_cidr" {
  type        = string
  description = "CIDR to use for the core shared services VPC"
}

variable "prod_secondary_vpc_cidr" {
  type        = string
  description = "CIDR to use for the core shared services VPC"
}

variable "preprod_vpc_public_subnets" {
  type        = list
  description = "List of CIDRs to use for public subnets"
}

variable "prod_vpc_public_subnets" {
  type        = list
  description = "List of CIDRs to use for public subnets"
}

variable "preprod_secondary_vpc_public_subnets" {
  type        = list
  description = "List of CIDRs to use for public subnets"
}

variable "prod_secondary_vpc_public_subnets" {
  type        = list
  description = "List of CIDRs to use for public subnets"
}

variable "preprod_vpc_private_subnets" {
  type        = list
  description = "List of CIDRs to use for private subnets"
}

variable "prod_vpc_private_subnets" {
  type        = list
  description = "List of CIDRs to use for private subnets"
}

variable "preprod_secondary_vpc_private_subnets" {
  type        = list
  description = "List of CIDRs to use for private subnets"
}

variable "prod_secondary_vpc_private_subnets" {
  type        = list
  description = "List of CIDRs to use for private subnets"
}

variable "preprod_vpc_database_subnets" {
  type        = list
  description = "List of CIDRs to use for database subnets"
}

variable "prod_vpc_database_subnets" {
  type        = list
  description = "List of CIDRs to use for database subnets"
}

variable "preprod_secondary_vpc_database_subnets" {
  type        = list
  description = "List of CIDRs to use for database subnets"
}

variable "prod_secondary_vpc_database_subnets" {
  type        = list
  description = "List of CIDRs to use for database subnets"
}

variable "preprod_vpc_intra_subnets" {
  type        = list
  description = "List of CIDRs to use for intra subnets"
}

variable "prod_vpc_intra_subnets" {
  type        = list
  description = "List of CIDRs to use for intra subnets"
}

variable "preprod_secondary_vpc_intra_subnets" {
  type        = list
  description = "List of CIDRs to use for intra subnets"
}

variable "prod_secondary_vpc_intra_subnets" {
  type        = list
  description = "List of CIDRs to use for intra subnets"
}

variable "mandatory_tags" {}


###################
## ECPI-222 - Start
###################

variable "enable_managed_ad_resolver" {
  type = string
  description = "Toggle to enable Managed AD resolver"
  default = ""
}

variable "managed_ad_domain" {
  type = string
  description = "Domain name of Managed AD in AWS"
  default = ""
}
variable "managed_ad_primary_region_1" {
  type = string
  description = "IP of Managed AD DC in primary region - 1"
  default = ""
}

variable "managed_ad_primary_region_2" {
  type = string
  description = "IP of Managed AD DC in primary region - 2"
  default = ""
}

variable "managed_ad_secondary_region_1" {
  type = string
  description = "IP of Managed AD DC in secondary region - 1"
  default = ""
}

variable "managed_ad_secondary_region_2" {
  type = string
  description = "IP of Managed AD DC in secondary region - 2"
  default = ""
}