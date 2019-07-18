/*
 * Proxy provider defining the requirement to pass down a provider aliased as aws.regional
 */
provider "aws" {
  alias = "regional"
}

#variable "app_cmdb_code" {}
#variable "app_abbreviation" {}

locals {
  logging_bucket_name = "${var.environment}-${data.aws_region.current.name}-${var.use_case}-s3-repl-logs"
}

data "aws_caller_identity" "current" {
  provider = "aws.regional"
}

data "aws_region" "current" {
  provider = "aws.regional"
}

# What does a standard bucket look like and how does replication overlay it?

resource "aws_kms_key" "kms_key" {
  provider            = "aws.regional"
  count               = "${length(var.bucket_names)}"
  enable_key_rotation = true
  description         = "${element(var.bucket_names, count.index)} key"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
                    "AWS": [
                        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"                                  
                      ]
                    },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF

  tags = {
    Name        = "${element(var.bucket_names, count.index)} key"
    Environment = "${var.environment}"
    #Application = "${var.app_cmdb_code}"
  }
}

resource "aws_kms_alias" "kms_alias" {
  provider      = "aws.regional"
  count         = "${length(var.bucket_names)}"
  name          = "alias/${element(var.bucket_names, count.index)}"
  target_key_id = "${element(aws_kms_key.kms_key.*.id, count.index)}"
}

resource "aws_s3_bucket" "bucket" {
  provider = "aws.regional"

  lifecycle {
    # Replication is set up outside of Terraform via CLI at present
    ignore_changes = ["replication_configuration"]
  }

  # Create as many buckets as we're passed:
  count  = "${length(var.bucket_names)}"
  bucket = "${element(var.bucket_names, count.index)}"
  acl    = "private"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.logging_bucket.id}"
    target_prefix = "${element(var.bucket_names, count.index)}/"
  }

  lifecycle_rule {
    prefix                                 = ""
    enabled                                = true
    abort_incomplete_multipart_upload_days = "7"

    transition {
      days          = "${var.lifecycle_days}"
      storage_class = "STANDARD_IA"
    }

    # Delete expired object delete markers
    expiration {
      expired_object_delete_marker = true
    }

    # Expire deleted versions
    noncurrent_version_expiration {
      days = "${var.noncurrent_lifecycle_days}"
    }
  }

  tags = {
    Name               = "${element(var.bucket_names, count.index)}"
    Environment        = "${var.environment}"
    #Application        = "${var.app_cmdb_code}"
    DataClassification = "${var.data_classification}"
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "DenyUnEncryptedObjectUploads",
          "Effect": "Deny",
          "Principal": {
              "AWS": "*"
          },
          "Action": [
            "s3:PutObject",
            "s3:ReplicateObject"
          ],
          "Resource": "arn:aws:s3:::${element(var.bucket_names, count.index)}/*",
          "Condition": {
              "StringNotEquals": {
                  "s3:x-amz-server-side-encryption": "aws:kms"
              }
          }
      },
      {
          "Sid": "DenyUnEncryptedObjectUploads",
          "Effect": "Deny",
          "Principal": {
              "AWS": "*"
          },
          "Action": [
            "s3:PutObject",
            "s3:ReplicateObject"
          ],
          "Resource": "arn:aws:s3:::${element(var.bucket_names, count.index)}/*",
          "Condition": {
              "StringNotEquals": {
              "s3:x-amz-server-side-encryption-aws-kms-key-id": "${element(aws_kms_key.kms_key.*.arn, count.index)}"
              }
          }
      },
      {
          "Sid": "DenyDelete",
          "Effect": "Deny",
          "Principal": {
              "AWS": "*"
          },
          "Action": "s3:DeleteObjectVersion",
          "Resource": "arn:aws:s3:::${element(var.bucket_names, count.index)}/*"
      },
      {
          "Sid": "DenyDelete",
          "Effect": "Deny",
          "Principal": {
              "AWS": "*"
          },
          "Action": "s3:DeleteBucket",
          "Resource": "arn:aws:s3:::${element(var.bucket_names, count.index)}"
      },
      {
        "Sid": "DRReplicate",
        "Effect": "Allow",
        "Principal": {"AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"},
        "Action": [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        "Resource": "arn:aws:s3:::${element(var.bucket_names, count.index)}/*"
      }      
  ]
}
  EOF
}

resource "aws_s3_bucket" "logging_bucket" {
  provider = "aws.regional"
  bucket   = "${local.logging_bucket_name}"
  acl      = "log-delivery-write"

  tags = {
    Name               = "${local.logging_bucket_name}"
    Environment        = "${var.environment}"
    #Application        = "${var.app_cmdb_code}"
    DataClassification = "Proprietary"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    prefix                                 = ""
    enabled                                = true
    abort_incomplete_multipart_upload_days = "2"

    transition {
      days          = "${var.logging_lifecycle_days}"
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = "${var.logging_expiration_days}"

      # See https://github.com/terraform-providers/terraform-provider-aws/issues/291
      # Expired object delete marker conflicts with the expiration policy of n days
      # expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      days = "${var.logging_noncurrent_lifecycle_days}"
    }
  }

  # Deny permanent delete and delete of the bucket itself
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "DenyDelete",
          "Effect": "Deny",
          "Principal": {
              "AWS": "*"
          },
          "Action": "s3:DeleteObjectVersion",
          "Resource": "arn:aws:s3:::${local.logging_bucket_name}/*"
      },
      {
          "Sid": "DenyDelete",
          "Effect": "Deny",
          "Principal": {
              "AWS": "*"
          },
          "Action": "s3:DeleteBucket",
          "Resource": "arn:aws:s3:::${local.logging_bucket_name}"
      }
  ]
}
  EOF
}

output "bucket_arns" {
  value = "${aws_s3_bucket.bucket.*.arn}"
}

output "bucket_names" {
  value = "${aws_s3_bucket.bucket.*.id}"
}

output "kms_key_arns" {
  value = "${aws_kms_key.kms_key.*.arn}"
}

output "kms_key_aliases" {
  value = "${aws_kms_alias.kms_alias.*.arn}"
}

output "kms_key_ids" {
  value = "${aws_kms_key.kms_key.*.id}"
}
