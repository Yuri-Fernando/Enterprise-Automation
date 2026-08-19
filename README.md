# Enterprise Cloud Automation & Infrastructure Platform

Terraform-first AWS infrastructure automation with CI/CD, Ansible,
PowerShell, security governance and automated troubleshooting.

> Projeto de portfólio pessoal (Yuri Fernando Dubbern), inspirado pelos
> requisitos técnicos de uma vaga pública de Enterprise Automation Engineer.
> Não é software da Caterpillar nem a representa — é uma plataforma de
> automação de infraestrutura corporativa simulada, construída para
> demonstrar Terraform, Ansible, PowerShell, CI/CD, AWS, segurança/governança
> e troubleshooting automatizado (self-healing). Origem do escopo:
> [`escopo.md`](escopo.md).

## Arquitetura

```
                        GitHub
                          │
                    Pull Request
                          │
                          ▼
                  GitHub Actions
               ┌──────────┴──────────┐
               │                     │
        terraform fmt/validate   Security Scan
               │               (checkov / tflint)
               ▼                     │
          terraform plan             │
               │                     │
               └──────────┬──────────┘
                          ▼
                    Terraform Apply *
                          │
                          ▼
                         AWS
          ┌───────────────┼────────────────┐
          │               │                │
         VPC             EC2              RDS
          │               │                │
     Subnets / SG      Linux/Windows     MySQL
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
             Ansible            PowerShell
                │                   │
        Linux configuration    Windows automation
                │                   │
                └─────────┬─────────┘
                          ▼
              Automation Controller (Python)
                          │
                ┌─────────┼─────────┐
                ▼         ▼         ▼
          Health Check  Inventory  Remediation
           (RCA/self-healing, boto3, MySQL)
                          │
                          ▼
                Bootstrap Dashboard (JS/Bootstrap)
```

`*` `terraform apply` é uma etapa manual/deliberada (gera custo real na AWS) —
ver [`docs/setup/aws-setup.md`](docs/setup/aws-setup.md). Por padrão, o CI
roda apenas `fmt`, `validate`, `plan` e scanners de segurança.

## Stack

Terraform · Ansible · PowerShell · Python (boto3) · GitHub Actions · AWS
(VPC, EC2, RDS/MySQL, IAM, S3, CloudWatch) · MySQL · Docker · JavaScript /
Bootstrap.

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `terraform/` | Módulos (networking, compute, database, iam, monitoring, security) + environments dev/staging/prod |
| `ansible/` | Roles e playbooks de configuração Linux |
| `powershell/` | Módulos e scripts de automação Windows + testes Pester |
| `automation/` | Controller Python, troubleshooting/self-healing, inventário via boto3 |
| `workloads/serverless/` | Espaço reservado para o workload serverless (projeto AWS a incorporar) |
| `database/` | Schema MySQL (execuções, incidentes, inventário) |
| `dashboard/` | Dashboard estático de observabilidade |
| `notebooks/` | Um notebook Jupyter executável por etapa do roadmap |
| `tests/` | Testes agregados |
| `docs/` | Arquitetura, epics, guias de setup, logs por trilha |

## Roadmap (releases)

| Versão | Foco |
|--------|------|
| v0.1 | Terraform Foundation (VPC, EC2, IAM, S3) |
| v0.2 | Automation (Ansible + PowerShell, Linux + Windows) |
| v0.3 | DevOps (CI/CD, terraform plan, security scan) |
| v0.4 | Enterprise (Load Balancer, Auto Scaling, RDS, monitoring) |
| v1.0 | Self-healing (troubleshooting automatizado, governança, docs) |

Detalhes por sprint/epic em [`docs/epics/`](docs/epics/). Histórico de
decisões e sessões de trabalho em [`PROJECT_LOG.md`](PROJECT_LOG.md).
Changelog por versão em [`CHANGELOG.md`](CHANGELOG.md).

## Quickstart

Guia completo em [`docs/setup/local-dev-setup.md`](docs/setup/local-dev-setup.md).

```bash
# Terraform (validação, sem custo)
cd terraform/environments/dev
terraform init -backend=false
terraform validate

# Testes Python (automation/)
python -m pytest tests/python -v

# Notebooks
jupyter lab notebooks/
```

## Autor

Yuri Fernando Dubbern — Pesquisador em IA Aplicada / AI-ML Data Engineer.
