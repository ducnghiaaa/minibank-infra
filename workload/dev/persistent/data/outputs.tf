output "cluster_endpoint" {
  value = aws_rds_cluster.main.endpoint
}

output "port" {
  value = aws_rds_cluster.main.port
}

# for IAM policies: rds-db:connect on arn:aws:rds-db:<region>:<account>:dbuser:<resource_id>/<db user>
output "cluster_resource_id" {
  value = aws_rds_cluster.main.cluster_resource_id
}

output "master_user_secret_arn" {
  value = aws_rds_cluster.main.master_user_secret[0].secret_arn
}

output "db_clients_security_group_id" {
  value = aws_security_group.db_clients.id
}

output "aurora_security_group_id" {
  value = aws_security_group.aurora.id
}
