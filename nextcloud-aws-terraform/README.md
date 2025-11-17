# ☁️ Nextcloud Infrastructure with Terraform on AWS

Este projeto provisiona **toda a infraestrutura necessária** para rodar o Nextcloud na AWS utilizando Terraform, com foco em:

- **Escalabilidade**
- **Segurança**
- **Armazenamento persistente**
- **Boas práticas de arquitetura em nuvem**

---

## 🚀 Componentes provisionados

- **VPC personalizada** com sub-redes públicas e privadas
- **Auto Scaling Group (ASG)** com instâncias EC2 para o Nextcloud
- **Application Load Balancer (ALB)** para acesso público via HTTP/HTTPS
- **Amazon EFS** para armazenamento compartilhado entre instâncias (dados do Nextcloud)
- **Amazon RDS (PostgreSQL)** como banco de dados gerenciado
- **Security Groups segmentados** por função (ALB, EC2, RDS, EFS)
- **Integração com Systems Manager (SSM)** para acesso às instâncias sem SSH aberto
- **(Opcional) CloudFront + WAF** para CDN e proteção na borda
- **Nextcloud via Docker** configurado por script de inicialização (user_data)

---

## 🔧 Pré-requisitos

Você precisa ter:

- Terraform `>= 1.6.0` instalado
- AWS CLI configurado com credenciais válidas
- Permissões na AWS para criar:
  - VPC, Subnets, Internet Gateway, NAT Gateway
  - EC2, ALB, EFS, RDS
  - IAM Roles/Instance Profile
  - (Opcional) CloudFront, WAF, ACM, Route 53

---

## 📦 Como usar (resumo rápido)

