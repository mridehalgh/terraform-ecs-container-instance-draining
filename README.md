<img src="https://edispark.com/assets/img/logo_dark.png" width="300">

# ECS container instance draining on lifecycle events

[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
![CI](https://github.com/edispark/terraform-ecs-container-instance-draining/workflows/build/badge.svg)

## Overview

Automates Container Instance Draining in Amazon ECS by removing tasks from an instance before scaling down a cluster with Auto Scaling Groups. Heavily inspired by this [blog post from AWS](https://aws.amazon.com/it/blogs/compute/how-to-automate-container-instance-draining-in-amazon-ecs/).
Lambda source code taken from and terraform inspired by the CloudFormation stack from Amazon available [here](https://github.com/aws-samples/ecs-cid-sample/blob/master/cform/ecs.yaml).  

It works by consuming lifecyle events from an autoscaling group. When an `autoscaling:EC2_INSTANCE_TERMINATING` event happens for the specified ASG it is placed on an SNS topic which in turn triggers lambda that will drain the tasks first from the ECS instance and then terminate the instance once the number of tasks on the instance become zero.

![Architecture](/media/architecture.png?raw=true "Architecture")


## Usage

```hcl
data "aws_region" "current" {}

module "example_module_test" {
  source = "git::https://github.com/edispark/terraform-ecs-container-instance-draining"

  autoscaling_group_name = "arn:partition:service:region:account-id:autoScalingGroupName/XXX"
  autoscaling_group_arn = "my-asg-name"
  ecs_cluster_arn = "arn:partition:service:region:account-id:cluster/XXX"
  ecs_cluster_name = "my-ecs-cluster-name"

  region                 = data.aws_region.current.name
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.26 |
| aws | >= 3.0 |
| local | 1.4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0 |
| local | 1.4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| autoscaling\_group\_arn | The name of the Auto Scaling group to which you want to assign the lifecycle hook to | `string` | n/a | yes |
| autoscaling\_group\_name | The name of the Auto Scaling group to which you want to assign the lifecycle hook to | `string` | n/a | yes |
| ecs\_cluster\_arn | Specifies the ECS Cluster ARN with which the resources would be associated | `string` | n/a | yes |
| ecs\_cluster\_name | Specifies the ECS Cluster Name with which the resources would be associated | `string` | n/a | yes |
| region | AWS Region for ECS cluster | `string` | n/a | yes |
| tags | Additional tags (\_e.g.\_ { BusinessUnit : ABC }) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| sns\_topic\_arn | Topic used by ASG to send notifications when instance state is changing |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Development

### Prerequisites 

- [terraform](https://learn.hashicorp.com/terraform/getting-started/install#installing-terraform)
- [terraform-docs](https://github.com/segmentio/terraform-docs)
- [pre-commit](https://pre-commit.com/#install)
- [golang](https://golang.org/doc/install#install)
- [golint](https://github.com/golang/lint#installation)

### Configurations

- Configure pre-commit hooks
```sh
pre-commit install
```

- Configure golang deps for tests
```sh
> go get github.com/gruntwork-io/terratest/modules/terraform
> go get github.com/stretchr/testify/assert
```

### Tests

- Tests are available in `test` directory
- In the test directory, run the below command
```sh
go test
```
