output "web_server_id" {
  value = module.web_server.instance_id
}

output "web_server_private_ip" {
  value = module.web_server.private_ip
}

output "orders_db_endpoint" {
  value = module.cob_orders_db.db_endpoint
}

output "orders_db_secret_arn" {
  value = module.cob_orders_db.secret_arn
}