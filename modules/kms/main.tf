data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "key" {
  statement {
    sid = "AccountAdmin"
    actions = [ "kms:*" ]
    resources = [ "*" ]

    principals {
      type = "AWS"
      identifiers = [ "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" ]
    }
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [ "kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*" ]
    resources = [ "*" ]

    principals {
      type = "Service"
      identifiers = [ "logs.${data.aws_region.current}.amazonaws.com" ]
    }

    condition {
      test = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [ "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*" ]
    }
  }

  statement {
    sid = "CloudTrail"
    actions = ["kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [ "cloudtrial.amazonaws.com" ]
    }

    condition {
      test = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [ "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*" ]
    }
  }

  # CloudWatch alarms cannot publish to an SNS topic encrypted with the AWS-managed key,
  # so the topic uses this CMK and CloudWatch must be allowed to use it.

  statement {
    sid = "AlarmsToSNS"
    actions = [ "kms:Decrypt", "kms:GenerateDataKey*" ]
    resources = [ "*" ]

    principals {
      type = "Service"
      identifiers = [ "cloudwatch.amazonaws.com", "sns.amazonaws.com" ]
    }

    condition {
      test = "StringEquals"
      variable = "aws:SourceAcccount"
      values = [ data.aws_caller_identity.current.account_id ]
    }
  }
}

resource "aws_kms_key" "this" {
  description = "${var.name} platform key (logs, trail, SNS)"

  enable_key_rotation = true
  deletion_window_in_days = var.deletion_window_in_days
  policy = data.aws_iam_policy_document.key.json
}

resource "aws_kms_alias" "this" {
  name = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}