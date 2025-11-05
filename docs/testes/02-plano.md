# Plano de Testes — Projeto Nextcloud na AWS
**Versão:** 1.0 | **Data:** 2025-10-24 | **Responsável:** Ana Paula

## Escopo
ECS/ECR (Nextcloud), RDS (MariaDB), EFS, S3 (lifecycle), ACM, Route 53, ALB.

## Fora de escopo
Testes de carga massiva (Gatling/JMeter), pentest formal.

## Critérios de Entrada
- DNS + TLS válidos
- Desired count ≥ 2
- Usuário demo + massas de teste disponíveis

## Critérios de Saída
- 100% dos casos críticos executados
- 0 defeitos críticos abertos
- Riscos residuais documentados e aceitos

## Cronograma
- Ensaio: D-1
- Execução: 15–25 min
- Consolidação e relatório: D+0

## Papéis
- Tester: Ana Paula | Observador: Gestor | Aprovador: PO/Stakeholder
