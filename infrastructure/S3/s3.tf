// ------------------------
// s3
// ------------------------
resource "aws_s3_bucket" "reciepts_bucket" {
  bucket = var.s3_bucket_name
  
  tags = {
    Name        = "Reciepts Bucket"
  }
}