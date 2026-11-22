output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

# AUTH_ISSUER and AUTH_JWKS_URL of the services
output "issuer" {
  value = "https://${aws_cognito_user_pool.main.endpoint}"
}

output "jwks_url" {
  value = "https://${aws_cognito_user_pool.main.endpoint}/.well-known/jwks.json"
}

output "managed_login_url" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.ap-southeast-1.amazoncognito.com"
}

output "web_client_id" {
  value = aws_cognito_user_pool_client.web.id
}

output "e2e_test_client_id" {
  value = aws_cognito_user_pool_client.e2e_test.id
}
