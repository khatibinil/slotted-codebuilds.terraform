data "aws_caller_identity" "current" { }
resource "aws_codebuild_project" "codebuild_project" {
  name          = "${var.slot_family}-slot-${count.index}"
  count         = 4
  description   = "code build project for ${var.slot_family}-${count.index}"
  build_timeout = "120"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "${var.codebuild_image}"
    type            = "LINUX_CONTAINER"
    privileged_mode = "${var.privileged_mode}"
  }

  source {
    type     = "S3"
    location = "${var.bucket_arn}/codebuild/source/${var.slot_family}-slot-${count.index}.zip"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  tags {
    Zone        = "${var.fams_tags["Zone"]}"
    Environment = "${var.fams_tags["Environment"]}"
    Application = "${var.fams_tags["Application"]}"
    Terraform   = "${var.terraform_template}"
  }
}


resource "aws_iam_role" "codebuild_role" {
  name = "${var.slot_family}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"          
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
} 


resource "aws_iam_policy" "codebuild_policy" {
  name        = "${var.slot_family}-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket",
				        "s3:GetObjectVersion"
            ],
            "Resource": [
              "${var.bucket_arn}",
              "${var.bucket_arn}/*"
            ]
        },
        {

            "Effect": "Allow",
            "Action": [
                "kms:ListAliases",
                "kms:ListKeys",
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": [
              "${var.bucket_kms_arn}"
            ]
        },
        {
            "Sid": "VisualEditor4",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "VisualEditor6",
            "Effect": "Allow",
            "Action": [
                "ecr:CreateRepository",
                "ecr:GetAuthorizationToken",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:SetRepositoryPolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor7",
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": [
              "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/scm/*",
              "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/scm/*",
              "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/scm_packages/*",
              "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/scm_packages/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameters",
            "Resource": [
              "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/aws/service/*",
              "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/aws/service/*",
              "arn:aws:ssm:us-west-2::parameter/aws/service/*",
              "arn:aws:ssm:us-east-1::parameter/aws/service/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action" : [
                "ec2:AttachVolume",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CopyImage",
                "ec2:CreateImage",
                "ec2:CreateKeypair",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteKeypair",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSnapshot",
                "ec2:DeleteVolume",
                "ec2:DeregisterImage",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeRegions",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:GetPasswordData",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifySnapshotAttribute",
                "ec2:RegisterImage",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances"
              ],
            "Resource": "*"
        }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "${var.slot_family}-policy-attachment"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles      = ["${aws_iam_role.codebuild_role.id}"]
}
