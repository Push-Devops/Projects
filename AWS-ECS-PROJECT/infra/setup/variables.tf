variable "tf_state_bucket" {
  description = "Name of S3 bucket in AWS for storing TF state"
  default     = "devops-app-tf-state-v101"
}

variable "tf_state_lock_table" {
  description = "Name of DynamoDB table for TF state locking"
  default     = "devops-app-api-tf-lock"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "phase1"
}

variable "contact" {
  description = "Contact name for tagging resources"
  default     = "mark@example.com"
}
