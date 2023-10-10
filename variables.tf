variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
}

variable "availability_zones" {
  type    = list
  default = []
}

