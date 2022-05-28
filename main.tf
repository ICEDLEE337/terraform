resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "main_public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "dev"
  }
}

resource "aws_route_table" "main_public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "dev-public"
  }
}

resource "aws_route" "main_default_route" {
  route_table_id         = aws_route_table.main_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_internet_gateway.id
}


resource "aws_route_table_association" "main_route_table_association" {
  subnet_id      = aws_subnet.main_public_subnet.id
  route_table_id = aws_route_table.main_public_route_table.id
}

resource "aws_security_group" "main_security_group" {
  name        = "dev_security_group"
  description = "Dev Security Group"
  vpc_id      = aws_vpc.main_vpc.id


  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev"
  }
}

resource "aws_key_pair" "main_key" {
  key_name   = "id_ed25519"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "ubuntu" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.ubuntu.id
  key_name               = "id_ed25519"
  vpc_security_group_ids = [aws_security_group.main_security_group.id]
  subnet_id              = aws_subnet.main_public_subnet.id
  user_data              = file("user-data.tpl")

  root_block_device {
    volume_size = 10
  }

  provisioner "local-exec" {
    command = templatefile("ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/id_ed25519"
    })
    interpreter = ["bash", "-c"]
  }
}