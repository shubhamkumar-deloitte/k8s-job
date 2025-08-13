/*
output "terraform_svc_access_key" {
  value = "${aws_iam_access_key.terraform_svc.id}"
}

output "terraform_svc_secret" {
  value = "${aws_iam_access_key.terraform_svc.secret}"
  sensitive = true
}
*/
output "private_hosted_zone_id" {
  value = module.private_dns.zone_id
}

output "secondary_private_hosted_zone_id" {
  value = module.secondary_private_dns.zone_id
}

# the output of this variable must be less than 6144 or AWS will error at runtime
output "gitlab_permission_boundary_policy_json_length" {
  value = length(jsonencode(jsondecode(data.aws_iam_policy_document.gitlab_permissions_boundary_policy_document.json)))
}
