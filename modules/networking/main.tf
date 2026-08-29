locals {
  name_prefix = "cob-${var.team}-${var.environment}"

  common_tags = merge(
    {
      Team        = var.team
      Environment = var.environment
      Platform    = "cob"
    },
    var.tags
  )

  # dev is always forced to a single NAT gateway, only prod respects the caller's choice
  effective_single_nat = var.environment == "prod" ? var.single_nat_gateway : true
  nat_gateway_count    = var.enable_nat_gateway ? (local.effective_single_nat ? 1 : length(var.azs)) : 0

  # sanity check that subnets actually belong to the VPC's range.
  vpc_network_octets = join(".", slice(split(".", split("/", var.vpc_cidr)[0]), 0, 2))

  subnets_match_vpc = alltrue([
    for cidr in concat(var.public_subnet_cidrs, var.private_subnet_cidrs) :
    startswith(cidr, local.vpc_network_octets)
  ])

  lists_are_same_length = (
    length(var.azs) == length(var.public_subnet_cidrs) &&
    length(var.azs) == length(var.private_subnet_cidrs)
  )
}


resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })

  lifecycle {
    precondition {
      condition     = local.subnets_match_vpc
      error_message = "One or more subnet CIDRs don't fall inside vpc_cidr (${var.vpc_cidr}). Check public_subnet_cidrs and private_subnet_cidrs."
    }
  
    precondition {
      condition     = local.lists_are_same_length
      error_message = "azs, public_subnet_cidrs, and private_subnet_cidrs must all be the same length."
    }
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${var.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${var.azs[count.index]}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip-${count.index}"
  })
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? (local.effective_single_nat ? 1 : length(var.azs)) : 1
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = local.effective_single_nat ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt-${count.index}"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = (var.enable_nat_gateway && !local.effective_single_nat) ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

resource "aws_security_group" "default" {
  name_prefix = "${local.name_prefix}-default-"
  description = "Baseline SG for ${local.name_prefix}, deny inbound by default"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-default-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}