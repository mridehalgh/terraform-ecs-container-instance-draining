data "aws_caller_identity" "current" {}
/*
* Lambda IAM
*/
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    actions = [
    "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
      "lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
    ]

    resources = [
      var.autoscaling_group_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      format("%s:*", aws_cloudwatch_log_group.lambda_log_group.arn)
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:ListContainerInstances",
      "ecs:DescribeContainerInstances",
      "ecs:UpdateContainerInstancesState",
    ]

    resources = [
      var.ecs_cluster_arn,
      format("%.64s/*", var.ecs_cluster_arn),
      format("arn:aws:ecs:%s:%s:container-instance/%s/*", var.region, data.aws_caller_identity.current.account_id, var.ecs_cluster_name)
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.topic.arn
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = format("%.41s-draining-function-role", regex("[[:alnum:]]+", var.autoscaling_group_name))
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_execution_policy" {
  name = format("%.39s-draining-function-policy", regex("[[:alnum:]]+", var.autoscaling_group_name))
  role = aws_iam_role.lambda.id

  policy = data.aws_iam_policy_document.lambda.json
}

/*
* Autoscaling
*/
data "aws_iam_policy_document" "lifecycle_assume_role" {
  statement {
    effect = "Allow"
    actions = [
    "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
      "autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lifecycle" {
  name               = format("%.49s-lifecycle-role", regex("[[:alnum:]]+", var.autoscaling_group_name))
  assume_role_policy = data.aws_iam_policy_document.lifecycle_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "lifecycle_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.topic.arn
    ]
  }
}

resource "aws_iam_role_policy" "lifecycle_execution_policy" {
  name = format("%.47s-lifecycle-policy", regex("[[:alnum:]]+", var.autoscaling_group_name))
  role = aws_iam_role.lifecycle.id

  policy = data.aws_iam_policy_document.lifecycle_policy.json
}

