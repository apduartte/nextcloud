# ☁️ Nextcloud Infrastructure with Terraform on AWS

Este projeto provisiona a infraestrutura completa para rodar o Nextcloud na AWS usando Terraform, com foco em escalabilidade, segurança e armazenamento persistente.

## 🚀 Componentes Provisionados

- **VPC personalizada** com sub-redes públicas e privadas
- **Auto Scaling Group (ASG)** com instâncias EC2 para o Nextcloud
- **Application Load Balancer (ALB)** para acesso público via HTTP/HTTPS
- **Amazon EFS** para armazenamento compartilhado entre instâncias
- **Amazon RDS (PostgreSQL)** como banco de dados externo
- **Grupos de segurança** segmentados para cada componente
- **Contêiner Docker** com Nextcloud configurado via script de inicialização

## 🔧 Pré-requisitos

- Terraform `>= 1.6.0`
- AWS CLI configurado
- Permissões adequadas para criar recursos na AWS

## 📦 Como usar

```bash
# Inicializar o Terraform
terraform init

# Visualizar o plano de execução
terraform plan

# Aplicar a infraestrutura
terraform apply