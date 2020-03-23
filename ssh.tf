resource "tls_private_key" "poc-vpc-transit" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_key_pair" "poc-vpc-transit" {
  key_name   = "poc-vpc-transit"
  public_key = tls_private_key.poc-vpc-transit.public_key_openssh
}
