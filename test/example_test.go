package test

import (
	"fmt"
	awsSdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"testing"
)

const region = "eu-west-1"

func TestInstanceDrainingModule(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../example",
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Hook exists for ASG
	asgName := terraform.Output(t, terraformOptions, "asg_name")
	expectedHookName := fmt.Sprintf("%s-terminating-hook", asgName)
	hookExistsByName := checkLifecycleHookExistsByName(t, asgName, expectedHookName)
	assert.NoError(t, hookExistsByName)

	// SNS topic is created
	snsTopic := terraform.Output(t, terraformOptions, "sns_topic_arn")
	assert.NotEmpty(t, snsTopic)

	// Lambda exists
	expectedLambdaName := fmt.Sprintf("%s-draining-function", asgName)
	lambdaExistsByName := checkLambdaExistsByName(t, expectedLambdaName)
	assert.NoError(t, lambdaExistsByName)

	//Lambda invoked from SNS topic
	snsTopicSubscriptionExists := checkSnsTopicConfiguration(t, snsTopic)
	assert.NoError(t, snsTopicSubscriptionExists)
}

func checkSnsTopicConfiguration(t *testing.T, snsTopic string) error {
	snsClient := aws.NewSnsClient(t, region)

	params := &sns.ListSubscriptionsByTopicInput{TopicArn: awsSdk.String(snsTopic)}

	resp, err := snsClient.ListSubscriptionsByTopic(params)
	if err != nil {
		return err
	}

	for _, subscription := range resp.Subscriptions {
		if *subscription.Protocol == "lambda" {
			return nil
		}
	}
	return fmt.Errorf("Unable to find a lambda subscription")
}

func checkLambdaExistsByName(t *testing.T, lambdaName string) error {
	lambdaClient := aws.NewLambdaClient(t, region)

	params := &lambda.GetFunctionInput{
		FunctionName: awsSdk.String(lambdaName),
	}

	_, err := lambdaClient.GetFunction(params)
	if err != nil {
		return err
	}

	return nil
}

func checkLifecycleHookExistsByName(t *testing.T, asgName, hookName string) error {
	asgClient := aws.NewAsgClient(t, region)

	params := &autoscaling.DescribeLifecycleHooksInput{
		AutoScalingGroupName: awsSdk.String(asgName),
		LifecycleHookNames:   []*string{awsSdk.String(hookName)},
	}
	resp, err := asgClient.DescribeLifecycleHooks(params)
	if err != nil {
		return err
	}
	if len(resp.LifecycleHooks) == 0 {
		return fmt.Errorf("LifecycleHook not found")
	}

	return nil
}
