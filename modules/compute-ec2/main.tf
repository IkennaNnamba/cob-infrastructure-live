locals {
  name_prefix = "cob-${var.team}-${var.environment}-${var.purpose}"

  common_tags = merge(
    {
      Team        = var.team
      Environment = var.environment
      ManagedBy   = "terraform"
      Platform    = "cob"
    },
    var.tags
  )
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "this" {
  name_prefix = "${local.name_prefix}-"
  description = "SG for ${local.name_prefix}"
  vpc_id      = data.aws_subnet.selected.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
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

data "aws_subnet" "selected" {
  id = var.subnet_id
}

resource "aws_iam_instance_profile" "this" {
  count = var.attach_iam_role ? 1 : 0
  name  = "${local.name_prefix}-profile"
  role  = var.iam_role_name
}

resource "aws_instance" "this" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  associate_public_ip_address = var.assign_public_ip

  iam_instance_profile = var.iam_role_name != "" ? aws_iam_instance_profile.this[0].name : null

  root_block_device {
    volume_size = var.root_volume_size_gb
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}"
  })
}