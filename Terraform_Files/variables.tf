variable "ami_reference" {
  type = string
  default = "ami-08e3b3155fc937a94"
}

variable "free_tier_instance" {
  type = string
  default = "t3.micro"
}

variable "ghcr_username" {
  type = string
}

variable "ghcr_token" {
  type      = string
  sensitive = true
}