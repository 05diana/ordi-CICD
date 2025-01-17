
module "build" {
  source            = "./modules/images"
  region            = var.region
  micro_service     = var.micro_service
  registry_base_url = data.terraform_remote_state.iasc.outputs.registry_base_url
}

module "ecs_service" {
  source              = "./modules/ecs_service"
  micro_service       = var.micro_service
  vpc_id              = data.terraform_remote_state.iasc.outputs.vpc_id
  vpc_cidr            = data.terraform_remote_state.iasc.outputs.vpc_cidr
  domain_name         = data.terraform_remote_state.iasc.outputs.domain_name
  db_user             = data.terraform_remote_state.iasc.outputs.db_user
  db_name             = data.terraform_remote_state.iasc.outputs.db_name
  db_pass             = data.terraform_remote_state.iasc.outputs.db_password
  db_host             = data.terraform_remote_state.iasc.outputs.db_instance_endpoint
  cluster_arn         = data.terraform_remote_state.iasc.outputs.cluster_arn
  db_sq_id            = data.terraform_remote_state.iasc.outputs.postgresql_sg_id
  public_subnet_ids   = data.terraform_remote_state.iasc.outputs.public_subnet_ids
  private_subnet_ids  = data.terraform_remote_state.iasc.outputs.private_subnet_ids
  ssl_certificate_arn = data.terraform_remote_state.iasc.outputs.ssl_certificate_arn
  registry_image      = "${data.terraform_remote_state.iasc.outputs.registry_base_url}/${var.micro_service}:latest"
}
