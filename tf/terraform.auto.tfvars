########################################################## Section 1 ##########################################################################

terraform_svc_user_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"

# Primary Region

vpc_azs                     = []
region                      = ""

# Secondary Region

secondary_vpc_azs                     = []
secondary_region                      = ""

# Change this value to "arn:aws-us-gov" or "arn:aws-cn" to deploy into
# GovCloud or China regions, respectively.

arn_format = "arn:aws"


preprod_vpc_cidr                    = ""
preprod_vpc_public_subnets          = []
preprod_vpc_private_subnets         = []
preprod_vpc_database_subnets        = []
preprod_vpc_intra_subnets           = []

prod_vpc_cidr             = ""
prod_vpc_public_subnets   = []
prod_vpc_private_subnets  = []
prod_vpc_database_subnets = []
prod_vpc_intra_subnets    = []


preprod_secondary_vpc_cidr                    = ""
preprod_secondary_vpc_public_subnets          = []
preprod_secondary_vpc_private_subnets         = []
preprod_secondary_vpc_database_subnets        = []
preprod_secondary_vpc_intra_subnets           = []

prod_secondary_vpc_cidr             = ""
prod_secondary_vpc_public_subnets   = []
prod_secondary_vpc_private_subnets  = []
prod_secondary_vpc_database_subnets = []
prod_secondary_vpc_intra_subnets    = []