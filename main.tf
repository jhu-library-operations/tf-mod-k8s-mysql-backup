resource "aws_s3_bucket" "mysql_backup" {
  bucket = format("%s-mysql-backup", var.prefix)
  tags   = var.tags
}

resource "aws_iam_user" "s3_user" {
  name = format("%s-backup", var.prefix)
  path = format("/%s/", var.prefix)

  tags = var.tags
}

resource "aws_iam_access_key" "s3" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_role" "backup_role" {
  name = format("%s-backup-role", var.prefix)

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
	"Action": "sts:AssumeRole",
	"Principal": {
	  "AWS": "${aws_iam_user.s3_user.arn}"
	},
	"Effect": "Allow"
      }
    ]
}
EOF

  tags = var.tags
}

resource "aws_iam_policy" "s3_bucket_perms" {
  name = format("%s-s3-bucket-perms", var.prefix)
  path = format("/%s/", var.prefix)

  policy = <<EOF
{
     "Version": "2012-10-17",
     "Statement": [
       {
          "Action": [
             "s3:PutObject",
             "s3:GetObject",
             "s3:ListBucket"
          ],
          "Resource": [
             "${aws_s3_bucket.mysql_backup.arn}/*",
             "${aws_s3_bucket.mysql_backup.arn}"
          ],
          "Effect": "Allow"
       }
     ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_role_policy_attachment" {
  name       = "s3-bucket"
  roles      = [aws_iam_role.backup_role.name]
  policy_arn = aws_iam_policy.s3_bucket_perms.arn
}

resource "local_file" "backup_secrets" {
  count           = length(var.namespaces)
  content         = templatefile("${path.module}/templates/_secret.yaml", { secrets = [{ key : "access_key_id", value : base64encode(aws_iam_access_key.s3.id) }, { key : "secret_access_key", value : base64encode(aws_iam_access_key.s3.secret) }], secret_name = "backup" })
  filename        = format("%s/%s/mysql_backup/secrets.yaml", var.output_path, element(var.namespaces, count.index))
  file_permission = "0600"
}

resource "local_file" "config_map" {
  count           = length(var.namespaces)
  content         = templatefile("${path.module}/templates/_configmap.yaml", { configs = [{ key : "role_arn", value : aws_iam_role.backup_role.arn }, { key : "s3_bucket", value : aws_s3_bucket.mysql_backup.id }, {key: "host", value: "mysql-service"}], name : "backup" })
  filename        = format("%s/%s/mysql_backup/configmap.yaml", var.output_path, element(var.namespaces, count.index))
  file_permission = "0600"
}

resource "local_file" "kustomize" {
  count           = length(var.namespaces)
  content         = file("${path.module}/templates/_kustomization.yaml")
  filename        = format("%s/%s/mysql_backup/kustomization.yaml", var.output_path, element(var.namespaces, count.index))
  file_permission = "0600"
}

resource "local_file" "cronjob" {
  count           = length(var.namespaces)
  content         = templatefile("${path.module}/templates/_cronjob.yaml", { mysql_secret_name = var.mysql_secret_name, mysql_secret_pass_key = var.mysql_secret_pass_key, mysqldump_image = var.mysqldump_image, name = "backup", cron_schedule_string = "0 */12 * * *" })
  filename        = format("%s/%s/mysql_backup/cronjob.yaml", var.output_path, element(var.namespaces, count.index))
  file_permission = "0600"
}

