output "asg_name" {
  value = module.asg.this_autoscaling_group_name
}

output "sns_topic_arn" {
  value = module.example_module_test.sns_topic_arn
}
