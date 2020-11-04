variable "prefix" {
  type = string
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
