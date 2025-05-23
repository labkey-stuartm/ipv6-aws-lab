provider "aws" {
  region  = var.region
#  profile = var.aws_profile_name
}

# Import the VPC resources
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../01_vpc/terraform.tfstate"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "v6LabSG" {
  description = "Allow SSH/HTTP(S)/ICMP inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["144.202.87.91/32"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ICMPv4 from anywhere"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ICMPv6 from anywhere"
    from_port        = -1
    to_port          = -1
    protocol         = "icmpv6"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "v6LabSG"
    Environment = "v6Lab"

  }
}

# EC2 in a dual-stack public subnet
resource "aws_network_interface" "eni_v6LabPublicEC2DualStack" {
  subnet_id       = data.terraform_remote_state.vpc.outputs.public_subnets[0].id
  security_groups = [aws_security_group.v6LabSG.id]
  # ipv6_prefix_count = 1
  # $ echo "ibase=16; DEADBEEF" | bc
  # 3735928559
  ipv6_addresses  = [cidrhost(data.terraform_remote_state.vpc.outputs.public_subnets[0].ipv6_cidr_block, 3735928559)]

  tags = {
    Name        = "eni_v6LabPublicEC2DualStack"
    Environment = "v6Lab"
  }
}

resource "aws_instance" "v6LabPublicEC2DualStack" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.medium"
  key_name      = var.ssh_key_name


  network_interface {
    network_interface_id = aws_network_interface.eni_v6LabPublicEC2DualStack.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name        = "v6LabPublicEC2DualStack"
    Environment = "v6Lab"
  }
}

# EC2 in a dual-stack private subnet
resource "aws_network_interface" "eni_v6LabPrivateEC2DualStack" {
  subnet_id       = data.terraform_remote_state.vpc.outputs.private_subnets[0].id
  security_groups = [aws_security_group.v6LabSG.id]
  # $ echo "ibase=16; C01DCAFE" | bc
  # 3223177982
  ipv6_addresses  = [cidrhost(data.terraform_remote_state.vpc.outputs.private_subnets[0].ipv6_cidr_block, 3223177982)]

  tags = {
    Name        = "eni_v6LabPublicEC2DualStack"
    Environment = "v6Lab"
  }
}

resource "aws_instance" "v6LabPrivateEC2DualStack" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.medium"
  key_name      = var.ssh_key_name


  network_interface {
    network_interface_id = aws_network_interface.eni_v6LabPrivateEC2DualStack.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name        = "v6LabPrivateEC2DualStack"
    Environment = "v6Lab"
  }
}

# EC2 instance in an IPv6-only public subnet
resource "aws_network_interface" "eni_v6LabPublicEC2IPv6Only" {
  subnet_id       = data.terraform_remote_state.vpc.outputs.public6only_subnets[0].id
  security_groups = [aws_security_group.v6LabSG.id]
  # ipv6_prefix_count = 1
  # $ echo "ibase=16; FACEB00C" | bc
  # 4207849484
  ipv6_addresses  = [
    cidrhost(data.terraform_remote_state.vpc.outputs.public6only_subnets[0].ipv6_cidr_block, 4207849484)
  ]

  tags = {
    Name        = "eni_v6LabPublicEC2IPv6Only"
    Environment = "v6Lab"
  }
}

resource "aws_instance" "v6LabPublicEC2IPv6Only" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.medium"
  key_name      = var.ssh_key_name


  network_interface {
    network_interface_id = aws_network_interface.eni_v6LabPublicEC2IPv6Only.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name        = "v6LabPublicEC2IPv6Only"
    Environment = "v6Lab"
  }
}

# EC2 instance in an IPv6-only private subnet
resource "aws_network_interface" "eni_v6LabPrivateEC2IPv6Only" {
  subnet_id       = data.terraform_remote_state.vpc.outputs.private6only_subnets[0].id
  security_groups = [aws_security_group.v6LabSG.id]
  # $ echo "ibase=16; BADCAFE" | bc
  # 195939070
  ipv6_addresses  = [
    cidrhost(data.terraform_remote_state.vpc.outputs.private6only_subnets[0].ipv6_cidr_block, 195939070)
  ]

  tags = {
    Name        = "eni_v6LabPrivateEC2IPv6Only"
    Environment = "v6Lab"
  }
}

resource "aws_instance" "v6LabPrivateEC2IPv6Only" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.medium"
  key_name      = var.ssh_key_name


  network_interface {
    network_interface_id = aws_network_interface.eni_v6LabPrivateEC2IPv6Only.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name        = "v6LabPrivateEC2IPv6Only"
    Environment = "v6Lab"
  }
}
