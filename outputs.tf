output "ssh-key" {
  value = tls_private_key.poc-vpc-transit.private_key_pem
}

output "poc-vpc-transit-orange-ip" {
  value = aws_eip.poc-vpc-transit-orange.public_ip
}

output "poc-vpc-transit-blue-ip" {
  value = aws_eip.poc-vpc-transit-blue.public_ip
}
