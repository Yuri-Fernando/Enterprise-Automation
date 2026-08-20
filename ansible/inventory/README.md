# Inventário — estático e dinâmico

## Estático (`hosts.example.ini`)

Ponto de partida rápido, sem dependência do Terraform. Grupos:

- `[linux_web]` — instâncias que recebem a role `webserver` (nginx).
- `[linux_db]` — instâncias de banco (hoje só recebem a role `base`;
  não há role de banco Linux nesta trilha — RDS MySQL é gerenciado via
  Terraform, ver `terraform/modules/database`).
- `[linux:children]` — agrega `linux_web` + `linux_db` para a role `base`
  (usuários, pacotes, firewall, hardening) ser aplicada a todos os hosts.

Copie `hosts.example.ini` para `hosts.ini` (não versionar hosts/IPs reais de
produção) e ajuste `ansible_host`/`ansible_user` com os valores reais das
instâncias EC2 criadas pelo Terraform.

```bash
cp ansible/inventory/hosts.example.ini ansible/inventory/hosts.ini
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml
```

## Dinâmico (`dynamic_inventory.py`)

Gera o inventário a partir de `terraform output -json`, para não manter IPs
manualmente sincronizados com o que o Terraform provisiona. É um **exemplo**
funcional na forma (protocolo `--list`/`--host` do Ansible), mas depende de
outputs que o módulo `terraform/modules/compute` ainda não expõe (essa
trilha está sendo construída em paralelo — ver `PROJECT_LOG.md`).

Convenção esperada quando os outputs existirem:

```hcl
output "web_instances" {
  value = [
    for i in aws_instance.web : {
      name       = i.tags["Name"]
      private_ip = i.private_ip
      ssh_user   = "ec2-user"
    }
  ]
}

output "db_instances" {
  value = [
    for i in aws_instance.db : {
      name       = i.tags["Name"]
      private_ip = i.private_ip
      ssh_user   = "ec2-user"
    }
  ]
}
```

Uso:

```bash
# Opção A — terraform ao vivo (precisa de state + credenciais AWS acessíveis)
export TF_ENV_DIR=terraform/environments/dev
ansible-playbook -i ansible/inventory/dynamic_inventory.py ansible/playbooks/site.yml

# Opção B — outputs pré-exportados (útil em CI, sem credenciais no passo de inventário)
cd terraform/environments/dev && terraform output -json > /tmp/tf-outputs.json
cd -
ANSIBLE_TF_OUTPUTS=/tmp/tf-outputs.json \
  ansible-playbook -i ansible/inventory/dynamic_inventory.py ansible/playbooks/site.yml

# Inspecionar o inventário sem rodar playbook
ansible-inventory -i ansible/inventory/dynamic_inventory.py --list
```

Se `terraform output -json` falhar (sem state, sem terraform instalado, sem
outputs), o script registra um aviso em stderr e retorna um inventário vazio
(`linux_web`/`linux_db` sem hosts) em vez de quebrar — seguro para rodar em
ambientes onde o Terraform ainda não foi aplicado.

### Limitação Windows

Nenhum dos dois modos roda `ansible-playbook` nativamente no Windows (módulo
`grp` é POSIX-only). Use WSL, um devcontainer Linux, ou confie no GitHub
Actions (Ubuntu runner) — ver `ansible/README.md` na raiz de `ansible/`.
