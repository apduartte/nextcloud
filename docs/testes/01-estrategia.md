# Estratégia de Testes — Projeto Nextcloud na AWS
**Versão:** 1.0 | **Data:** 2025-10-24 | **Responsável:** Ana Paula

## Objetivo
Validar disponibilidade (HA), persistência (EFS), segurança (TLS/SG), escalabilidade (ECS),
backup/restore (RDS, S3) e observabilidade (CloudWatch).

## Abordagem
- Níveis: funcional, integração, resiliência/HA, segurança básica, não-funcionais (métricas).
- Tipos: manual guiado + scripts AWS CLI (evidências).
- Critérios de aceite (alto nível):
  - Sem downtime perceptível na troca de task (≤ 10s).
  - Dados persistem via EFS após reciclo de task.
  - HTTPS enforced, SGs mínimos.
  - Desired count ↑ cria task healthy em < 2 min.
  - Snapshots automáticos e restore validado (staging).

## Riscos e mitigação
- RDS failover ao vivo → mostrar só evidência (staging).
- Desired count baixo → garantir ≥2 antes do demo.

## Ferramentas
Navegador, AWS Console/CLI, Nextcloud UI, planilhas e scripts.
