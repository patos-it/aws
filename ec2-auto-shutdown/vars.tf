variable "relative_path" {
  type        = string
  description = "Relative path to lambda function"
}

variable "startup" {
  type        = string
  description = "CRON expression to send STARTUP command to EC2"
  default     = "0 8 ? * MON-FRI *"
}

variable "shutdown" {
  type        = string
  description = "CRON expression to send SHUTDOWN command to EC2"
  default     = "0 20 ? * MON-FRI *"
}
