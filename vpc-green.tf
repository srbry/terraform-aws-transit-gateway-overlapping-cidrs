##########################
#### VPC ROUTING ETC #####
##########################

# transit 1 is from primary too secandry

resource "aws_vpc" "poc-vpc-transit-green" {
  cidr_block = "192.168.253.0/24"

  tags = {
    Name = "poc-vpc-transit-green"
  }
}

resource "aws_subnet" "poc-vpc-transit-green" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "192.168.253.0/24"
  vpc_id                  = aws_vpc.poc-vpc-transit-green.id
  map_public_ip_on_launch = true

  tags = {
    Name = "poc-vpc-transit-green"
  }

  depends_on = [aws_internet_gateway.poc-vpc-transit-green]
}

resource "aws_internet_gateway" "poc-vpc-transit-green" {
  vpc_id = aws_vpc.poc-vpc-transit-green.id

  tags = {
    Name = "poc-vpc-transit-green"
  }
}

resource "aws_route_table" "poc-vpc-transit-green" {
  vpc_id = aws_vpc.poc-vpc-transit-green.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.poc-vpc-transit-green.id
  }

  tags = {
    Name = "poc-vpc-transit-green"
  }
}

resource "aws_route_table_association" "poc-vpc-transit-green" {
  subnet_id      = aws_subnet.poc-vpc-transit-green.id
  route_table_id = aws_route_table.poc-vpc-transit-green.id
}

##########################
#### Transit gateway #####
##########################

resource "aws_ec2_transit_gateway_route_table" "poc-vpc-transit-green" {
  transit_gateway_id = aws_ec2_transit_gateway.poc-vpc-transit-gateway.id

  tags = map(
    "Name", "poc-vpc-transit-green",
    "10.0.1.0/24", "192.168.254.0/24",
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "poc-vpc-transit-green" {
  subnet_ids                                      = [aws_subnet.poc-vpc-transit-green.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.poc-vpc-transit-gateway.id
  vpc_id                                          = aws_vpc.poc-vpc-transit-green.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "poc-vpc-transit-green"
  }
}

resource "aws_ec2_transit_gateway_route_table_propagation" "poc-vpc-transit-green" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.poc-vpc-transit-orange.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.poc-vpc-transit-green.id
}

resource "aws_ec2_transit_gateway_route_table_association" "poc-vpc-transit-green" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.poc-vpc-transit-green.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.poc-vpc-transit-green.id
}

##########################
#### nat instance    #####
##########################


resource "aws_eip" "poc-vpc-transit-green-primary" {
  vpc = true

  network_interface = aws_network_interface.poc-vpc-transit-green-primary.id

  tags = {
    Name = "poc-vpc-transit-green-primary"
  }

  depends_on = [aws_internet_gateway.poc-vpc-transit-green]
}

resource "aws_eip" "poc-vpc-transit-green-secondary" {
  vpc = true

  network_interface = aws_network_interface.poc-vpc-transit-green-secondary.id

  tags = {
    Name = "poc-vpc-transit-green-secondary"
  }

  depends_on = [aws_internet_gateway.poc-vpc-transit-green]
}

resource "aws_security_group" "poc-vpc-transit-green" {
  name   = "poc-vpc-transit-green"
  vpc_id = aws_vpc.poc-vpc-transit-green.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "poc-vpc-transit-green"
  }
}

resource "aws_network_interface" "poc-vpc-transit-green-primary" {
  subnet_id         = aws_subnet.poc-vpc-transit-green.id
  private_ips       = ["192.168.253.11"]
  security_groups   = [aws_security_group.poc-vpc-transit-green.id]
  source_dest_check = false

  tags = {
    Name = "poc-vpc-transit-green-primary"
  }
}

resource "aws_network_interface" "poc-vpc-transit-green-secondary" {
  subnet_id         = aws_subnet.poc-vpc-transit-green.id
  private_ips       = ["192.168.253.12"]
  security_groups   = [aws_security_group.poc-vpc-transit-green.id]
  source_dest_check = false

  tags = {
    Name = "poc-vpc-transit-green-secondary"
  }
}

resource "aws_instance" "poc-vpc-green-nat-gateway-primary" {
  ami                  = data.aws_ami.amazon-linux.id
  instance_type        = "m4.large"
  key_name             = aws_key_pair.poc-vpc-transit.key_name
  iam_instance_profile = aws_iam_instance_profile.poc-vpc-transit-nat.name

  network_interface {
    network_interface_id = aws_network_interface.poc-vpc-transit-green-primary.id
    device_index         = 0
  }

  tags = {
    Name = "NATPrimary"
    Use  = "poc-vpc-transit-green-nat-primary"
  }


  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.poc-vpc-transit.private_key_pem
    host        = aws_eip.poc-vpc-transit-green-primary.public_ip
  }

  provisioner "file" {
    source      = "config/health_monitor.sh"
    destination = "/home/ec2-user/health_monitor.sh"
  }

  provisioner "file" {
    source      = "config/tgw_monitor.sh"
    destination = "/home/ec2-user/tgw_monitor.sh"
  }

  provisioner "file" {
    source      = "config/setup.sh"
    destination = "/home/ec2-user/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod a+x setup.sh",
      "./setup.sh"
    ]
  }
}

resource "aws_instance" "poc-vpc-green-nat-gateway-secondary" {
  ami                  = data.aws_ami.amazon-linux.id
  instance_type        = "m4.large"
  key_name             = aws_key_pair.poc-vpc-transit.key_name
  iam_instance_profile = aws_iam_instance_profile.poc-vpc-transit-nat.name

  network_interface {
    network_interface_id = aws_network_interface.poc-vpc-transit-green-secondary.id
    device_index         = 0
  }

  tags = {
    Name = "NATSecondary"
    Use  = "poc-vpc-transit-green-nat-secondary"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.poc-vpc-transit.private_key_pem
    host        = aws_eip.poc-vpc-transit-green-secondary.public_ip
  }

  provisioner "file" {
    source      = "config/health_monitor.sh"
    destination = "/home/ec2-user/health_monitor.sh"
  }

  provisioner "file" {
    source      = "config/tgw_monitor.sh"
    destination = "/home/ec2-user/tgw_monitor.sh"
  }

  provisioner "file" {
    source      = "config/setup.sh"
    destination = "/home/ec2-user/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod a+x setup.sh",
      "./setup.sh"
    ]
  }
}
