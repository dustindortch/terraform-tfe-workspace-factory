terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.58"
    }
  }
}

provider "aws" {}

provider "tfe" {}

locals {
  workspace_accounts = {
    for k, v in var.workspace_accounts : k => merge(
      v,
      {
        variables = merge(
          v.variables,
          {
            TFC_AWS_RUN_ROLE_ARN = {
              category = "env"
              value    = module.idp.iam_role_arns[k]
            }
            account_id = {
              value = module.account[k].id
            }
          }
        )
      }
    )
  }
}

module "project" {
  source  = "dustindortch/project/tfe"
  version = "~> 1.1"

  name           = var.factory_project_name
  organization   = var.organization
  oauth_token_id = var.oauth_token_id
  workspaces     = local.workspace_accounts
}

module "variable-set" {
  source  = "dustindortch/variable-set/tfe"
  version = "~> 1.0"

  name         = var.factory_project_name
  organization = var.organization
  project_ids  = [module.project.id]

  variables = var.project_variables
}

module "account" {
  for_each = var.workspace_accounts

  source  = "dustindortch/account/aws"
  version = "~> 0.1"

  name  = each.key
  email = each.value.email
  organizational_unit_id = coalesce(
    each.value.organizational_unit_id,
    var.aws_organizational_unit_id
  )
}

locals {
  iam_roles = {
    for k, v in var.workspace_accounts : k => {
      subject_name = join(":", [
        "organization", var.organization,
        "project", var.factory_project_name,
        "workspace", k,
        "run_phase", "*"
      ])
      permissions = [
        "*"
      ]
      account_id = module.account[k].id
    }
  }
}

module "idp" {
  source  = "dustindortch/idp-tfe-oidc/aws"
  version = "~> 1.0"

  iam_roles = local.iam_roles
}
