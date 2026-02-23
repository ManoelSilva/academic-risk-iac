output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.academic_risk_host.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.academic_risk_host.public_dns
}

output "mlflow_url" {
  description = "MLflow tracking server URL"
  value       = "http://${aws_instance.academic_risk_host.public_ip}:5001"
}

output "prometheus_url" {
  description = "Prometheus server URL"
  value       = "http://${aws_instance.academic_risk_host.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${aws_instance.academic_risk_host.public_ip}:3001"
}
