data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Tier = "private"
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

locals {
  az_count = length(distinct([for s in data.aws_subnet.private : s.availability_zone]))
}

resource "terraform_data" "validate_azs" {
  lifecycle {
    precondition {
      condition     = local.az_count >= 2
      error_message = "EKS requires subnets in at least 2 availability zones, but only ${local.az_count} found."
    }
  }
}
