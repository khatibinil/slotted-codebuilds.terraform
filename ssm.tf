resource "aws_ssm_parameter" "scm_primary_bucket" {
  name  = "/fams/scm/scm-primary-bucket"
  type  = "String"
  value = "${module.replicated_buckets.primary_bucket_name[0]}"

  tags {
    Environment = "prod"
    Zone        = "SCM"
    Application = "ALL"
  }
}

resource "aws_ssm_parameter" "scm_primary_bucket_kms_key" {
  name  = "/fams/scm/scm-primary-bucket-kms-key"
  type  = "String"
  value = "${module.replicated_buckets.primary_kms_key_arns[0]}"

  tags {
    Environment = "prod"
    Zone        = "SCM"
    Application = "ALL"
  }
}

resource "aws_ssm_parameter" "scm_primary_region" {
  name  = "/fams/scm/scm-primary-region"
  type  = "String"
  value = "${var.region}"

  tags {
    Environment = "prod"
    Zone        = "SCM"
    Application = "ALL"
  }
}

resource "aws_ssm_parameter" "scm_secondary_bucket" {
  name  = "/fams/scm/scm-secondary-bucket"
  type  = "String"
  value = "${module.replicated_buckets.secondary_bucket_name[0]}"

  tags {
    Environment = "prod"
    Zone        = "SCM"
    Application = "ALL"
  }
}

resource "aws_ssm_parameter" "scm_secondary_bucket_kms_key" {
  name  = "/fams/scm/scm-secondary-bucket-kms-key"
  type  = "String"
  value = "${module.replicated_buckets.secondary_kms_key_arns[0]}"

  tags {
    Environment = "prod"
    Zone        = "SCM"
    Application = "ALL"
  }
}

resource "aws_ssm_parameter" "scm_secondary_region" {
  name  = "/fams/scm/scm-secondary-region"
  type  = "String"
  value = "${var.sec_region}"

  tags {
    Environment = "prod"
    Zone        = "SCM"
    Application = "ALL"
  }
}
