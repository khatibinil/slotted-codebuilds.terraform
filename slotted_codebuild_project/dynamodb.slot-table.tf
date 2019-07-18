resource "aws_dynamodb_table" "slot_table" {
  name           = "${var.slot_family}-slot_table"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ComponentName"

  attribute {
    name = "ComponentName"
    type = "S"
  }

  tags {
    Zone        = "${var.fams_tags["Zone"]}"
    Environment = "${var.fams_tags["Environment"]}"
    Application = "${var.fams_tags["Application"]}"
    Terraform   = "${var.terraform_template}"
  }
}
