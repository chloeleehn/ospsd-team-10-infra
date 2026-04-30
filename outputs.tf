output "service_url" {
  value       = "https://${aws_apprunner_service.app.service_url}"
  description = "App Runner service URL"
}