# ☁️ Nextcloud na AWS com Terraform — Migração, Alta Disponibilidade e Otimização de Custos

![Status](https://img.shields.io/badge/status-em%20evolu%C3%A7%C3%A3o-blue?style=flat-square)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-232F3E?style=flat-square&logo=amazonaws&logoColor=white)
![EC2](https://img.shields.io/badge/EC2-Compute-FF9900?style=flat-square&logo=amazonec2&logoColor=white)
![ALB](https://img.shields.io/badge/ALB-Load%20Balancer-FF9900?style=flat-square&logo=amazonaws&logoColor=white)
![RDS](https://img.shields.io/badge/RDS-PostgreSQL-527FFF?style=flat-square&logo=amazonrds&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-DB-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![EFS](https://img.shields.io/badge/EFS-Storage-FF9900?style=flat-square&logo=amazonaws&logoColor=white)
![Route 53](https://img.shields.io/badge/Route%2053-DNS-8C4FFF?style=flat-square&logo=amazonroute53&logoColor=white)
![CloudFront](https://img.shields.io/badge/CloudFront-CDN-8C4FFF?style=flat-square&logo=amazoncloudfront&logoColor=white)
![WAF](https://img.shields.io/badge/AWS%20WAF-Security-DD344C?style=flat-square&logo=amazonaws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Container-2496ED?style=flat-square&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI/CD-2088FF?style=flat-square&logo=githubactions&logoColor=white)

Este repositório consolida **Infraestrutura como Código (IaC)** para migrar e operar o **Nextcloud na AWS** com foco em:
- **redução de custos**,  
- **alta disponibilidade**,  
- **segurança e conformidade**,  
- **backups e recuperação**,  
- **observabilidade e governança (FinOps)**.

> **Importante:** alguns componentes podem ser **opcionais** (ex.: WAF/CloudFront/AWS Backup/Lambda/DataSync), variando conforme o escopo final e o ambiente do cliente.

---

## Sumário
1. [Resumo Executivo](#1-resumo-executivo-objetivo-e-resultados-esperados)  
2. [Solução Proposta](#2-solução-proposta-arquitetura-alvo-na-aws)  
3. [Fluxo de Informações](#3-fluxo-de-informações-como-o-tráfego-e-os-dados-circulam)  
4. [Preservação e Integridade dos Dados](#4-preservação-e-integridade-dos-dados-backups-recuperação-e-risco)  
5. [Segurança e Resiliência](#5-por-que-essa-arquitetura-é-segura-e-resiliente)  
6. [Estrutura do Repositório](#6-estrutura-do-repositório)  
7. [Pré-requisitos](#7-pré-requisitos-ferramentas-e-acessos)  
8. [Como Executar](#8-como-executar-terraform)  
9. [Operação, Observabilidade e FinOps](#9-operação-observabilidade-e-governança-finops)  
10. [Cronograma, Entregáveis, Garantias e Custos](#10-cronograma-entregáveis-garantias-e-custos-referência)  

---

## 1. Resumo Executivo (Objetivo e Resultados Esperados)

### Objetivo
Migrar e otimizar o Nextcloud para uma arquitetura moderna e escalável na AWS, assegurando:

- Redução significativa de custos operacionais  
- Alta disponibilidade e escalabilidade automática  
- Segurança avançada com controle de acesso auditável e conformidade  
- Backups automatizados e prevenção contra perda de dados  
- Monitoramento contínuo e plano de otimizações recorrentes

### Diagnóstico (pontos críticos comuns do ambiente atual)
Cenário típico de legado que esta solução endereça:

- Instância EC2 monolítica (aplicação + banco no mesmo servidor)  
- Ponto único de falha (**SPOF**) com risco de indisponibilidade total  
- Escalabilidade manual com necessidade de janela/downtime  
- Backup manual (cron/rotina operacional) com risco de perda de dados  
- Acesso direto (SSH) com baixa rastreabilidade/auditoria  
- Crescimento de custo sem governança (**FinOps**)  

> Observação (custos): valores e projeções variam conforme região, tráfego, armazenamento e picos de acesso.

---

## 2. Solução Proposta (Arquitetura Alvo na AWS)

A solução adota uma arquitetura altamente disponível e resiliente, priorizando segurança, performance e governança.

### Camada de Borda e DNS
- **Route 53**: DNS com alta disponibilidade  
- **ACM**: certificados SSL/TLS (HTTPS)  
- **CloudFront** *(opcional/conforme escopo)*: CDN com cache e proteção integrada  
- **AWS WAF** *(opcional/conforme escopo)*: camada adicional contra ataques e vulnerabilidades  

### Camada de Aplicação
- **Application Load Balancer (ALB/ELB)**: balanceamento HTTP/HTTPS  
- **Auto Scaling Group (ASG)**: escalabilidade automática conforme demanda  
- **EC2**: instâncias para execução do Nextcloud  
- **Docker + bootstrap** *(opcional/conforme desenho)*: padronização de runtime e provisionamento

### Camada de Dados e Armazenamento
- **Amazon RDS (PostgreSQL) Multi-AZ**: banco com replicação e failover automático  
- **Amazon EFS**: armazenamento elástico compartilhado entre instâncias

### Operação, Segurança e Observabilidade
- **VPC multi-AZ + sub-redes privadas** + **NAT Gateway**: conectividade segura  
- **IAM**: menor privilégio e controle granular de acesso  
- **CloudWatch** *(conforme implementação)*: métricas, logs e alertas  
- **Backups automatizados** *(conforme escopo)*: estratégia de proteção e recuperação  
- **SNS (alertas)** *(conforme escopo)*: notificação de eventos críticos

---

## 3. Fluxo de Informações (Como o Tráfego e os Dados Circulam)

1. Usuário acessa o domínio → Route 53 resolve DNS  
2. *(Opcional)* CloudFront atende conteúdo com baixa latência (cache)  
3. *(Opcional)* WAF inspeciona e bloqueia tráfego malicioso  
4. Tráfego segue para o ALB  
5. ALB distribui requisições para instâncias no ASG/EC2  
6. Aplicação persiste:
   - Arquivos no **EFS**
   - Dados transacionais no **RDS Multi-AZ**
7. Observabilidade via CloudWatch (métricas/logs/alarmes) *(quando configurado)*  
8. Backups garantem restauração e histórico *(quando aplicável)*

---

## 4. Preservação e Integridade dos Dados (Backups, Recuperação e Risco)

A arquitetura foi desenhada para minimizar risco de perda e facilitar recuperação:

- **RDS Multi-AZ**: failover automático + alta continuidade do banco  
- **EFS**: dados persistentes e compartilhados entre múltiplas instâncias  
- **Backups automatizados** *(conforme escopo)*:
  - políticas de retenção definidas em conjunto  
  - versionamento/histórico (quando aplicável)  
  - trilha de auditoria para ações e eventos
- **Rollback seguro**: estratégia de reversão/cutover controlado para preservar disponibilidade e integridade

---

## 5. Por que Essa Arquitetura é Segura e Resiliente

- Sem ponto único de falha: balanceamento + escalabilidade + banco com failover  
- Segurança em camadas: CDN/WAF + segmentação de rede + Security Groups  
- Tráfego criptografado: HTTPS com certificados gerenciados (ACM)  
- Acesso controlado: IAM com menor privilégio e rastreabilidade/auditoria  
- Observabilidade: métricas, logs e alertas para performance e custo  
- Pronta para crescimento: capacidade elástica conforme demanda real do negócio  

---

## 6. Estrutura do Repositório

> Pode variar conforme evolução do projeto, mas o padrão esperado é:

- `.github/workflows/`  
  Workflows de CI (validações e automações)
- `nextcloud-aws-terraform/`  
  Código Terraform principal (infra AWS)
- `docs/terraform/`  
  Evidências e validações técnicas
- `backend.tf`  
  Configuração de backend/state do Terraform (ajuste conforme ambiente)
- `Makefile`  
  Atalhos para rotinas (init/plan/apply/validate)
- `README.md`  
  Documentação do projeto

Recomendação de higiene:
- diretórios locais de IDE (ex.: `.idea`, `.vs`) devem ficar no `.gitignore` quando não fizerem parte do entregável.

---

## 7. Pré-requisitos (Ferramentas e Acessos)

- **Terraform >= 1.6**
- **AWS CLI** configurado
- Credenciais/permissões para criar e gerenciar recursos (VPC, EC2, ALB, EFS, RDS, IAM, CloudWatch, etc.)
- Convenções definidas:
  - região  
  - naming e tags  
  - domínio e Hosted Zone (se aplicável)  
  - estratégia de **state remoto** (recomendado)

---

## 8. Como Executar (Terraform)

> Recomendação: executar via pipeline (CI/CD) ou workstation controlada, com credenciais seguras.

### 8.1 Execução local (referência)
```bash
cd nextcloud-aws-terraform

terraform init
terraform fmt -recursive
terraform validate

terraform plan -out=tfplan
terraform apply tfplan
