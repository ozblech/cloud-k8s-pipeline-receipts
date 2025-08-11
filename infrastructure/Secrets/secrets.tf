resource "aws_secretsmanager_secret" "receipts_secrets" {
  name        = var.secret_name
  description = "Secrets for Receipts app (DB, S3, AWS credentials)"
}

resource "aws_secretsmanager_secret_version" "receipts_secrets_version" {
  secret_id     = aws_secretsmanager_secret.receipts_secrets.id

  secret_string = jsonencode({
    db_user                 = var.db_user
    db_password             = var.db_password
    db_connection_string    = var.db_connection_string
    AWS_ACCESS_KEY_ID       = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY   = var.aws_secret_access_key
  })
}
