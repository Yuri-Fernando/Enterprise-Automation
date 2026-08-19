# Arquitetura

Visão detalhada do diagrama em [`README.md`](../README.md).

## Componentes e responsabilidades

| Camada | Tecnologia | Responsabilidade |
|--------|-----------|-------------------|
| Provisionamento | Terraform | Cria toda a infraestrutura AWS (VPC, subnets, SG, EC2, RDS, IAM, S3, CloudWatch, ALB, ASG) de forma declarativa e versionada |
| Configuração Linux | Ansible | Instala dependências, configura serviços systemd, usuários, firewall nas instâncias Linux provisionadas |
| Configuração Windows | PowerShell | Equivalente ao Ansible para Windows Server: serviços, processos, diretórios, eventos |
| Orquestração/Inteligência | Python (automation/) | CLI/controller que dispara Ansible/PowerShell, faz inventário via boto3, roda health checks e remediação |
| Self-healing | Python (automation/troubleshooting/) | Detecta falha → coleta diagnóstico (logs, CPU, RAM, portas) → identifica causa → executa remediation → valida recuperação → gera relatório de incidente |
| Persistência | MySQL (RDS em prod, Docker em dev) | Registra execuções, inventário e incidentes |
| Observabilidade | Dashboard (HTML/JS/Bootstrap) + CloudWatch | Mostra inventário, status e histórico de incidentes |
| CI/CD | GitHub Actions | Valida Terraform (fmt/validate/plan), roda scanners de segurança (checkov/tflint), lint Ansible, testes Python/Pester |
| Segurança/Governança | IAM least-privilege, checkov, tags obrigatórias, Secrets Manager/GitHub Secrets | Bloqueia infra insegura no pipeline, evita credenciais no Git |

## Fluxo de um incidente (self-healing)

```
Serviço cai
   ↓
Health Check (Python) detecta falha
   ↓
Coleta logs + CPU + RAM + portas (+ CloudWatch se AWS)
   ↓
Diagnóstico de causa raiz
   ↓
Executa remediation playbook (Ansible/PowerShell)
   ↓
Reinicia serviço
   ↓
Valida recuperação (novo health check)
   ↓
Grava incidente no MySQL + gera relatório
```

## Ambientes

| Ambiente | Onde roda | Custo |
|----------|-----------|-------|
| `dev` (Terraform) | AWS `sa-east-1`, aplicado manualmente pelo usuário | Real, sob demanda |
| CI (`terraform plan`) | GitHub Actions | Zero (não aplica) |
| Testes Python | Local / CI, com `moto` mockando boto3 | Zero |
| MySQL dev | Docker local (`database/docker-compose.yml`) | Zero |
| Dashboard dev | Servido estático localmente | Zero |

## Decisões de arquitetura

Ver histórico completo em [`../PROJECT_LOG.md`](../PROJECT_LOG.md#decisões-chave).
