######## Output init_slots_powershell file #######

data "template_file" "init_slots_powershell" {
  template = "${file("${path.module}/templates/init-slots-build.ps1.tmpl")}"

  vars {
    slot_family = "${var.slot_family}"
    aws_region  = "${var.aws_region}"
    aws_profile = "${var.terraform_profile}"
    count       = "${aws_codebuild_project.codebuild_project.count}"
  }
}

resource "local_file" "init_slots_powershell" {
  content  = "${data.template_file.init_slots_powershell.rendered}"
  filename = "${path.module}/init-slots-build-${var.slot_family}.ps1"
}

resource "null_resource" "init_slots" {
  triggers {
    test = "${data.template_file.init_slots_powershell.rendered}"
  }

  provisioner "local-exec" {
    command = "powershell.exe ${path.module}/init-slots-build-${var.slot_family}.ps1"
  }
}
