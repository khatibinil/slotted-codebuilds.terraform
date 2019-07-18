terraform {
  required_version = "~> 0.11"
}

/*   backend "s3" {
    role_arn       = "arn:aws:iam::025009383915:role/TerraformStateAndLocking-TerraformRole-1GNBRFA78DRM6"
    bucket         = "fams-terraform-state-025009383915"
    region         = "us-west-2"
    key            = "scm/terraform.tfstate"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-west-2:025009383915:key/9b74e82b-3518-42d3-adcd-a816fd374996"
    dynamodb_table = "terraform-lock-table"
  }
} */

module "replicated_buckets" {
  source = "./s3_cross_replicated"

  providers {
    "aws.primary"   = "aws"
    "aws.secondary" = "aws.sec"
  }

  #app_cmdb_code    = "${var.app_cmdb_code}"
  #app_abbreviation = "all"
  environment      = "${var.environment}"
  use_case         = "scm"
  bucket_prefixes  = "${var.bucket_prefixes}"
}



#SCM Version Table
resource "aws_dynamodb_table" "version_table" {
  name           = "scm_${var.region}_version_table"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ComponentName"

  attribute {
    name = "ComponentName"
    type = "S"
  }

  tags {
    Zone        = "All"
    Environment = "prod"
    Application = "All"
  }
}
