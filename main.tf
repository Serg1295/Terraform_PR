provider "aws" {
  region = var.region
}

#---Creating VPC and (public-private) subnets for our network-----
resource "aws_vpc" "VPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "VPC_MAIN"
  }
}
resource "aws_default_vpc" "Default_VPC" {
  tags = {
    Name = "Default_VPC"
  }
}
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}
resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}
resource "aws_default_subnet" "default_az3" {
  availability_zone = data.aws_availability_zones.available.names[2]
}
resource "aws_internet_gateway" "IGW" { #--internet getaway for vpc
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "IGW_VPC_MAIN"
  }
}

resource "aws_subnet" "Public-A" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public_subnet-A"
  }
}

resource "aws_subnet" "Public-B" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public_subnet-B"
  }
}
resource "aws_subnet" "Public-C" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.30.0/24"
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public_subnet-C"
  }
}
resource "aws_subnet" "Private-A" {
  vpc_id            = aws_vpc.VPC.id
  cidr_block        = "10.0.110.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "Private_subnet-A"
  }
}
resource "aws_subnet" "Private-B" {
  vpc_id            = aws_vpc.VPC.id
  cidr_block        = "10.0.120.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "Private_subnet-B"
  }
}
resource "aws_subnet" "Private-C" {
  vpc_id            = aws_vpc.VPC.id
  cidr_block        = "10.0.130.0/24"
  availability_zone = data.aws_availability_zones.available.names[2]
  tags = {
    Name = "Private_subnet-C"
  }
}

#---Create rout table and add rout to internet gateway -----

resource "aws_route_table" "VPC_Public_Route" {
  vpc_id = aws_vpc.VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  route {
    cidr_block                = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.Peer_to_Def.id
  }
  tags = {
    Name = "VPC_Public_Route"
  }
}
resource "aws_route_table" "VPC_Private_Route" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block                = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.Peer_to_Def.id
  }
  tags = {
    Name = "VPC_Private_Route"
  }
}
resource "aws_route_table_association" "Association_Private_A" {
  subnet_id      = aws_subnet.Private-A.id
  route_table_id = aws_route_table.VPC_Private_Route.id
}
resource "aws_route_table_association" "Association_Private_B" {
  subnet_id      = aws_subnet.Private-B.id
  route_table_id = aws_route_table.VPC_Private_Route.id
}
resource "aws_route_table_association" "Association_Private_C" {
  subnet_id      = aws_subnet.Private-C.id
  route_table_id = aws_route_table.VPC_Private_Route.id
}
resource "aws_route_table_association" "Association_Public_A" {
  subnet_id      = aws_subnet.Public-A.id
  route_table_id = aws_route_table.VPC_Public_Route.id
}
resource "aws_route_table_association" "Association_Public_B" {
  subnet_id      = aws_subnet.Public-B.id
  route_table_id = aws_route_table.VPC_Public_Route.id
}
resource "aws_route_table_association" "Association_Public_C" {
  subnet_id      = aws_subnet.Public-C.id
  route_table_id = aws_route_table.VPC_Public_Route.id
}
resource "aws_route_table_association" "Association_Default_az1" {
  subnet_id      = aws_default_subnet.default_az1.id
  route_table_id = aws_default_vpc.Default_VPC.default_route_table_id
}
resource "aws_route_table_association" "Association_Default_az2" {
  subnet_id      = aws_default_subnet.default_az2.id
  route_table_id = aws_default_vpc.Default_VPC.default_route_table_id
}
resource "aws_route_table_association" "Association_Default_az3" {
  subnet_id      = aws_default_subnet.default_az3.id
  route_table_id = aws_default_vpc.Default_VPC.default_route_table_id
}
#---Vpc peering VPC_MAIN -> default VPC ----------------------
resource "aws_vpc_peering_connection" "Peer_to_Def" {
  peer_vpc_id = data.aws_vpc.default.id
  vpc_id      = aws_vpc.VPC.id
  auto_accept = true
}

resource "aws_route" "Default_Rout" {
  route_table_id            = aws_default_vpc.Default_VPC.default_route_table_id
  destination_cidr_block    = aws_vpc.VPC.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.Peer_to_Def.id
}
#-------------------------------------------------------------------
resource "aws_security_group" "SG_EC2_Ruby" {
  name   = "SG_EC2_Ruby"
  vpc_id = aws_vpc.VPC.id

  dynamic "ingress" {
    for_each = ["3000", "22"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG_EC2_Ruby"
  }
}
resource "aws_instance" "EC2_Ruby" {
  ami                    = split(":",local.artifact_id[0])[1]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.Public-A.id
  vpc_security_group_ids = [aws_security_group.SG_EC2_Ruby.id]
  private_ip             = cidrhost(aws_subnet.Public-A.cidr_block, 6)
  key_name               = data.aws_key_pair.Frankfurt_key.key_name
  #user_data              = file("UserData.sh")
  tags = {
    Name = "EC2_Ruby"
  }
}
#----------------------------------------------------------------------
resource "aws_db_subnet_group" "DB_Subnet_Group" {
  subnet_ids = [aws_subnet.Private-A.id, aws_subnet.Private-B.id]

  tags = {
    Name = "DB_subnet_group"
  }
}
resource "aws_security_group" "SG_DB_MySQL" {
  name   = "SG_DB_MySQl"
  vpc_id = aws_vpc.VPC.id

  dynamic "ingress" {
    for_each = ["3306"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.VPC.cidr_block]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG_DB_MySQL"
  }
}
resource "aws_db_instance" "MySQL_DB" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "foo"
  password               = "foobarbaz"
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.DB_Subnet_Group.name
  vpc_security_group_ids = [aws_security_group.SG_DB_MySQL.id]
  skip_final_snapshot    = true
}