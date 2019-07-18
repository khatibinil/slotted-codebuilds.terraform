provider "template" {
  version = "~> 1.0"
}

provider "local" {
  version = "~> 1.0"
}

provider "aws" {
  version = "~> 1.17"
  region  = "${var.region}"
  profile = "${var.terraform_profile}"
}

provider "aws" {
  alias   = "sec"
  version = "~> 1.17"
  region  = "${var.sec_region}"
  profile = "${var.terraform_profile}"
}
