
resource "null_resource" "docker_build_push" {
  provisioner "local-exec" {
    command = <<EOT
      docker logout
      docker build -t "${var.registry_base_url}/${var.micro_service}" ${var.micro_service}
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.registry_base_url}
      docker push "${var.registry_base_url}/${var.micro_service}"
      docker logout
    EOT
  }

  triggers = {
    dockerfile = filemd5("${path.root}/${var.micro_service}/Dockerfile")
  }
}
#      docker rmi "${var.registry_base_url}/${var.micro_service}"
