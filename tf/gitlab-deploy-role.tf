# AMI  kms key
data "aws_kms_key" "ami" {
  key_id = "alias/ami_key"
}

# AMI Secondary kms key
data "aws_kms_key" "ami_secondary" {
  provider = aws.secondary
  key_id   = "alias/ami_key"
}

# AMI  kms key
data "aws_kms_key" "rds" {
  key_id = "alias/aws/rds"
}

# AMI Secondary kms key
data "aws_kms_key" "rds_secondary" {
  provider = aws.secondary
  key_id   = "alias/aws/rds"
}

# EBS  kms key
data "aws_kms_key" "ebs" {
  key_id = "alias/ebs_key"
}

# EBS Secondary kms key
data "aws_kms_key" "ebs_secondary" {
  provider = aws.secondary
  key_id   = "alias/ebs_key"
}

# EBS  kms key
data "aws_kms_key" "ssm" {
  key_id = "alias/ssm-key"
}

# EBS Secondary kms key
data "aws_kms_key" "ssm_secondary" {
  provider = aws.secondary
  key_id   = "alias/ssm-key"
}

# S3 key
data "aws_kms_key" "s3" {
  key_id = "alias/aws/s3"
}

# S3 secondary Key
data "aws_kms_key" "s3_secondary" {
  provider = aws.secondary
  key_id = "alias/aws/s3"
}

# backup  kms key
data "aws_kms_key" "backup" {
  key_id = "alias/aws/backup"
}

# backup  Secondary kms key
data "aws_kms_key" "backup_secondary" {
  provider = aws.secondary
  key_id   = "alias/aws/backup"
}


