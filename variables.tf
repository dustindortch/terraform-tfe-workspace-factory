variable "factory_project_name" {
  description = "Factory project name for TFC/TFE"
  type        = string
}

variable "organization" {
  description = "TFC/TFE organization name"
  type        = string
}

variable "oauth_token_id" {
  description = "TFE/TFC Oauth Token ID"
  type        = string
}

variable "project_variables" {
  description = "Project variables for TFC/TFE"
  type = map(object({
    category = optional(string, "env")
    value    = string
  }))
}

variable "aws_organizational_unit_id" {
  description = "AWS Organizational Unit ID"
  type        = string
}

variable "workspace_accounts" {
  default     = {}
  description = "TFC/TFE workspaces to create"
  type = map(object({
    description            = optional(string, null)
    email                  = string
    organizational_unit_id = optional(string, null)
    vcs_repo = object({
      identifier     = string
      branch         = optional(string, null)
      oauth_token_id = optional(string, null)
    })
    variables = optional(map(object({
      category = optional(string, "env")
      value    = string
    })), null)
  }))
}
