output "bucket_arn" {
  value = aws_s3_bucket.mysql_backup.arn
}

output "user_arn" {
  value = aws_iam_user.s3_user.arn
}

