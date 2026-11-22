# Customer sign-up and sign-in (app spec §6.1, infra spec §8). The account service checks
# access tokens with this pool's JWKS — same code path as devtoken locally.

locals {
  name   = "minibank-dev"
  domain = "andrewnguyen.cloud"

  web_callbacks = ["https://bank.${local.domain}/callback", "http://localhost:5173/callback"]
  web_logouts   = ["https://bank.${local.domain}/", "http://localhost:5173/"]
}

resource "aws_cognito_user_pool" "main" {
  name = local.name

  # Essentials: needed for Managed Login, free up to 10,000 MAU (Plus has no free tier)
  user_pool_tier = "ESSENTIALS"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # the bank account's display name comes from here (via userInfo, scope profile)
  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # customers sign themselves up
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # deleting the pool deletes every customer login
  deletion_protection = "ACTIVE"
  lifecycle {
    prevent_destroy = true
  }
}

# Managed Login on a Cognito prefix domain; auth.andrewnguyen.cloud comes with the edge stack
# (its certificate must be in us-east-1)
resource "aws_cognito_user_pool_domain" "main" {
  user_pool_id          = aws_cognito_user_pool.main.id
  domain                = "minibank-andrewnguyen"
  managed_login_version = 2
}

# SPA in the browser: cannot keep a secret, so authorization code + PKCE, no client secret
resource "aws_cognito_user_pool_client" "web" {
  name         = "web"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "profile", "email"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = local.web_callbacks
  logout_urls                          = local.web_logouts

  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # same answer for "wrong password" and "no such user"
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
}

# Managed Login v2 needs a style per client; Cognito's default look is enough for phase 1
resource "aws_cognito_managed_login_branding" "web" {
  user_pool_id                = aws_cognito_user_pool.main.id
  client_id                   = aws_cognito_user_pool_client.web.id
  use_cognito_provided_values = true
}

# end-to-end test scripts only: sign in with AWS credentials (admin API), no browser
resource "aws_cognito_user_pool_client" "e2e_test" {
  name         = "e2e-test"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret     = false
  explicit_auth_flows = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  prevent_user_existence_errors = "ENABLED"
}
