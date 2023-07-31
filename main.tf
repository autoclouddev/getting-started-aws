## --------------------------------------------------------------------------------------------------------------------
## GITHUB REPOSITORY CONFIGURATION
## Define which Github repositories the Terraform blueprint user has access to
## --------------------------------------------------------------------------------------------------------------------

data "autocloud_github_repos" "repos" {}

locals {
  # A list of Github repositories the user is allowed to submit Terraform code to, add specific repositories out of the
  # repositories you have authorized AutoCloud to access to limit users to your infrastructure as code repositories. If
  # you set these, uncomment the filter lines in the `dest_repos` definition on lines 20-23 below.
  # 
  # allowed_repos = [
  #   "example",
  # ]

  # Destination repos where generated code will be submitted
  dest_repos = [
    for repo in data.autocloud_github_repos.repos.data[*].url : repo

    # Uncomment if you have defined an allow list for your repos on lines 12-14 above.
    #
    # if anytrue([
    #   for allowed_repo in local.allowed_repos: length(regexall(format("/%s", allowed_repo), repo)) > 0
    # ])
  ]
}



## --------------------------------------------------------------------------------------------------------------------
## GLOBAL BLUEPRINT CONFIGURATION
## Define form questions the user will be shown which are either not associated with any Terraform module, or are shared
## between multiple Terraform modules.
## --------------------------------------------------------------------------------------------------------------------

data "autocloud_blueprint_config" "global" {
  ###
  # Hard code `enabled` to true to create all assets
  variable {
    name  = "enabled"
    value = true
  }

  ###
  # Set the namespace
  variable {
    name         = "namespace"
    display_name = "Namespace"
    helper_text  = "The organization namespace the assets will be deployed in"

    type = "shortText"

    value = "autocloud"
  }

  ###
  # Choose the environment
  variable {
    name         = "environment"
    display_name = "Environment"
    helper_text  = "The environment the assets will be deployed in"

    type = "radio"

    options {
      option {
        label   = "Nonprod"
        value   = "nonprod"
        checked = true
      }
      option {
        label = "Production"
        value = "production"
      }
    }
  }

  ###
  # Collect the name of the asset group
  variable {
    name         = "name"
    display_name = "Name"
    helper_text  = "The name of the encrypted S3 bucket"

    type = "shortText"

    validation_rule {
      rule          = "isRequired"
      error_message = "You must provide a name for the encrypted S3 bucket"
    }
  }
}


## --------------------------------------------------------------------------------------------------------------------
## AWS CONFIGURATION
## Define AWS specific elements that will be added to all assets, such as tags and tags
## between multiple Terraform modules.
## --------------------------------------------------------------------------------------------------------------------

data "autocloud_blueprint_config" "aws" {
  ###
  # Collect tags to apply to assets
  variable {
    name         = "tags"
    display_name = "Tags"
    helper_text  = "A map of tags to apply to the deployed assets"

    type = "map"
  }
}



## --------------------------------------------------------------------------------------------------------------------
## KMS KEY MODULE
## Define display and output for the KMS key used to encrypt the S3 bucket.
## --------------------------------------------------------------------------------------------------------------------

resource "autocloud_module" "kms_key" {
  name    = "cpkmskey"
  source  = "cloudposse/kms-key/aws"
  version = "0.12.1"
}

data "autocloud_blueprint_config" "kms_key" {
  source = {
    global = data.autocloud_blueprint_config.global.blueprint_config,
    aws    = data.autocloud_blueprint_config.aws.blueprint_config,
    kms    = autocloud_module.kms_key.blueprint_config
  }

  ###
  # Hide variables from user
  omit_variables = [
    # Use defaults in the module (don't collect)
    "kms_key.variables.customer_master_key_spec",
    "kms_key.variables.key_usage",
    "kms_key.variables.multi_region",
    "kms_key.variables.policy",
  ]

  ###
  # Show the full KMS key alias to the user
  variable {
    name         = "kms.variables.alias"
    display_name = "Key Alias"
    helper_text  = "The alias for the KMS key that will be created"
    value        = "alias/{{namespace}}-{{environment}}-{{name}}"
    variables = {
      namespace   = "global.variables.namespace"
      environment = "global.variables.environment"
      name        = "global.variables.name"
    }
  }

  ###
  # Force KMS key deletion window to 14 days
  variable {
    name  = "kms.variables.deletion_window_in_days"
    value = 14
  }

  ###
  # Set description
  variable {
    name  = "kms.variables.description"
    value = format("KMS key for encryption of encrypted S3 bucket {{namespace}}-{{environment}}-{{name}}")
    variables = {
      namespace   = "global.variables.namespace",
      environment = "global.variables.environment",
      name        = "global.variables.name",
    }
  }

  ###
  # Set the environment
  variable {
    name  = "kms.variables.environment"
    value = "global.variables.environment"
  }

  ###
  # Set the name
  variable {
    name  = "kms.variables.name"
    value = "global.variables.name"
  }

  ###
  # Set the namespace
  variable {
    name  = "kms.variables.namespace"
    value = "global.variables.namespace"
  }

  ###
  # Set the tags
  variable {
    name  = "kms.variables.tags"
    value = "aws.variables.tags"
  }
}



