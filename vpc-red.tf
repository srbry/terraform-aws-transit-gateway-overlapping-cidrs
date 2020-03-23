##########################
#### VPC ROUTING ETC #####
##########################

# transit 1 is from primary too secandry

resource "aws_vpc" "poc-vpc-transit-red" {
  cidr_block = "192.168.252.0/24"

  tags = {
    Name = "poc-vpc-transit-red"
  }
}

resource "aws_subnet" "poc-vpc-transit-red" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "192.168.252.0/24"
  vpc_id                  = aws_vpc.poc-vpc-transit-red.id
  map_public_ip_on_launch = true

  tags = {
    Name = "poc-vpc-transit-red"
  }

  depends_on = [aws_internet_gateway.poc-vpc-transit-red]
}

resource "aws_internet_gateway" "poc-vpc-transit-red" {
  vpc_id = aws_vpc.poc-vpc-transit-red.id

  tags = {
    Name = "poc-vpc-transit-red"
  }
}

resource "aws_route_table" "poc-vpc-transit-red" {
  vpc_id = aws_vpc.poc-vpc-transit-red.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.poc-vpc-transit-red.id
  }

  tags = {
    Name = "poc-vpc-transit-red"
  }
}

resource "aws_route_table_association" "poc-vpc-transit-red" {
  subnet_id      = aws_subnet.poc-vpc-transit-red.id
  route_table_id = aws_route_table.poc-vpc-transit-red.id
}

##########################
#### Transit gateway #####
##########################

resource "aws_ec2_transit_gateway_route_table" "poc-vpc-transit-red" {
  transit_gateway_id = aws_ec2_transit_gateway.poc-vpc-transit-gateway.id

  tags = map(
    "Name", "poc-vpc-transit-red",
    "10.0.1.0/24", "192.168.254.0/24",
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "poc-vpc-transit-red" {
  subnet_ids                                      = [aws_subnet.poc-vpc-transit-red.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.poc-vpc-transit-gateway.id
  vpc_id                                          = aws_vpc.poc-vpc-transit-red.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "poc-vpc-transit-red"
  }
}

resource "aws_ec2_transit_gateway_route_table_propagation" "poc-vpc-transit-red" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.poc-vpc-transit-blue.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.poc-vpc-transit-red.id
}

resource "aws_ec2_transit_gateway_route_table_association" "poc-vpc-transit-red" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.poc-vpc-transit-red.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.poc-vpc-transit-red.id
}

##########################
#### nat instance    #####
##########################


resource "aws_eip" "poc-vpc-transit-red-primary" {
  vpc = true

  network_interface = aws_network_interface.poc-vpc-transit-red-primary.id

  tags = {
    Name = "poc-vpc-transit-red-primary"
  }

  depends_on = [aws_internet_gateway.poc-vpc-transit-red]
}

resource "aws_eip" "poc-vpc-transit-red-secondary" {
  vpc = true

  network_interface = aws_network_interface.poc-vpc-transit-red-secondary.id

  tags = {
    Name = "poc-vpc-transit-red-secondary"
  }

  depends_on = [aws_internet_gateway.poc-vpc-transit-red]
}

resource "aws_security_group" "poc-vpc-transit-red" {
  name   = "poc-vpc-transit-red"
  vpc_id = aws_vpc.poc-vpc-transit-red.id

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
    Name = "poc-vpc-transit-red"
  }
}

resource "aws_network_interface" "poc-vpc-transit-red-primary" {
  subnet_id         = aws_subnet.poc-vpc-transit-red.id
  private_ips       = ["192.168.252.11"]
  security_groups   = [aws_security_group.poc-vpc-transit-red.id]
  source_dest_check = false

  tags = {
    Name = "poc-vpc-transit-red-primary"
  }
}

resource "aws_network_interface" "poc-vpc-transit-red-secondary" {
  subnet_id         = aws_subnet.poc-vpc-transit-red.id
  private_ips       = ["192.168.252.12"]
  security_groups   = [aws_security_group.poc-vpc-transit-red.id]
  source_dest_check = false

  tags = {
    Name = "poc-vpc-transit-red-secondary"
  }
}

resource "aws_instance" "poc-vpc-red-nat-gateway-primary" {
  ami                  = data.aws_ami.amazon-linux.id
  instance_type        = "m4.large"
  key_name             = aws_key_pair.poc-vpc-transit.key_name
  iam_instance_profile = aws_iam_instance_profile.poc-vpc-transit-nat.name

  network_interface {
    network_interface_id = aws_network_interface.poc-vpc-transit-red-primary.id
    device_index         = 0
  }

  tags = {
    Name = "NATPrimary"
    Use  = "poc-vpc-transit-red-nat-primary"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.poc-vpc-transit.private_key_pem
    host        = aws_eip.poc-vpc-transit-red-primary.public_ip
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

resource "aws_instance" "poc-vpc-red-nat-gateway-secondary" {
  ami                  = data.aws_ami.amazon-linux.id
  instance_type        = "m4.large"
  key_name             = aws_key_pair.poc-vpc-transit.key_name
  iam_instance_profile = aws_iam_instance_profile.poc-vpc-transit-nat.name

  network_interface {
    network_interface_id = aws_network_interface.poc-vpc-transit-red-secondary.id
    device_index         = 0
  }

  tags = {
    Name = "NATSecondary"
    Use  = "poc-vpc-transit-red-nat-secondary"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.poc-vpc-transit.private_key_pem
    host        = aws_eip.poc-vpc-transit-red-secondary.public_ip
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
