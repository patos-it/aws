# IAM Role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "ec2_auto_shutdown_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda to manage EC2 instances
resource "aws_iam_policy" "lambda_policy" {
  name        = "ec2_auto_shutdown_lambda_policy"
  description = "IAM policy for EC2 auto-shutdown Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:StartInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function to stop EC2 instances
resource "aws_lambda_function" "stop_ec2_instances" {
  filename      = var.relative_path
  function_name = "ec2_auto_shutdown"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  environment {
    variables = {
      # Define the tag used to identify instances to be auto-shutdown
      TARGET_TAG_KEY   = "AutoShutdown"
      TARGET_TAG_VALUE = "true"
    }
  }
}

# Lambda function to start EC2 instances
resource "aws_lambda_function" "start_ec2_instances" {
  filename      = var.relative_path
  function_name = "ec2_auto_startup"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  environment {
    variables = {
      # Define the tag used to identify instances to be auto-started
      TARGET_TAG_KEY   = "AutoShutdown"
      TARGET_TAG_VALUE = "true"
      ACTION           = "start"
    }
  }
}

# EventBridge rule for weekday shutdown at 8 PM
resource "aws_cloudwatch_event_rule" "weekday_shutdown" {
  name                = "weekday-ec2-shutdown"
  description         = "Triggers EC2 shutdown at 8 PM on weekdays"
  schedule_expression = "cron(${var.shutdown})" # 8 PM UTC Monday to Friday "cron(0 20 ? * MON-FRI *)"
}

# EventBridge rule for weekday startup at 8 AM
resource "aws_cloudwatch_event_rule" "weekday_startup" {
  name                = "weekday-ec2-startup"
  description         = "Triggers EC2 startup at 8 AM on weekdays"
  schedule_expression = "cron(${var.startup})" #  8 AM UTC Monday to Friday: "cron(0 8 ? * MON-FRI *)"
}

# Connect the weekday shutdown rule to the Lambda function
resource "aws_cloudwatch_event_target" "weekday_shutdown_target" {
  rule      = aws_cloudwatch_event_rule.weekday_shutdown.name
  target_id = "StopEC2Instances"
  arn       = aws_lambda_function.stop_ec2_instances.arn
}

# Connect the weekday startup rule to the Lambda function
resource "aws_cloudwatch_event_target" "weekday_startup_target" {
  rule      = aws_cloudwatch_event_rule.weekday_startup.name
  target_id = "StartEC2Instances"
  arn       = aws_lambda_function.start_ec2_instances.arn
}

# Grant permission for EventBridge to invoke the Lambda functions
resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekday_shutdown.arn
}

resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ec2_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekday_startup.arn
}
