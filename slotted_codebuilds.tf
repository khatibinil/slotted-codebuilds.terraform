module "nodejs_slotted_codebuild" {
  source = "./slotted_codebuild_project"

  aws_region = "${var.region}"

  fams_tags = {
    Zone        = "nodejs_slotted_codebuild"
    Environment = "prod"
    Application = "ALL"
  }

  #privileged_mode    = "true"
  slot_family        = "codebuild-nodejs"
  codebuild_image    = "aws/codebuild/standard:2.0"
  terraform_template = "${var.terraform_template}"
  bucket_arn         = "${module.replicated_buckets.primary_bucket_arns[0]}"
  bucket_kms_arn     = "${module.replicated_buckets.primary_kms_key_arns[0]}"
  terraform_profile  = "${var.terraform_profile}"
}

module "dotnet_slotted_codebuild" {
  source = "./slotted_codebuild_project"

  aws_region = "${var.region}"

  fams_tags = {
    Zone        = "dotnet_slotted_codebuild"
    Environment = "prod"
    Application = "ALL"
  }

  #privileged_mode    = "true"
  slot_family        = "codebuild-dotnet"
  codebuild_image    = "aws/codebuild/standard:2.0"
  terraform_template = "${var.terraform_template}"
  bucket_arn         = "${module.replicated_buckets.primary_bucket_arns[0]}"
  bucket_kms_arn     = "${module.replicated_buckets.primary_kms_key_arns[0]}"
  terraform_profile  = "${var.terraform_profile}"
}

module "packer_slotted_codebuild" {
  source = "./slotted_codebuild_project"

  aws_region = "${var.region}"

  fams_tags = {
    Zone        = "packer_slotted_codebuild"
    Environment = "prod"
    Application = "ALL"
  }

  slot_family        = "codebuild-packer"
  codebuild_image    = "aws/codebuild/standard:2.0"
  privileged_mode    = "true"
  terraform_template = "${var.terraform_template}"
  bucket_arn         = "${module.replicated_buckets.primary_bucket_arns[0]}"
  bucket_kms_arn     = "${module.replicated_buckets.primary_kms_key_arns[0]}"
  terraform_profile  = "${var.terraform_profile}"
}

module "ami_slotted_codebuild" {
  source = "./slotted_codebuild_project"

  aws_region = "${var.region}"

  fams_tags = {
    Zone        = "ami_slotted_codebuild"
    Environment = "prod"
    Application = "ALL"
  }

  slot_family        = "codebuild-ami"
  codebuild_image    = "aws/codebuild/standard:2.0"
  privileged_mode    = "true"
  terraform_template = "${var.terraform_template}"
  bucket_arn         = "${module.replicated_buckets.primary_bucket_arns[0]}"
  bucket_kms_arn     = "${module.replicated_buckets.primary_kms_key_arns[0]}"
  terraform_profile  = "${var.terraform_profile}"
}

/* 
module "cicd_slotted_codebuild" {
  source = "../modules/aws/slotted_codebuild_tf"

  aws_region = "${var.region}"

  fams_tags = {
    Zone        = "cicd_slotted_codebuild"
    Environment = "prod"
    Application = "ALL"
  }

  slot_family     = "codebuild-cicd"
  codebuild_image = "025009383915.dkr.ecr.us-west-2.amazonaws.com/fams-codebuild-cicd:latest"

  #privileged_mode    = "true"
  terraform_template = "${var.terraform_template}"
  bucket_arn         = "${module.replicated_buckets.primary_bucket_arns[0]}"
  bucket_kms_arn     = "${module.replicated_buckets.primary_kms_key_arns[0]}"
  terraform_profile  = "${var.terraform_profile}"
} */

