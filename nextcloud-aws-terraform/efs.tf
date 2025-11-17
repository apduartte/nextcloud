############################################
# EFS - Sistema de arquivos compartilhado
############################################

resource "aws_efs_file_system" "this" {
  creation_token   = "${var.project_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-efs"
  })
}

############################################
# EFS Mount Targets - 1 por subnet privada
############################################

#resource "aws_efs_mount_target" "this" {
#  for_each = toset(module.vpc.private_subnets)
#
#  file_system_id  = aws_efs_file_system.this.id
#  subnet_id       = each.value
#  security_groups = [aws_security_group.efs.id]
#}

resource "aws_efs_mount_target" "this" {
  count = length(module.vpc.private_subnets)
  subnet_id = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

#A solução é usar uma função toset para converter a lista em um conjunto, mas note que o problema é que os valores são desconhecidos.
#Uma abordagem comum é usar o count em vez de for_each quando se trata de listas de valores desconhecidos, ou garantir que a lista seja conhecida. No entanto, no caso do módulo VPC, as subnets são criadas dentro do módulo e, portanto, seus IDs não são conhecidos até que o módulo seja aplicado.
#Alternativamente, podemos adiar a criação do aws_efs_mount_target até que as subnets estejam criadas. Mas note que o erro diz que o Terraform não pode determinar o conjunto de chaves porque os valores são desconhecidos.
#Uma solução é usar o count com base no comprimento da lista de subnets privadas, e então acessar cada subnet por índice. No entanto, o módulo VPC do Terraform AWS não exporta a lista de subnets privadas como um valor conhecido antes do apply? Na verdade, se o módulo VPC for criado no mesmo configuration, então sim, é desconhecido.