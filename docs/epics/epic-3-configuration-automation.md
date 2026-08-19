# Epic 3 — Configuration Automation

**Release alvo:** v0.2 · **Trilha:** Ansible + PowerShell

## Objetivo
Configurar o que o Terraform provisiona: Linux via Ansible, Windows via
PowerShell.

## Escopo
### Linux (Ansible)
- [ ] `ansible/inventory/` — inventário estático de exemplo + suporte a
      inventário dinâmico (a partir do output do Terraform)
- [ ] Role `base`: usuários, grupos, pacotes, firewall (ufw/firewalld)
- [ ] Role `webserver`: instala/configura nginx como serviço systemd
- [ ] Playbook `site.yml` orquestrando as roles
- [ ] `ansible.cfg` + `ansible-lint` config (`.ansible-lint`)

### Windows (PowerShell)
- [ ] Módulo `powershell/modules/InfraOps` com funções: verificar serviços,
      instalar aplicações, criar diretórios, controlar processos, coletar
      info de sistema, consultar eventos
- [ ] Scripts em `powershell/scripts/` reaproveitando o módulo
- [ ] Testes Pester em `powershell/tests/`

## Critérios de aceite
- `ansible-playbook --syntax-check site.yml` ok (via CI, Ubuntu runner).
- Testes Pester rodando localmente (`Invoke-Pester`).
- Nenhuma credencial hardcoded (usar Ansible Vault / variáveis de ambiente).
