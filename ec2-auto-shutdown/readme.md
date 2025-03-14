# EC2 Auto-Shutdown Module

This Terraform module automates the shutdown of Amazon EC2 instances tagged with `AutoShutdown = "true"`. It offers flexible scheduling to manage startup and shutdown times effectively.

## Prerequisites

1. **Lambda Function Deployment:**
   - Deploy the Lambda function included in this module.
   - Specify the relative path to the Lambda function from your working directory in your Terraform configuration.

2. **Scheduling Configuration (Optional):**
   - Utilize the `var.startup` and `var.shutdown` variables to define custom CRON expressions for startup and shutdown times.
   - If these variables are not set, the following default schedule applies:
     - **Monday to Friday:**
       - Shutdown at 8:00 PM
       - Startup at 8:00 AM
     - **Friday:**
       - Shutdown at 8:00 PM
     - **Monday:**
       - Startup at 8:00 AM

## Usage

To implement this module, include it in your Terraform configuration as shown below:

```hcl
module "ec2_auto_shutdown" {
  source = "./path/to/module"

  # Optional: Define custom startup and shutdown times
  startup  = "0 8 * * 1-5"  # CRON expression for startup time
  shutdown = "0 20 * * 1-5"  # CRON expression for shutdown time

  # Specify the Lambda function path
  lambda_function_path = "./path/to/lambda_function"
}

