output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "ID of the monitoring EC2 instance"
  value       = aws_instance.monitoring.id
}

output "instance_public_ip" {
  description = "Public IP of the monitoring instance"
  value       = aws_instance.monitoring.public_ip
}

output "jenkins_url" {
  description = "URL for Jenkins UI"
  value       = "http://${aws_instance.monitoring.public_ip}:8080"
}

output "prometheus_url" {
  description = "URL for Prometheus UI"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "URL for Grafana UI"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}


