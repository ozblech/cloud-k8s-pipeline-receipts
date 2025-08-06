output "secret_name" {
  description = "Name of the secret created in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.receipts_secrets1.name
}
