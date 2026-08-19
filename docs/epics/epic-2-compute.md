# Epic 2 — Compute

**Release alvo:** v0.4 · **Trilha:** Terraform / IaC

## Objetivo
Camada de computação escalável simulando ambiente enterprise, sem manter
custo fixo elevado.

## Escopo
- [ ] Módulo `compute`: EC2 (Linux + Windows Server), Launch Template
- [ ] Auto Scaling Group parametrizável (`min_size`, `desired_size`,
      `max_size`)
- [ ] Application Load Balancer + target groups
- [ ] Módulo `database`: RDS MySQL (multi-AZ opcional via variável)
- [ ] Outputs de inventário (IPs, IDs) consumíveis pelo Ansible/PowerShell/
      Python (inventário dinâmico)

## Critérios de aceite
- `instance_count`/`asg` parametrizados via `.tfvars.example` (não commitar
  `.tfvars` real).
- Nenhuma instância fixa "always-on" cara por padrão (usar `t3.micro`/
  `t3.small` como default, documentar custo estimado).
