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
    kms    = autocloud_module.kms_key.blueprint_config
  }

  ###
  # Hide variables from user
  omit_variables = [
    # Global
    "environment",
    "name",
    "namespace",
    "tags",

    # Use defaults in the module (don't collect)
    "alias",
    "customer_master_key_spec",
    "key_usage",
    "multi_region",
    "policy",

    # Defined below
    "deletion_window_in_days",
    "description",
    "enable_key_rotation",
  ]

  ###
  # Force KMS key deletion window to 14 days
  variable {
    name = "kms.variables.deletion_window_in_days"

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
    # Global
    "environment",
    "name",
    "namespace",
    "tags",

    # Use defaults in the module (don't collect)
    "access_key_enabled",
    "acl",
    "allow_encrypted_uploads_only",
    "allow_ssl_requests_only",
    "allowed_bucket_actions",
    "block_public_acls",
    "block_public_policy",
    "bucket_key_enabled",
    "bucket_name",
    "cors_configuration",
    "force_destroy",
    "grants",
    "ignore_public_acls",
    "kms_master_key_arn",
    "lifecycle_configuration_rules",
    "lifecycle_rule_ids",
    "lifecycle_rules",
    "logging",
    "object_lock_configuration",
    "policy",
    "privileged_principal_actions",
    "privileged_principal_arns",
    "replication_rules",
    "restrict_public_buckets",
    "s3_object_ownership",
    "s3_replica_bucket_arn",
    "s3_replication_enabled",
    "s3_replication_permissions_boundary_arn",
    "s3_replication_rules",
    "s3_replication_source_roles",
    "source_policy_documents",
    "sse_algorithm",
    "ssm_base_path",
    "store_access_key_in_ssm",
    "transfer_acceleration_enabled",
    "user_enabled",
    "user_permissions_boundary_arn",
    "versioning_enabled",
    "website_configuration",
    "website_redirect_all_requests_to",

    # Defined below
    "allow_encrypted_uploads_only",
    "allow_ssl_requests_only",
    "kms_master_key_arn",
    "s3_object_ownership",
    "sse_algorithm",
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
    "deletion_window_in_days",
    "description",
    "enable_key_rotation",

    ###
    # S3 Bucket

    # Defined values, no user input needed
    "allow_encrypted_uploads_only",
    "allow_ssl_requests_only",
    "block_public_acls",
    "block_public_policy",
    "ignore_public_acls",
    "kms_master_key_arn",
    "restrict_public_buckets",
    "s3_object_ownership",
    "sse_algorithm",
    "versioning_enabled",
  ]

  ###
  # Set the order in which the variables are displayed to the user
  display_order {
    priority = 0
    values = [
      "global.variables.namespace",
      "global.variables.environment",
      "global.variables.name",
      "global.variables.tags",
    ]
  }
}



####
# Create Blueprint
#
# Create generator blueprint that contains all the elements
resource "autocloud_blueprint" "this" {
  name = "[Getting Started] KMS Encrypted S3 Bucket"

  ###
  # UI Configuration
  author       = "jim@unstyl.com" # Set to your user
  description  = "Deploys a KMS Encrypted S3 Bucket to AWS"
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
