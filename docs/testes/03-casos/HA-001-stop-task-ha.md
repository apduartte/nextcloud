---
id: HA-001
titulo: Troca de task sem indisponibilidade perceptível
prioridade: Alta
area: Disponibilidade/HA
pre-condicoes:
  - Desired count ≥ 2 no service `service-nextcloud`
  - Usuário demo autenticado
passos:
  - P1: Listar tasks ativas (AWS CLI)
  - P2: Parar 1 task via `aws ecs stop-task`
  - P3: Usar o Nextcloud (refresh, abrir/baixar arquivo) durante a troca
  - P4: Verificar runningCount e nova task healthy
resultado-esperado:
  - Sem downtime visível (≤ 10s)
  - Sessão ativa; downloads funcionam
  - Nova task criada automaticamente
evidencias:
  - docs/testes/06-evidencias/2025-10-24_HA-001_stop-task.png
  - Saídas CLI com horário (anexar)
status: NÃO EXECUTADO
observacoes: —
