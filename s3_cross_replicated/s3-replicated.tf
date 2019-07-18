/*
 * Create a set of encrypted buckets, crosss-replicated between 2 regions in the same account
 */

/*
 * Requires providers for aws.primary and aws.secondary be passed down, already configured
 */
provider "aws" {
  alias = "primary"
}
provider "aws" {
  alias = "secondary"
}

##
## NOTE: This does not do replication configuration automatically yet. We're using the CLI since you can't do CRR-KMS with Terraform yet
##

#variable "app_cmdb_code" { }
#variable "app_abbreviation" { }
variable "environment" { }
variable "use_case" { description = "Unique use case for the replicated buckets - creates unique role & policy names" }

# This module doesn't work without versioning & lifecycle, but the retention can be tweaked from defaults if desired
variable "lifecycle_days" { default = 30 }
variable "noncurrent_lifecycle_days" { default = 366 }

# Bucket Variables
variable "bucket_prefixes" {
  type = "list"
  description = <<EOD
Array of buckets to create.

NOTE! Once buckets are created, changes to the list can be tricky. May be better to live with an unused/empty bucket in production environments.

1. Adds should only be done at the end of the list
2. Removing buckets other than from the end of the list is STRONGLY discouraged since Terraform will reorder
   resources and some ugly state-editing would be needed to align TF and AWS.
3. Rearranging the list is going to make a mess too.
EOD
}


variable "suffixes" {
  type = "map"
  default = {
    us-east-1 = "-e1"
    us-east-2 = "-e2"
    us-west-1 = "-w1"
    us-west-2 = "-w2"
  }
}

provider "local" {
  version = "> 1.0"
}

provider "template" {
  version = ">= 1.0"
}

data "aws_caller_identity" "current" { }

data "aws_region" "primary" {
  provider = "aws.primary"
}
data "aws_region" "secondary" {
  provider = "aws.secondary"
}

###############################################################################

module "primary_buckets" {
  source = "./kms_buckets"
  providers = {
    "aws.regional" = "aws.primary"
  }
  #app_cmdb_code = "${var.app_cmdb_code}"
  #app_abbreviation = "${var.app_abbreviation}"
  environment = "${var.environment}"
  use_case = "${var.use_case}"
  #lifecycle_days = "${var.lifecycle_days}"
  #noncurrent_lifecycle_days = "${var.noncurrent_lifecycle_days}"

  bucket_names = "${formatlist("%s%s", var.bucket_prefixes, lookup(var.suffixes, data.aws_region.primary.name))}"
}
module "secondary_buckets" {
  source = "./kms_buckets"
  providers = {
    "aws.regional" = "aws.secondary"
  }
  #app_cmdb_code = "${var.app_cmdb_code}"
  #app_abbreviation = "${var.app_abbreviation}"
  environment = "${var.environment}"
  use_case = "${var.use_case}"
  #lifecycle_days = "${var.lifecycle_days}"
  #noncurrent_lifecycle_days = "${var.noncurrent_lifecycle_days}"

  bucket_names = "${formatlist("%s%s", var.bucket_prefixes, lookup(var.suffixes, data.aws_region.secondary.name))}"
}


# Replication configuration JSON files.
data "template_file" "crr-json-primary" {
  count = "${length(var.bucket_prefixes)}"
  template = "${file("${path.module}/crr-kms-json.tpl")}"

  vars {
    replicate_role = "${aws_iam_role.s3_replicate_role.arn}"
    destination_bucket_arn = "${element(module.secondary_buckets.bucket_arns, count.index)}"
    destination_kms_arn = "${element(module.secondary_buckets.kms_key_arns, count.index)}"
  }
}

resource "local_file" "crr-json-primary" {
  count = "${length(var.bucket_prefixes)}"
  content = "${element(data.template_file.crr-json-primary.*.rendered, count.index)}"
  # Config files are named for the source bucket they apply to, though the file contents are about the dest bucket
  filename = "${path.cwd}/crr-kms-setup/${element(module.primary_buckets.bucket_names, count.index)}.json"
}

# Replication configuration JSON files.
data "template_file" "crr-json-secondary" {
  count = "${length(var.bucket_prefixes)}"
  template = "${file("${path.module}/crr-kms-json.tpl")}"

  vars {
    replicate_role = "${aws_iam_role.s3_replicate_role.arn}"
    destination_bucket_arn = "${element(module.primary_buckets.bucket_arns, count.index)}"
    destination_kms_arn = "${element(module.primary_buckets.kms_key_arns, count.index)}"
  }
}

resource "local_file" "crr-json-secondary" {
  count = "${length(var.bucket_prefixes)}"
  content = "${element(data.template_file.crr-json-secondary.*.rendered, count.index)}"
  # Config files are named for the source bucket they apply to, though the file contents are about the dest bucket
  filename = "${path.cwd}/crr-kms-setup/${element(module.secondary_buckets.bucket_names, count.index)}.json"
}

