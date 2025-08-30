terraform {
  required_version = "~> 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83"
    }
  }
}

module "network" {
  source   = "../modules/network"
  env      = local.env
  network  = local.network

}

module "db" {
  source   = "../modules/db"
  env      = local.env
  db       = local.db
  network  = module.network
  ars_list = local.ars_ap
}


# module "ec2_win" {
#   source        = "../modules/ec2_win"
#   env           = local.env
#   vpc_id        = module.vpc.vpc_id
#   name_prefix   = local.env
#   subnet_1a_id  = module.public_subnet.subnet_alb_1a_id
#   subnet_1b_id  = module.public_subnet.subnet_alb_1b_id
#   sg_ec2_win_id = module.sg.sg_windows-sg_id
#   instace_spec  = "t3.small"
#   win_ami_id    = "ami-019295d820ae4ccf1" # Windows_Server-2022-Japanese-Full-Base-2023.03.15
# }