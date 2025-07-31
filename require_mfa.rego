package iam.security

deny[message] {
  input.users[_] == user
  user.role == "Administrator"
  not user.mfa_enabled
  message := sprintf("Admin user '%s' does not have MFA enabled.", [user.username])
}