data "aws_iam_policy_document" "gitlab_permissions_boundary_policy_document" {
  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::svb-*-gitlab-*/*",
      "arn:aws:s3:::svb-*-gitlab-*"
    ]
  }
  statement {
    actions = [
      "SNS:Publish"
    ]
    resources = [
      "arn:aws:sns:*:*:svb-*-gitlab-*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:log-group:aws/lambda/run_gitlab_backup:log-stream:*",
      "arn:aws:logs:*:log-group:aws/lambda/run_gitlab_backup*"
    ]
  }
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeScalingActivities",
      "cloudwatch:PutMetricData",
      "ec2:CreateTags",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeTags",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeSubnets",
      "ec2:ImportKeyPair",
      "ec2messages:SendReply",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:BatchDeleteImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration",
      "ssm:PutInventory",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetManifest",
      "ssmmessages:OpenDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "ssm:SendCommand"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ssm:*:*:document/svb-*-gitlab-*"
    ]
    condition {
      test     = "StringEqualsIfExists"
      variable = "ssm:resourceTag/application"
      values = [
        "XXXXXXXXX"
      ]
    }
  }
  statement {
    actions = [
      "ec2:DetachVolume",
      "ec2:AttachVolume",
      "ec2:DeleteVolume",
      "ec2:TerminateInstances",
    ]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:instance/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/application"
      values = [
        "XXXXXXXXX",
      ]
    }
  }
  statement {
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/application"
      values = [
        "XXXXXXXXX",
      ]
    }
  }
  statement {
    actions = [
      "ec2:RunInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
      "ec2:TerminateInstances",
    ]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:launch-template/*",
      "arn:aws:ec2:*:*:placement-group/*",
      "arn:aws:ec2:*:*:key-pair/*",
      "arn:aws:ec2:*:*:subnet/*",
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*::image/*"
    ]
    condition {
      test     = "ArnEqualsIfExists"
      variable = "ec2:InstanceProfile"
      values = [
        "arn:aws:iam::*:instance-profile/gitlab-*-node*",
      ]
    }
  }
  statement {
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::*:role/gitlab-runner-nodes*",
    ]
  }
  statement {
    actions = [
      "logs:DescribeLogStreams",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:*:*",
    ]
  }
  statement {
    actions = [
      "kms:CreateGrant",
      "kms:ReEncrypt*",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ListGrants",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:RevokeGrant"
    ]
    resources = [
      "${data.aws_kms_key.ami.arn}",
      "${data.aws_kms_key.ami_secondary.arn}",
      "${data.aws_kms_key.backup.arn}",
      "${data.aws_kms_key.backup_secondary.arn}",
      "${data.aws_kms_key.ebs.arn}",
      "${data.aws_kms_key.ebs_secondary.arn}",
      "${data.aws_kms_key.rds.arn}",
      "${data.aws_kms_key.rds_secondary.arn}",
      "${data.aws_kms_key.ssm.arn}",
      "${data.aws_kms_key.ssm_secondary.arn}",
      "${data.aws_kms_key.s3.arn}",
      "${data.aws_kms_key.s3_secondary.arn}"
    ]
  }
  statement {
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/devops/*",
    ]
  }
  statement {
    actions = [
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/svb-*-gitlab-*",
    ]
  }
  statement {
    actions = [
      "ec2:DeleteKeyPair",
      "ec2:CreateKeyPair"
    ]
    resources = [
      "arn:aws:ec2:*:*:key-pair/aws*",
      "arn:aws:ec2:*:*:key-pair/runner-*"
    ]
  }
  statement {
    actions = [
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:UpdateAssociationStatus"
    ]
    resources = [
      "arn:aws:ssm:*:*:document/svb-app-*",
      "arn:aws:ssm:*:*:document/AWS-*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
       "arn:aws:secretsmanager:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:secret:gitlab-*",
       "arn:aws:secretsmanager:${data.aws_region.secondary.name}:${data.aws_caller_identity.this.account_id}:secret:gitlab-*",
       "arn:aws:secretsmanager:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:secret:svb-${var.environment}-*",
       "arn:aws:secretsmanager:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:secret:gitlab_ldap_password-*"
    ]

    condition {
       test = "StringEquals"
       variable = "secretsmanager:ResourceTag/application"
       values = [
        "XXXXXXXXX"
      ]
    }
  }
  statement {
    actions = [
      "es:ESHttp*"
    ]
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${var.account_id}:domain/svb*"
    ]
  }
}

resource "aws_iam_policy" "gitlab-deploy-perm-boundary-policy" {
  name   = "gitlab-deploy-perm-boundary-policy"
  policy = data.aws_iam_policy_document.gitlab_permissions_boundary_policy_document.json
  tags = jsondecode(var.mandatory_tags)
}

locals {
  group_name = "tlz_c4e_devops_engineer"
  policy_tags = merge(jsondecode(var.mandatory_tags), local.additional_tags)

  role_policies_map = {
    "tlz_devops_engineer" = {
      "description" = "Additional policies for  members of the DevOps team to assume devops_gitlab_deploy role",
      "custom_policies" = [
        "devops_gitlab_deploy_assume_role.json.tpl",
        "devops_gitlab_deploy_mfa.json.tpl",
      ]
    }
    "devops_gitlab_deploy" = {
      "description" = "This programmatic role access is for deploying gitlab"
      "custom_policies" = [
        "devops_gitlab_deploy_policy_describe_all.json.tpl",
        "devops_gitlab_deploy_policy_resource_specific.json.tpl",
        "devops_gitlab_deploy_policy_resource_specific_2.json.tpl",
        "devops_gitlab_deploy_deny_policies.json.tpl",
      ]
    }
  }
}

resource "aws_iam_group" "tlz_c4e_devops_engineer_group" {
  name = local.group_name
}


# render  custom policies to assume role
data "template_file" "custom" {
  for_each = toset(local.role_policies_map["tlz_devops_engineer"]["custom_policies"])
  template = file(
    "${path.module}/templates/${each.value}",
  )
}

# attach  custom policy to assume role
resource "aws_iam_group_policy" "custom" {
  depends_on = [aws_iam_group.tlz_c4e_devops_engineer_group]
  for_each   = toset(local.role_policies_map["tlz_devops_engineer"]["custom_policies"])
  name       = split(".", each.value)[0]
  group      = aws_iam_group.tlz_c4e_devops_engineer_group.name
  policy     = data.template_file.custom[each.value].rendered
}
