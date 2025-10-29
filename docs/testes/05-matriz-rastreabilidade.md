| Requisito                         | Caso(s)  | Evidências principais                        |
|----------------------------------|----------|----------------------------------------------|
| Alta disponibilidade (≤10s)      | HA-001   | 2025-10-24_HA-001_stop-task.png              |
| Persistência EFS (troca de task) | HA-001   | EFS_ls.png; sessão pós-parada                |
| HTTPS enforced                   | SEC-001  | curl-redirect.txt; screenshot cadeado        |
| Escalabilidade < 2 min           | ESC-001  | ECS_runningCount_3.png; ALB-target-healthy   |
| Backups RDS + restore (staging)  | BAK-001  | rds-snapshots.json; print restore ok         |
| Observabilidade                  | OBS-001  | cloudwatch-logs.png; alb-5xx-latency.png     |
