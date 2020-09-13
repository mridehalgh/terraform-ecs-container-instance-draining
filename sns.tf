#tfsec:ignore:AWS016
resource "aws_sns_topic" "topic" {
  name = format("%s-topic", var.autoscaling_group_name)
  tags = var.tags
}
