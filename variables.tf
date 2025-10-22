variable "aws_region" {
  description = "AWS region for gaming infrastructure"
  type        = string
  default     = "us-west-2"
}

variable "default_tags" {
  description = "Default tags applied to all AWS resources via the provider's default_tags."
  type        = map(string)
  default = {
    project = "scalable-tfe-aws-gaming-infrastructure"
  }
}

variable "tfe_hostname" {
  description = "Terraform Enterprise hostname"
  type        = string
  default     = "tfe.scalableterraform.com"
}

variable "tfe_organization" {
  description = "TFE organization name"
  type        = string
  default     = "scalable-tfe"
}

variable "infrastructure_workspace_name" {
  description = "Name of the infrastructure workspace to read outputs from"
  type        = string
  default     = "gaming-core-01-infrastructure"
}