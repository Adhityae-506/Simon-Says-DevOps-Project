#!/bin/bash

set -e

# Update Amazon Linux packages
dnf update -y

# Install Docker
dnf install -y docker

# Start Docker
systemctl start docker

# Enable Docker to start automatically after reboot
systemctl enable docker

# Allow ec2-user to run Docker without sudo
usermod -aG docker ec2-user

# Log in to GitHub Container Registry
echo "${ghcr_token}" | docker login ghcr.io \
  -u "${ghcr_username}" \
  --password-stdin