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
  tags = {
    Name = "VPC_Public_Route"
  }
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
resource "aws_iam_role" "SSM_Read_Only" {
  name = "SSM_Read_Only"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "SSM_Read_Only"
  }
}
resource "aws_iam_role_policy_attachment" "Attach_SSM_Access" {
  role       = aws_iam_role.SSM_Read_Only.name
  policy_arn = data.aws_iam_policy.AmazonSSmReadOnlyAccess.arn
}
resource "aws_iam_instance_profile" "SSMReadAccessProfile" {
  name = "SSMReadAccessProfile"
  role = aws_iam_role.SSM_Read_Only.name
}
resource "aws_eip" "E_IP" {
  instance = aws_instance.EC2_Ruby.id
  vpc      = true
}
resource "aws_instance" "EC2_Ruby" {
  ami                    = split(":", local.artifact_id[0])[1]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.Public-A.id
  vpc_security_group_ids = [aws_security_group.SG_EC2_Ruby.id]
  iam_instance_profile   = aws_iam_instance_profile.SSMReadAccessProfile.name
  key_name               = data.aws_key_pair.Frankfurt_key.key_name
  user_data              = file("UserData.sh")
  tags = {
    Name = "EC2_Ruby"
  }
  lifecycle {
    create_before_destroy = true
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
  username               = "P161App"
  password               = random_password.db_password.result
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.DB_Subnet_Group.name
  vpc_security_group_ids = [aws_security_group.SG_DB_MySQL.id]
  skip_final_snapshot    = true
}
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
resource "aws_ssm_parameter" "DB_Secret" {
  name        = "DB_PASSWORD"
  description = "Password for DB"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = {
    Name = "DB_PASSWORD"
  }
}
resource "aws_ssm_parameter" "DB_URL" {
  name        = "DB_URL"
  description = "DB_URL"
  type        = "String"
  value       = aws_db_instance.MySQL_DB.address
  tags = {
    Name = "DB_URL"
  }
}
resource "aws_ssm_parameter" "DB_USER" {
  name        = "DB_USER"
  description = "DB_USER"
  type        = "String"
  value       = aws_db_instance.MySQL_DB.username

  tags = {
    Name = "DB_USER"
  }
}