variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the web server."
  type        = string
}
