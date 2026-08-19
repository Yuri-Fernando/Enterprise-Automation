# Epic 5 — Observability

**Release alvo:** v0.4 / v1.0 · **Trilha:** Automação Python + Database/Dashboard

## Objetivo
Saber o estado da infraestrutura e dos incidentes a qualquer momento.

## Escopo
- [ ] `automation/inventory/` — inventário via boto3 (EC2, RDS, status)
- [ ] `automation/troubleshooting/health_check.py` — HTTP/porta/processo
- [ ] `automation/troubleshooting/{network,disk,service}_check.py`
- [ ] `automation/troubleshooting/remediation.py` — dispara Ansible/
      PowerShell para corrigir
- [ ] `database/schema.sql` — tabelas `executions`, `incidents`, `inventory`
- [ ] `dashboard/` — HTML/JS/Bootstrap lendo do MySQL (via API simples ou
      JSON estático para dev)
- [ ] Simulação de incidente ponta a ponta (ex.: `INCIDENT #017` do escopo)
      documentada em notebook

## Critérios de aceite
- Health check identifica falha simulada localmente (processo/porta
  derrubados propositalmente) sem depender de AWS real.
- Relatório de incidente gerado em formato legível (markdown/json) e gravado
  no MySQL de dev.
