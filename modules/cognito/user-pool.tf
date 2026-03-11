resource "aws_cognito_user_pool" "pool" {
  name = "${var.name}-user-pool"

#   email_verification_message = "Please click the link below to verify your email address. {##Verify Email##}"
#   email_verification_subject = "Your verification link"

  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
    email_message_by_link = "Please click the link below to verify your email address. {##Verify Email##}"
    email_subject = "Your verification link"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${var.name}-client"

  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret     = false
  allowed_oauth_flows = [ "code" ]
  allowed_oauth_scopes = [ "aws.cognito.signin.user.admin", "email", "phone", "openid" ]
  explicit_auth_flows = ["ALLOW_USER_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  enable_token_revocation = true
  prevent_user_existence_errors = "ENABLED"
  allowed_oauth_flows_user_pool_client = true

  callback_urls = [ var.callback_urls ]
  logout_urls = [ var.logout_urls ]

}

resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email"
    client_id        = "${var.google_client_id}"
    client_secret    = "${var.google_client_secret}"
    authorize_scopes = "aws.cognito.signin.user.admin"
  }
  
  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}