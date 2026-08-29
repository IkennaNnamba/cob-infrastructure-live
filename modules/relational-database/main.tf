locals {
  name_prefix = "cob-${var.team}-${var.environment}-${var.purpose}"

  common_tags = merge(
    {
      Team        = var.team
      Environment = var.environment
      Platform    = "cob"
    },
    var.tags
  )

  db_port = coalesce(var.db_port, var.engine == "postgres" ? 5432 : var.engine == "mysql" ? 3306 : 0)
}

resource "random_password" "master" {
  length  = 20
  special = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${local.name_prefix}-db-credentials"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master.result
  })
}

resource "aws_db_subnet_group" "this" {
  name_prefix = "${local.name_prefix}-"
  subnet_ids  = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-subnet-group"
  })
}

resource "aws_security_group" "this" {
  name_prefix = "${local.name_prefix}-"
  description = "Allows DB access only from explicitly approved security groups"
  vpc_id      = data.aws_subnet.first.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port       = local.db_port
      to_port         = local.db_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_subnet" "first" {
  id = var.private_subnet_ids[0]
}

resource "aws_db_instance" "this" {
  count = var.prevent_destroy ? 0 : 1

  identifier_prefix = "${local.name_prefix}-"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  port           = local.db_port

  allocated_storage = var.allocated_storage_gb
  storage_encrypted = true

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]

  username = var.db_username
  password = random_password.master.result

  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_days
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot"

  tags = local.common_tags
}

resource "aws_db_instance" "this_protected" {
  count = var.prevent_destroy ? 1 : 0

  identifier_prefix = "${local.name_prefix}-"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  port           = local.db_port

  allocated_storage = var.allocated_storage_gb
  storage_encrypted = true

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]

  username = var.db_username
  password = random_password.master.result

  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_days
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot"

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}