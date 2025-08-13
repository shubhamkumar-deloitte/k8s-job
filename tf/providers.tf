terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.54.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region

  assume_role {
    role_arn = "${var.arn_format}:iam::${var.shared_services_account_number}:role/${var.shared_svcs_admin_role}"
  }
}

provider "aws" {
  profile = var.profile
  region  = var.secondary_region
  alias   = "secondary"

  assume_role {
    role_arn = "${var.arn_format}:iam::${var.shared_services_account_number}:role/${var.shared_svcs_admin_role}"  
  }
}
