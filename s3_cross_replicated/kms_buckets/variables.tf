variable "environment" {}

# This module doesn't work without versioning & lifecycle, but the retention can be tweaked
variable "lifecycle_days" {
  default = 30
}

variable "noncurrent_lifecycle_days" {
  default = 366
}

variable "logging_lifecycle_days" {
  default = 30
}

variable "logging_expiration_days" {
  default     = 120
  description = "Bucket access log expiration / automatic deletion - defaults to the security standard of 120, but can be extended"
}

variable "logging_noncurrent_lifecycle_days" {
  default = 120
}

# Bucket Variables
variable "use_case" {
  description = "Unique use case for the replicated buckets - creates unique logging bucket"
}

variable "bucket_names" {
  type = "list"
}

variable "data_classification" {
  default     = "Confidential"
  description = "Corporate standard data classification. KMS-secured buckets are likely to contain customer Confidential data, so the default is set accordingly"
}
