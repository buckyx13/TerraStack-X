resource "aws_vpc" "this" {
  cidr_block = var.cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = var.name
  }
}

# Lock down th default SG
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-default-do-not-use"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id = aws_vpc.this.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-public-${var.azs[count.index]}",
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id = aws_vpc.this.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-private-${var.azs[count.index]}",
    Tier = "private"
  }
}

locals {
  nat_count = var.single_nat_gateway ? 1 : length(var.azs)
}

resource "aws_eip" "nat" {
  count = local.nat_count
  domain = "vpc"

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${vpc.name}-nat-${count.index}"
  }
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${var.name}-nat-${count.index}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(var.azs)
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-private-${var.azs[count.index]}"
  }
}

resource "aws_route" "private_nat" {
  count = length(var.azs)

  route_table_id = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ---- VPC flow logs -> CloudWatch (encrypted) ----

resource "aws_cloudwatch_log_group" "flow" {
  name = "/vpc/${var.name}/flow-logs"
  retention_in_days = var.flow_log_retention_days
  kms_key_id = var.kms_key_arn
}

# Defining Trust Policy
data "aws_iam_policy_document" "flow_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

# Defining Permissions Policy
data "aws_iam_policy_document" "flow_write" {
   statement {
     actions = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
     resources = ["${aws_cloudwatch_log_group.flow.arn}:*"]
   }
}

resource "aws_iam_role" "flow" {
  name = "${var.name}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_assume.json
}

resource "aws_iam_role_policy" "flow" {
  name = "write-flow-logs"
  role = aws_iam_role.flow.id
  policy = data.aws_iam_policy_document.flow_write.json
}

resource "aws_flow_log" "this" {
  vpc_id = aws_vpc.this.id
  traffic_type = "ALL"
  log_destination = aws_cloudwatch_log_group.flow.arn
  iam_role_arn = aws_iam_role.flow.arn
}