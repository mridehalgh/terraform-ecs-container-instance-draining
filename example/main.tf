provider "aws" {
  region = "eu-west-1"
}

data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2"

  name            = "test-vpc"
  cidr            = "10.0.0.0/16"
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnets  = ["10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}


resource "aws_security_group" "test_group" {
  name        = "test_sg"
  description = "creates a security group to test with"
  vpc_id      = module.vpc.vpc_id
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  name   = "my-ecs"
}
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name                = "ecs-asg"
  image_id            = data.aws_ami.ecs_ami.image_id
  desired_capacity    = "1"
  health_check_type   = "EC2"
  max_size            = "1"
  min_size            = "1"
  instance_type       = "t3a.micro"
  vpc_zone_identifier = module.vpc.private_subnets
}
module "example_module_test" {
  source                 = "../."
  autoscaling_group_name = module.asg.this_autoscaling_group_name
  autoscaling_group_arn  = module.asg.this_autoscaling_group_arn
  ecs_cluster_arn        = module.ecs.this_ecs_cluster_arn
  ecs_cluster_name       = module.ecs.this_ecs_cluster_name
  region                 = "eu-west-1"
}
