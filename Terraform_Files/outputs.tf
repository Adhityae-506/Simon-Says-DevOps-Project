output "ec2_1_public_ip" {
  description = "Public IP address of EC2 instance 1"
  value       = aws_instance.simon_ec2_1.public_ip
}

output "ec2_2_public_ip" {
  description = "Public IP address of EC2 instance 2"
  value       = aws_instance.simon_ec2_2.public_ip
}