## --------------------------------------------------------------------------------------------------------------------
## S3 KEY MODULE
## Define display and output for the S3 bucket.
## --------------------------------------------------------------------------------------------------------------------

resource "autocloud_module" "s3_bucket" {
  name    = "cps3bucket"
  source  = "cloudposse/s3-bucket/aws"
  version = "3.1.2"
}

data "autocloud_blueprint_config" "s3_bucket" {
  source = {
    s3 = autocloud_module.s3_bucket.blueprint_config
  }

  ###
  # Hide variables from user
  omit_variables = [
    # Use defaults in the module (don't collect)
    "s3.variables.access_key_enabled",
    "s3.variables.acl",
    "s3.variables.allowed_bucket_actions",
    "s3.variables.bucket_key_enabled",
    "s3.variables.cors_configuration",
    "s3.variables.force_destroy",
    "s3.variables.grants",
    "s3.variables.lifecycle_configuration_rules",
    "s3.variables.lifecycle_rule_ids",
    "s3.variables.lifecycle_rules",
    "s3.variables.logging",
    "s3.variables.object_lock_configuration",
    "s3.variables.policy",
    "s3.variables.privileged_principal_actions",
    "s3.variables.privileged_principal_arns",
    "s3.variables.replication_rules",
    "s3.variables.s3_replica_bucket_arn",
    "s3.variables.s3_replication_enabled",
    "s3.variables.s3_replication_permissions_boundary_arn",
    "s3.variables.s3_replication_rules",
    "s3.variables.s3_replication_source_roles",
    "s3.variables.source_policy_documents",
    "s3.variables.ssm_base_path",
    "s3.variables.store_access_key_in_ssm",
    "s3.variables.transfer_acceleration_enabled",
    "s3.variables.user_enabled",
    "s3.variables.user_permissions_boundary_arn",
    "s3.variables.website_configuration",
    "s3.variables.website_redirect_all_requests_to",
  ]


  ###
  # Force encrypted uploads
  variable {
    name  = "s3.variables.allow_encrypted_uploads_only"
    value = true
  }

  ###
  # Force encrypted downloads
  variable {
    name  = "s3.variables.allow_ssl_requests_only"
    value = true
  }

  ###
  # Block public ACLs
  variable {
    name  = "s3.variables.block_public_acls"
    value = true
  }

  ###
  # Block public policy
  variable {
    name  = "s3.variables.block_public_policy"
    value = true
  }

  ###
  # Show the full bucket name to the user
  variable {
    name         = "s3.variables.bucket_name"
    display_name = "S3 Bucket Name"
    helper_text  = "The full name of the S3 bucket that will be created"
    value        = "{{namespace}}-{{environment}}-{{name}}"
    variables = {
      namespace   = "global.variables.namespace"
      environment = "global.variables.environment"
      name        = "global.variables.name"
    }
  }

  ###
  # Set the environment
  variable {
    name  = "s3.variables.environment"
    value = "global.variables.environment"
  }

  ###
  # Ignore public ACLs
  variable {
    name  = "s3.variables.ignore_public_acls"
    value = true
  }

  ###
  # Set KMS Key ARN
  variable {
    name  = "s3.variables.kms_master_key_arn"
    value = autocloud_module.kms_key.outputs["key_arn"]
  }

  ###
  # Set the name
  variable {
    name  = "s3.variables.name"
    value = "global.variables.name"
  }

  ###
  # Set the namespace
  variable {
    name  = "s3.variables.namespace"
    value = "global.variables.namespace"
  }

  ###
  # Restrict public buckets
  variable {
    name  = "s3.variables.restrict_public_buckets"
    value = true
  }

  ###
  # Force BucketOwner object permissions
  variable {
    name  = "s3.variables.s3_object_ownership"
    value = "BucketOwnerEnforced"
  }

  ###
  # Use KMS key encryption
  variable {
    name  = "s3.variables.sse_algorithm"
    value = "aws:kms"
  }

  ###
  # Set the tags
  variable {
    name  = "s3.variables.tags"
    value = "aws.variables.tags"
  }

  ###
  # Force versioning
  variable {
    name  = "s3.variables.versioning_enabled"
    value = true
  }
}



## --------------------------------------------------------------------------------------------------------------------
## COMPLETE BLUEPRINT CONFIGURATION
## Combine all the defined Terraform blueprint configurations into the complete blueprint configuration that will be used
## to create the form shown to the end user.
## --------------------------------------------------------------------------------------------------------------------

