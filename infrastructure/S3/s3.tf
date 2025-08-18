// ------------------------
// s3
// ------------------------
resource "aws_s3_bucket" "receipts_bucket" {
  bucket = var.s3_bucket_name
  
  tags = {
    Name        = "Receipts Bucket"
  }

  force_destroy = true // Allows deletion of non-empty buckets
}

resource "aws_s3_bucket_versioning" "receipts_bucket_versioning" {
  bucket = aws_s3_bucket.receipts_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

// This policy only grants access to minikube_role
resource "aws_s3_bucket_policy" "receipts_bucket_policy" {
  bucket = aws_s3_bucket.receipts_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowMinikubeRoleAccess"
        Effect    = "Allow"
        Principal = {
          AWS = var.minikube_role_arn
        }
        Action    = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.receipts_bucket.arn}",
          "${aws_s3_bucket.receipts_bucket.arn}/*"
        ]
      }
    ]
  })
}