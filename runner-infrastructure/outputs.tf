output "runner_instance_id" {
  description = "ID of the GitHub runner EC2 instance"
  value       = aws_instance.github_runner.id
}

output "runner_public_ip" {
  description = "Public IP of the GitHub runner"
  value       = aws_instance.github_runner.public_ip
}

output "runner_private_ip" {
  description = "Private IP of the GitHub runner"
  value       = aws_instance.github_runner.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to the runner"
  value       = "ssh -i ~/.ssh/${var.project_name}-runner-key ubuntu@${aws_instance.github_runner.public_ip}"
}

output "runner_name" {
  description = "Name of the GitHub runner"
  value       = "${var.project_name}-runner-${random_id.runner_suffix.hex}"
}