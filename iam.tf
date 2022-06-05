
locals {

  region = var.append_region ? "-${var.region}" : ""

}

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
      format("%s/*", var.ecs_cluster_arn),
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
  name               = format("%s-draining-function-role%s", var.autoscaling_group_name, local.region)
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = var.tags
}


## can't write to cloudwatch w/o
# resource "aws_iam_policy" "lambda" {

#   name        = "${var.ecs_cluster_name}-ecs-draining"
#   description = "IAM policy ecs/cloudwatch/sns to lambda for ecs cluster draining"
#   policy      = data.aws_iam_policy_document.lambda_assume_role.json
# }
## can't write to cloudwatch w/o
resource "aws_iam_role_policy_attachment" "lambda" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}


resource "aws_iam_role_policy" "lambda_execution_policy" {
  name = format("%s-draining-function-policy%s", var.autoscaling_group_name, local.region)
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
  name               = format("%s-lifecycle-role%s", var.autoscaling_group_name, local.region)
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
  name = format("%s-lifecycle-policy%s", var.autoscaling_group_name, local.region)
  role = aws_iam_role.lifecycle.id

  policy = data.aws_iam_policy_document.lifecycle_policy.json
}
