This module will automatically shutdown all EC2s that have the tag "AutoShutdown = "true".

Prerequisite:
1. You need to add the relative path to the lambda function that is included in this dir from your working dir.
2. (Optional) - Use var.startup and var.shutdown to set CRON to be able to control custom start and shutdown time

If you do not set the var, the following schedule will apply:
Mo - Fr: Shutdown 8 PM startup 8 AM
FR: Shutdown 8PM
MO: Startup 8AM
