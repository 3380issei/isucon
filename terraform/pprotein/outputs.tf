output "monitor_public_ip" {
  description = "Elastic IP address of the monitoring server."
  value       = aws_eip.monitor.public_ip
}

output "monitor_ssh_command" {
  description = "SSH command; add -i with your private key path when needed."
  value       = "ssh ec2-user@${aws_eip.monitor.public_ip}"
}
