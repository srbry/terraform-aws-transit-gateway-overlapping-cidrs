resource "aws_ec2_transit_gateway" "poc-vpc-transit-gateway" {
  description = "poc-vpc-transit-gateway"

  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = map(
    "Name", "poc-vpc-transit-gateway",
  )
}
