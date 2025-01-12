# --------------------------------
#  database
# --------------------------------

# --------------------------------
#  input prameter
variable "env" {
  type = string
}
variable "db" {
  type = object({
    allocated_storage = string
    storage_type      = string
    engine            = string
    version           = string
    instance_class    = string
    db_name           = string
    username          = string
    password          = string

  })
}
variable "network" {
  type = object({
    vpc-id      = string
    # route_table = string
    subnet-public-1a-id            = string
    subnet-public-1c-id           = string
  })
}

variable "ars_list" {}

# RDS
resource "aws_db_subnet_group" "public-db" {
  name       = "${var.env}-public-db"
  subnet_ids = ["${var.network.subnet-public-1a-id}"  , "${var.network.subnet-public-1c-id}" ]
  tags = {
    Name = "${var.env}-public-db"
  }
}

# Security Group
resource "aws_security_group" "public-db-sg" {
  # for_each = var.ars_list.server
  name   = "${var.env}-public-db-sg"
  vpc_id = "${var.network.vpc-id}"
  # count = "${length(var.ars_list.server)}"
  tags = {
    Name = "public-db-sg"
  }
}


resource "aws_security_group_rule" "inbound_ars" {
  for_each = var.ars_list.server
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = [
    "${var.ars_list.server[each.key].ip_address}"
  ]
  description = "ars-${each.key}"
  security_group_id = "${aws_security_group.public-db-sg.id}"
}


resource "aws_security_group_rule" "outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = "${aws_security_group.public-db-sg.id}"
}


resource "aws_db_instance" "db" {
  identifier             = "${var.env}-db"
  allocated_storage      = var.db.allocated_storage
  storage_type           = var.db.storage_type
  engine                 = var.db.engine
  engine_version         = var.db.version
  instance_class         = var.db.instance_class
  db_name                = var.db.db_name
  username               = var.db.username
  password               = var.db.password
  vpc_security_group_ids = ["${aws_security_group.public-db-sg.id}"]
  db_subnet_group_name   = aws_db_subnet_group.public-db.name
  skip_final_snapshot    = true
  publicly_accessible    = true
  backup_retention_period = "7"
  backup_window = "00:00-01:00"
  apply_immediately = "true"
}




# --------------------------------
#  output
output "security_group" {
  value = aws_security_group.public-db-sg
}
