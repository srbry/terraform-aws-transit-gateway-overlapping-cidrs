##########################
#### VPC ROUTING ETC #####
##########################

resource "aws_vpc" "poc-vpc-transit-orange" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "poc-vpc-transit-orange"
  }
}

resource "aws_subnet" "poc-vpc-transit-orange" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.poc-vpc-transit-orange.id
  map_public_ip_on_launch = true

  tags = {
    Name = "poc-vpc-transit-orange"
  }

  depends_on = [aws_internet_gateway.poc-vpc-transit-orange]
}

resource "aws_internet_gateway" "poc-vpc-transit-orange" {
  vpc_id = aws_vpc.poc-vpc-transit-orange.id

  tags = {
    Name = "poc-vpc-transit-orange"
  }
}

resource "aws_route_table" "poc-vpc-transit-orange" {
  vpc_id = aws_vpc.poc-vpc-transit-orange.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.poc-vpc-transit-orange.id
  }

  route {
    cidr_block         = "192.168.254.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.poc-vpc-transit-gateway.id
  }

  tags = {
    Name = "poc-vpc-transit-orange"
  }
}

resource "aws_route_table_association" "poc-vpc-transit-orange" {
  subnet_id      = aws_subnet.poc-vpc-transit-orange.id
  route_table_id = aws_route_table.poc-vpc-transit-orange.id
}


##########################
#### test instance   #####
##########################

resource "aws_security_group" "poc-vpc-transit-orange" {
  name   = "poc-vpc-transit-orange"
  vpc_id = aws_vpc.poc-vpc-transit-orange.id

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
    Name = "poc-vpc-transit-primary"
  }
}


resource "aws_eip" "poc-vpc-transit-orange" {
  vpc = true

  network_interface = aws_network_interface.poc-vpc-transit-orange.id

  tags = {
    Name = "poc-vpc-transit-orange"
  }

  depends_on = [aws_internet_gateway.poc-vpc-transit-orange]
}

resource "aws_network_interface" "poc-vpc-transit-orange" {
  subnet_id       = aws_subnet.poc-vpc-transit-orange.id
  private_ips     = ["10.0.1.100"]
  security_groups = [aws_security_group.poc-vpc-transit-orange.id]

  tags = {
    Name = "poc-vpc-transit-orange"
  }
}

resource "aws_instance" "poc-vpc-transit-orange" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.poc-vpc-transit.key_name

  network_interface {
    network_interface_id = aws_network_interface.poc-vpc-transit-orange.id
    device_index         = 0
  }

  tags = {
    Name = "poc-vpc-transit-orange"
  }
}

##########################
#### Transit gateway #####
##########################


resource "aws_ec2_transit_gateway_route_table" "poc-vpc-transit-orange" {
  transit_gateway_id = aws_ec2_transit_gateway.poc-vpc-transit-gateway.id

  tags = {
    Name = "poc-vpc-transit-orange"
  }
}

resource "aws_ec2_transit_gateway_route" "poc-vpc-transit-orange" {
  destination_cidr_block         = "192.168.254.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.poc-vpc-transit-red.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.poc-vpc-transit-orange.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "poc-vpc-transit-orange" {
  subnet_ids                                      = [aws_subnet.poc-vpc-transit-orange.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.poc-vpc-transit-gateway.id
  vpc_id                                          = aws_vpc.poc-vpc-transit-orange.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "poc-vpc-transit-orange"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "poc-vpc-transit-orange" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.poc-vpc-transit-orange.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.poc-vpc-transit-orange.id
}
