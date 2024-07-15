data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project_name}/${var.environment}/vpc_id"
}

data "aws_ssm_parameter" "cluster_sg_id" {
  name = "/${var.project_name}/${var.environment}/cluster_sg_id"
}

data "aws_ssm_parameter" "node_sg_id" {
  name = "/${var.project_name}/${var.environment}/node_sg_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/private_subnet_ids"
}



data "aws_vpc" "default" {
  default = true
}