/*
 * IAM role & policy for replication
 */
resource "aws_iam_role" "s3_replicate_role" {
  name = "${var.use_case}-replicate-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
EOF
}

# Note: the statements below *could* be dedicated per region, but have been simplified by combining,
#       though this means some of the combinations of resources/conditions don't make sense in each region
data "aws_iam_policy_document" "replicate_policy" {
  statement {
    sid = "1"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [
      "${formatlist("%s", module.primary_buckets.bucket_arns)}",
      "${formatlist("%s", module.secondary_buckets.bucket_arns)}"
    ]
  }

  statement {
    actions = [
    "s3:GetObjectVersionAcl",
    "s3:GetObjectVersionForReplication"
    ]
    resources = [
      "${formatlist("%s/*", module.primary_buckets.bucket_arns)}",
      "${formatlist("%s/*", module.secondary_buckets.bucket_arns)}"
    ]
  }

  statement {
    actions = [
    "s3:ReplicateDelete",
    "s3:ReplicateObject"
    ]
    resources = [
      "${formatlist("%s/*", module.primary_buckets.bucket_arns)}",
      "${formatlist("%s/*", module.secondary_buckets.bucket_arns)}"
    ]
  }


  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      "${formatlist("%s", module.primary_buckets.kms_key_arns)}",
      "${formatlist("%s", module.secondary_buckets.kms_key_arns)}"
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"

      values = [
        "s3.${data.aws_region.primary.name}.amazonaws.com",
        "s3.${data.aws_region.secondary.name}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"

      values = [
        "${formatlist("%s/*", module.primary_buckets.bucket_arns)}",
        "${formatlist("%s/*", module.secondary_buckets.bucket_arns)}"
      ]
    }
  }

  statement {
    actions = [
    "kms:Encrypt"
    ]
    resources = [
      "${formatlist("%s", module.primary_buckets.kms_key_arns)}",
      "${formatlist("%s", module.secondary_buckets.kms_key_arns)}"
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"

      values = [
        "s3.${data.aws_region.primary.name}.amazonaws.com",
        "s3.${data.aws_region.secondary.name}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"

      values = [
        "${formatlist("%s/*", module.primary_buckets.bucket_arns)}",
        "${formatlist("%s/*", module.secondary_buckets.bucket_arns)}"
      ]
    }
  }
}

resource "aws_iam_policy" "replicate_policy" {
  name   = "${var.use_case}-replicate-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.replicate_policy.json}"
}

resource "aws_iam_role_policy_attachment" "replicate-attach" {
  role = "${aws_iam_role.s3_replicate_role.name}"
  policy_arn = "${aws_iam_policy.replicate_policy.arn}"
}


/*
  Since the application pattern should be "read/write to the region I'm running in", we expose the regions used
  as output, so that automation can avoid assumptions.
*/
output "primary_bucket_region" { value = "${data.aws_region.primary.name}" }
output "secondary_bucket_region" { value = "${data.aws_region.secondary.name}" }

output "primary_bucket_arns" { value = "${module.primary_buckets.bucket_arns}" }
output "secondary_bucket_arns" { value = "${module.secondary_buckets.bucket_arns}" }

output "primary_kms_keys" { value = "${module.primary_buckets.kms_key_ids}" }
output "secondary_kms_keys" { value = "${module.secondary_buckets.kms_key_ids}" }

output "primary_kms_key_arns" { value = "${module.primary_buckets.kms_key_arns}" }
output "secondary_kms_key_arns" { value = "${module.secondary_buckets.kms_key_arns}" }

output "primary_kms_aliases" { value = "${module.primary_buckets.kms_key_aliases}" }
output "secondary_kms_aliases" { value = "${module.secondary_buckets.kms_key_aliases}" }

output "primary_bucket_name" { value = "${module.primary_buckets.bucket_names}" }
output "secondary_bucket_name" {  value = "${module.secondary_buckets.bucket_names}"}


# The replication config commands are only output - it would be nice to local-exec the commands automatically, but they
# depend on the private API being set up and we don't have a known story for local-exec error handling for critical elements like this 
output "primary_cli_commands" {
  value = "${formatlist("aws s3private put-bucket-replication --bucket %s --replication-configuration file://crr-kms-setup/%s.json --region %s --profile SOURCE_ACCOUNT_PROFILE", module.primary_buckets.bucket_names, module.primary_buckets.bucket_names, data.aws_region.primary.name)}"
}
output "secondary_cli_commands" {
  value = "${formatlist("aws s3private put-bucket-replication --bucket %s --replication-configuration file://crr-kms-setup/%s.json --region %s --profile SOURCE_ACCOUNT_PROFILE", module.secondary_buckets.bucket_names, module.secondary_buckets.bucket_names, data.aws_region.secondary.name)}"
}