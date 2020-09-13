output "sns_topic_arn" {
  value       = aws_sns_topic.topic.arn
  description = "Topic used by ASG to send notifications when instance state is changing"
}
