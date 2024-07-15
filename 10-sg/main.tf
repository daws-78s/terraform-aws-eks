module "db" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for DB MySQL Instances"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "db"
}

module "ingress" {
  source         = "git::https://github.com/daws-76s/terraform-aws-security-group.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for Ingress controller"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "ingress"
}

module "cluster" {
  source         = "git::https://github.com/daws-76s/terraform-aws-security-group.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for EKS Control plane"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "eks-control-plane"
}

module "node" {
  source         = "git::https://github.com/daws-76s/terraform-aws-security-group.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for EKS node"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "eks-node"
}

module "bastion" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for Bastion Instances"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "bastion"
}

module "vpn" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for VPN Instances"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "vpn"
  ingress_rules = var.vpn_sg_rules
}

resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

# EKS cluster can be accessed from bastion host
resource "aws_security_group_rule" "cluster_bastion" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id = module.cluster.sg_id
}

# EKS control plane accepting all traffic from nodes
resource "aws_security_group_rule" "cluster_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # All traffic
  source_security_group_id = module.node.sg_id
  security_group_id = module.cluster.sg_id
}


# EKS nodes accepting all traffic from control plane
resource "aws_security_group_rule" "node_cluster" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # All traffic
  source_security_group_id = module.cluster.sg_id
  security_group_id = module.node.sg_id
}

# EKS nodes should accept all traffic from nodes with in VPC CIDR range.
resource "aws_security_group_rule" "node_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # All traffic
  cidr_blocks = ["10.0.0.0/16"]
  security_group_id = module.node.sg_id
}

# RDS accepting connections from bastion
resource "aws_security_group_rule" "db_bastion" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "TCP" # All traffic
  source_security_group_id = module.bastion.sg_id
  security_group_id = module.db.sg_id
}

# DB should accept connections from EKS nodes
resource "aws_security_group_rule" "db_node" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "TCP" # All traffic
  source_security_group_id = module.node.sg_id
  security_group_id = module.db.sg_id
}

# Ingress ALB accepting traffic on 443
resource "aws_security_group_rule" "ingress_public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP" # All traffic
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ingress.sg_id
}

# Ingress ALB accepting traffic on 80
resource "aws_security_group_rule" "ingress_public_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP" # All traffic
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ingress.sg_id
}

#
resource "aws_security_group_rule" "node_ingress" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32768
  protocol          = "TCP" # All traffic
  source_security_group_id = module.ingress.sg_id
  security_group_id = module.node.sg_id
}

