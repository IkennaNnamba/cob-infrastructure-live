output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "role_arns" {
  description = "Role ARNs to set as GitHub repository variables"
  value       = { for name, role in aws_iam_role.ci : name => role.arn }
}
