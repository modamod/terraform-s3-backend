// This template is to build all the networking components required to spin up an ec2 instance.



// Resources to build
resource "aws_vpc" "myvpc" {
  tags       = var.tags
  cidr_block = var.vpc_cidr

}

resource "aws_eip" "eips" {
  count = length(var.azs)
  tags  = var.tags
  vpc   = true
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  tags   = var.tags
}

resource "aws_nat_gateway" "natgateway" {
  count         = length(var.azs)
  tags          = var.tags
  allocation_id = aws_eip.eips[count.index].allocation_id
  depends_on = [
    aws_internet_gateway.igw
  ]
  subnet_id = aws_subnet.public_subnet[count.index].id
}


resource "aws_subnet" "private_subnet" {
  count             = length(var.azs)
  tags              = var.tags
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.azs[count.index]
  vpc_id            = aws_vpc.myvpc.id

}



resource "aws_subnet" "public_subnet" {
  count                   = length(var.azs)
  map_public_ip_on_launch = true
  tags                    = var.tags
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, length(var.azs) + count.index)
  availability_zone       = var.azs[count.index]
  vpc_id                  = aws_vpc.myvpc.id


}


resource "aws_route_table" "private_rt" {
  count  = length(var.azs)
  vpc_id = aws_vpc.myvpc.id
  tags   = var.tags
}

resource "aws_route" "private_route" {
  count                  = length(var.azs)
  nat_gateway_id         = aws_nat_gateway.natgateway[count.index].id
  route_table_id         = aws_route_table.private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}


resource "aws_route_table_association" "private_rt_association" {
  count          = length(var.azs)
  route_table_id = aws_route_table.private_rt[count.index].id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.myvpc.id
  tags   = var.tags
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_rt_association" {
  count          = length(var.azs)
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

resource "aws_security_group" "allow_access" {
  name        = "allow_access"
  description = "Allow TLS and SSH inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from world"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.myvpc.cidr_block]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "TLS from world"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "ssh from the world"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
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

}

resource "aws_launch_template" "lt" {
  image_id               = var.ami_id
  instance_type          = var.instance_type
  user_data              = filebase64("${path.module}/data/user_data.sh")
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_access.id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.ip.arn
  }
}

resource "aws_iam_policy" "fullaccess" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "role" {
  name = "role"
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
      }
    ]
  })
}
resource "aws_iam_instance_profile" "ip" {
  role = aws_iam_role.role.name
}

resource "aws_iam_policy_attachment" "policyattach" {
  policy_arn = aws_iam_policy.fullaccess.arn
  name       = "fullaccess_policy_attach"
  roles      = [aws_iam_role.role.name]
}

resource "aws_key_pair" "keypair" {
  key_name = var.key_name
  public_key = file(pathexpand(var.pub_key_path))
}


resource "aws_autoscaling_group" "asg" {
  name                = var.asg_name
  vpc_zone_identifier = [for item in concat(aws_subnet.public_subnet, aws_subnet.private_subnet) : item.id]

  launch_template {
    id      = aws_launch_template.lt.id
    version = aws_launch_template.lt.latest_version
  }
  max_size         = 3
  desired_capacity = 1
  min_size         = 1
  instance_refresh {
    strategy = "Rolling"
  }
  target_group_arns = [ aws_alb_target_group.alb_target_group.arn]
  depends_on = [
    aws_launch_template.lt,
    aws_key_pair.keypair
  ]

}

resource "aws_alb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_access.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]

}

resource "aws_alb_listener" "tls_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.alb_target_group.arn
  }
  depends_on = [
    aws_acm_certificate_validation.acm_validation,
  ]
  lifecycle {
    replace_triggered_by = [
      aws_alb_target_group.alb_target_group
    ]
  }
}

resource "aws_alb_listener_certificate" "lister_certificates" {
  certificate_arn = aws_acm_certificate.cert.arn
  listener_arn    = aws_alb_listener.tls_listener.arn
}


resource "aws_alb_target_group" "alb_target_group" {
  name        = "alb-tg80"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.myvpc.id
}
