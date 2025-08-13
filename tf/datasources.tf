data "aws_region" "current" {}

data "aws_region" "current_secondary" {
  provider = aws.secondary
}