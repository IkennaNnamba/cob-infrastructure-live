output "db_endpoint" {
  value = var.prevent_destroy ? aws_db_instance.this_protected[0].endpoint : aws_db_instance.this[0].endpoint
}

output "db_port" {
  value = local.db_port
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "security_group_id" {
  value = aws_security_group.this.id
}