data "autocloud_blueprint_config" "complete" {
  source = {
    global = data.autocloud_blueprint_config.global.blueprint_config,
    aws    = data.autocloud_blueprint_config.aws.blueprint_config,
    kms    = data.autocloud_blueprint_config.kms_key.blueprint_config,
    s3     = data.autocloud_blueprint_config.s3_bucket.blueprint_config
  }

  ###
  # Hide variables from user
  omit_variables = [
    ###
    # Global

    # Use defaults in the module (don't collect)
    "additional_tag_map",
    "attributes",
    "context",
    "delimiter",
    "descriptor_formats",
    "id_length_limit",
    "label_key_case",
    "label_order",
    "label_value_case",
    "labels_as_tags",
    "regex_replace_chars",
    "stage",
    "tenant",

    # Defined values
    "enabled",

    ###
    # KMS Key

    # Defined values, no user input needed
    "kms.variables.customer_master_key_spec",
    "kms.variables.key_usage",
    "kms.variables.multi_region",
    "kms.variables.policy",
    "kms.variables.deletion_window_in_days",
    "kms.variables.description",
    "kms.variables.enable_key_rotation",
    "kms.variables.environment",
    "kms.variables.name",
    "kms.variables.namespace",
    "kms.variables.tags",

    ###
    # S3 Bucket

    # Defined values, no user input needed
    "s3.variables.allow_encrypted_uploads_only",
    "s3.variables.allow_ssl_requests_only",
    "s3.variables.block_public_acls",
    "s3.variables.block_public_policy",
    "s3.variables.environment",
    "s3.variables.ignore_public_acls",
    "s3.variables.kms_master_key_arn",
    "s3.variables.name",
    "s3.variables.namespace",
    "s3.variables.restrict_public_buckets",
    "s3.variables.s3_object_ownership",
    "s3.variables.sse_algorithm",
    "s3.variables.tags",
    "s3.variables.versioning_enabled",
  ]

  ###
  # Set the order in which the variables are displayed to the user
  display_order {
    priority = 0
    values = [
      "global.variables.namespace",
      "global.variables.environment",
      "global.variables.name",
      "kms.variables.alias",
      "s3.variables.bucket_name",
      "aws.variables.tags",
    ]
  }
}



## --------------------------------------------------------------------------------------------------------------------
## AUTOCLOUD BLUEPRINT
## Create the AutoCloud Terraform blueprint using the modules and blueprint configurations defined above. 
## --------------------------------------------------------------------------------------------------------------------

resource "autocloud_blueprint" "this" {
  name = "[Getting Started] KMS Encrypted S3 Bucket"

  ###
  # UI Configuration
  #
  author       = "example@example.com"
  description  = "Deploy an S3 bucket encrypted with a customer managed KMS key"
  instructions = <<-EOT
    To deploy this generator, these simple steps:

      * step 1: Choose the target environment
      * step 2: Provide a name to identify assets
      * step 3: Add tags to apply to assets
    EOT

  labels = ["aws"]



  ###
  # Form configuration
  config = data.autocloud_blueprint_config.complete.config



  ###
  # File definitions
  file {
    action      = "CREATE"
    destination = "{{namespace}}-{{environment}}-{{name}}.tf"
    variables = {
      namespace   = data.autocloud_blueprint_config.complete.variables["namespace"]
      environment = data.autocloud_blueprint_config.complete.variables["environment"]
      name        = data.autocloud_blueprint_config.complete.variables["name"]
    }

    ###
    # Add version requirements and provider configuration to the top of the output file. See ./files/provider_config.hcl.tpl
    # for content to be added.
    header = file("./files/provider_config.hcl.tpl")

    modules = [
      autocloud_module.kms_key.name,
      autocloud_module.s3_bucket.name,
    ]
  }



  ###
  # Destination repository git configuraiton
  #
  git_config {
    destination_branch = "main"

    git_url_options = local.dest_repos
    git_url_default = length(local.dest_repos) != 0 ? local.dest_repos[0] : "" # Choose the first in the list by default

    pull_request {
      title                   = "[AutoCloud] new KMS Encrypted S3 Bucket {{namespace}}-{{environment}}-{{name}}, created by {{authorName}}"
      commit_message_template = "[AutoCloud] new KMS Encrypted S3 Bucket {{namespace}}-{{environment}}-{{name}}, created by {{authorName}}"
      body                    = file("./files/pull_request.md.tpl")
      variables = {
        authorName  = "generic.authorName"
        namespace   = data.autocloud_blueprint_config.complete.variables["namespace"]
        environment = data.autocloud_blueprint_config.complete.variables["environment"]
        name        = data.autocloud_blueprint_config.complete.variables["name"]
      }
    }
  }
}
