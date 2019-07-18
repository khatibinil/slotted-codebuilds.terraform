variable "region" {}
variable "sec_region" {}
variable "environment" {}
#variable "app_cmdb_code" {}
variable "terraform_profile" {}

#variable "role_arn" {}

variable "terraform_template" {
  default = "scm"
}

variable "bucket_prefixes" {
  type = "list"
}

variable "short_region" {
  type = "map"

  default = {
    us-east-1 = "e1"
    us-east-2 = "e2"
    us-west-2 = "w2"
    us-west-1 = "w1"
  }
}
