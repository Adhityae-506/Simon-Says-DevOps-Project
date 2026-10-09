resource "aws_instance" "simon_ec2_1" {
  ami           = var.ami_reference
  subnet_id = aws_subnet.public_subnet_1.id
  instance_type = var.free_tier_instance
  key_name = "MyEC2 keypair"
  vpc_security_group_ids = [ aws_security_group.simon_sg.id ]
  associate_public_ip_address = "true"

  user_data = templatefile("${path.module}/user_data.sh", {
    ghcr_username = var.ghcr_username
    ghcr_token    = var.ghcr_token
  })

  tags = {
    name = "simon-says-instance-1"
    team = "simon_devOps_team"
  } 
}

resource "aws_instance" "simon_ec2_2" {
  ami           = var.ami_reference
  subnet_id = aws_subnet.public_subnet_2.id
  instance_type = var.free_tier_instance
  key_name = "MyEC2 keypair"
  vpc_security_group_ids = [ aws_security_group.simon_sg.id ]
  associate_public_ip_address = "true"
  user_data = templatefile("${path.module}/user_data.sh", {
    ghcr_username = var.ghcr_username
    ghcr_token    = var.ghcr_token
  })

  tags = {
    name = "simon-says-instance-2"
    team = "simon_devOps_team"
  } 
}