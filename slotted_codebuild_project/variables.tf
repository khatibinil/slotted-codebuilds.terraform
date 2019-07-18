variable codebuild_image {}

variable slot_family {}

variable privileged_mode {
  default = "false"
}

variable aws_region {}

variable terraform_template {}

variable terraform_profile {}
variable fams_tags {
  type = "map"
}

variable bucket_arn {}

variable bucket_kms_arn {}

#################################################

output code_build_slots {
  value = "${aws_codebuild_project.codebuild_project.*.name}"
}

output dynamodb_table_arn {
  value = "${aws_dynamodb_table.slot_table.arn}"
}
