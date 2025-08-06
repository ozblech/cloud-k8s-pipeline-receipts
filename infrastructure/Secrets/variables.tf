variable "db_user" {
  description = "Database user for the PostgreSQL database"
  type        = string
}
variable "db_password" {
  description = "Database user for the PostgreSQL database"
  type        = string
}
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing app data"
  type        = string
}
variable "s3_region" {
  description = "AWS region where the S3 bucket is located"
  type        = string
}
variable "db_connection_string" {
  description = "Connection string for the PostgreSQL database"
  type        = string
}
variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  type        = string
}
variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  type        = string
}