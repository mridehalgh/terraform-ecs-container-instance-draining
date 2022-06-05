locals {

  function_name = var.append_region ? "${var.ecs_cluster_name}-ecs-drain-${var.region}" : "${var.ecs_cluster_name}-ecs-drain"
}

resource "aws_sns_topic_subscription" "topic_lambda" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.draining_lambda.arn
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.draining_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.topic.arn
}

resource "aws_lambda_function" "draining_lambda" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.7"
  memory_size   = 128
  timeout       = 60

  environment {
    variables = {
      CLUSTER = var.ecs_cluster_name
      REGION  = var.region
    }
  }

  filename         = data.local_file.lambda_zip.filename
  source_code_hash = filebase64sha256(data.local_file.lambda_zip.filename)

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = format("/aws/lambda/%s", aws_lambda_function.draining_lambda.function_name)
  retention_in_days = 14

  tags = var.tags
}

resource "aws_autoscaling_lifecycle_hook" "asg_terminate_hook" {
  name                    = format("%s-terminating-hook", var.autoscaling_group_name)
  autoscaling_group_name  = var.autoscaling_group_name
  default_result          = "ABANDON"
  heartbeat_timeout       = var.heartbeat_timeout 
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = aws_sns_topic.topic.arn
  role_arn                = aws_iam_role.lifecycle.arn
}