```bash
# Inicializar o Terraform
terraform init

# Visualizar o plano de execução
terraform plan

# Aplicar a infraestrutura
terraform apply
## 🎯 Por que este projeto é relevante para o meu portfólio

Este projeto não é “só mais um lab de Terraform”. Ele demonstra, na prática, que eu sei **desenhar, provisionar e operar** uma aplicação real (Nextcloud) em ambiente de nuvem com **boas práticas de arquitetura, segurança e DevOps**. Alguns pontos que este repositório evidencia:

### 🧩 Arquitetura em nuvem bem estruturada (AWS)

- Uso de **serviços gerenciados da AWS**: VPC, EC2, Auto Scaling Group, ALB, EFS, RDS (PostgreSQL), CloudFront, WAF, SNS, AWS Backup, IAM e Systems Manager.
- Separação clara entre **camada pública** (Internet / ALB / CloudFront) e **camada privada** (EC2, RDS, EFS), reforçando **segurança por camadas**.
- Uso de **EFS** para armazenamento compartilhado e **RDS gerenciado** para banco de dados, mostrando preocupação com **persistência e confiabilidade**.

### ⚙️ Infra como Código (IaC) com Terraform

- Código organizado em **módulos lógicos** (`network`, `alb`, `asg_ec2`, `efs`, `rds`, `security_groups`, `iam`, `cloudfront`, `backup`, etc.).
- Uso consistente de:
  - `variables.tf` bem descrito,
  - `outputs.tf` focado em operação,
  - `terraform.tfvars.example` para facilitar replicação do ambiente.
- Boas práticas de Terraform:
  - nomes padronizados,
  - uso de `locals`,
  - `merge(var.tags, {...})` para tagging consistente,
  - separação entre **configuração** e **valores sensíveis** (ex.: `TF_VAR_db_password`).

### 🔐 Segurança e Governança

- **Security Groups** segmentados por função (ALB, EC2, RDS, EFS) com regras de **mínimo privilégio** (least privilege).
- Acesso às instâncias via **AWS Systems Manager (SSM)** em vez de SSH aberto na Internet.
- Suporte a **HTTPS** com ACM e, opcionalmente, **CloudFront + WAF** para proteção na borda.
- Integração com **AWS Backup**, usando tags para selecionar automaticamente recursos críticos (EFS/RDS).

### 📈 Escalabilidade, Resiliência e Operação

- Aplicação rodando em **Auto Scaling Group**, preparada para escalar horizontalmente.
- Separação entre **dados da aplicação (EFS)** e **dados de banco (RDS)**, permitindo recriar instâncias sem perda de dados.
- Estrutura pronta para ser integrada em um **pipeline de CI/CD** (GitHub Actions / GitLab CI / etc.) para automação de `terraform plan` e `terraform apply`.

### 💼 O que este projeto mostra sobre mim, como profissional

- Que eu sei **pensar arquitetura de ponta a ponta**, e não apenas “subir um EC2”.
- Que tenho experiência prática com **AWS + Terraform**, preocupada(o) com:
  - segurança,
  - reuso,
  - organização de código,
  - operação e manutenção.
- Que eu consigo produzir **documentação clara** (README, diagramas, explicação de fluxo de rede e segurança) — algo essencial em times de engenharia, platform, DevOps e SRE.

> Em resumo: este projeto mostra que eu consigo **tirar uma solução completa do zero até a nuvem**, com boas práticas modernas de **Infra as Code, AWS e DevOps**, pronta para ser evoluída em ambiente real.

## 🎯 Why this project matters for my portfolio

This project is not “just another Terraform lab”. It shows that I can **design, provision, and operate** a real-world application (Nextcloud) in the cloud using **AWS, Infrastructure as Code, and DevOps best practices**.  

Here’s what this repository demonstrates:

### 🧩 Well-structured cloud architecture (AWS)

- Use of **managed AWS services**: VPC, EC2, Auto Scaling Group, ALB, EFS, RDS (PostgreSQL), CloudFront, WAF, SNS, AWS Backup, IAM, and Systems Manager.
- Clear separation between **public layer** (Internet / ALB / CloudFront) and **private layer** (EC2, RDS, EFS), following a **defense-in-depth** approach.
- **EFS** for shared storage and **managed RDS** for the database, showing concern with **data persistence and reliability**.

### ⚙️ Infrastructure as Code (IaC) with Terraform

- Code organized into **logical components** (`network`, `alb`, `asg_ec2`, `efs`, `rds`, `security_groups`, `iam`, `cloudfront`, `backup`, etc.).
- Consistent use of:
  - a well-documented `variables.tf`,
  - operation-focused `outputs.tf`,
  - `terraform.tfvars.example` to make the environment easy to reproduce.
- Terraform best practices:
  - consistent naming conventions,
  - use of `locals`,
  - `merge(var.tags, {...})` for unified tagging,
  - clear separation between **configuration** and **sensitive values** (e.g. `TF_VAR_db_password`).

### 🔐 Security and governance

- **Security Groups** segmented by role (ALB, EC2, RDS, EFS) with **least-privilege** rules.
- Instance access via **AWS Systems Manager (SSM)** instead of SSH exposed to the Internet.
- Support for **HTTPS** using ACM and optional **CloudFront + WAF** for edge security.
- Integration with **AWS Backup**, using tags to automatically select critical resources (EFS/RDS).

### 📈 Scalability, resilience and operations

- Application running in an **Auto Scaling Group**, ready for horizontal scaling.
- Separation between **application data (EFS)** and **database data (RDS)**, allowing instances to be recreated without data loss.
- Structure ready to be plugged into a **CI/CD pipeline** (GitHub Actions / GitLab CI / etc.) to automate `terraform plan` and `terraform apply`.

### 💼 What this project says about me as an engineer

- I can **think end-to-end architecture**, not just “launch a single EC2 instance”.
- I have hands-on experience with **AWS + Terraform**, and I care about:
  - security,
  - reusability,
  - clean code organization,
  - operations and maintainability.
- I know how to produce **clear documentation** (README, diagrams, network/security explanations) — which is essential in engineering, platform, DevOps, and SRE teams.

> In short: this project shows that I can take a solution **from zero to a fully working cloud environment**, applying modern **Infrastructure as Code, AWS, and DevOps** practices, and leaving it ready to evolve in a real production scenario.
