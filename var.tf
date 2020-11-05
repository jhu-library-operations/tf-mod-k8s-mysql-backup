variable "prefix" {
  type        = string
  description = "String of text used to prefix all names of resources created"
}

variable "namespaces" {
  type = list(string)
}

variable "output_path" {
  type = string
}

variable "tags" {
  type = map
}

variable "mysql_secret_name" {
  type = string
}

variable "mysql_secret_pass_key" {
  type = string
}

variable "mysqldump_image" {
  type    = string
  default = "ghcr.io/jhu-library-operations/mysqldump/mysqldump:latest"
}
