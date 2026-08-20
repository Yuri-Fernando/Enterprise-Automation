#!/usr/bin/env python3
"""dynamic_inventory.py — inventário dinâmico do Ansible a partir do Terraform.

Lê `terraform output -json` no diretório de um environment
(`terraform/environments/dev`, por padrão) e monta um inventário no formato
esperado pelo Ansible (script de inventário dinâmico, protocolo `--list` /
`--host`).

STATUS: exemplo/placeholder. Os módulos `terraform/modules/compute` desta
trilha ainda não expõem outputs (outra trilha do projeto está construindo o
Terraform em paralelo — ver PROJECT_LOG.md). Quando os outputs existirem
(algo como `web_instance_ips`, `db_instance_ips`, ou uma lista de objetos
com tags), ajuste `_load_terraform_outputs()` e o mapeamento de grupos
abaixo para os nomes reais.

Uso esperado (uma vez que os outputs existam):

    cd terraform/environments/dev
    terraform output -json > /tmp/tf-outputs.json
    ANSIBLE_TF_OUTPUTS=/tmp/tf-outputs.json \
        ansible-playbook -i ansible/inventory/dynamic_inventory.py ansible/playbooks/site.yml

Ou diretamente como inventory script (chama `terraform output -json` você
mesmo, sem variável de ambiente):

    ansible-inventory -i ansible/inventory/dynamic_inventory.py --list

Este script é POSIX-friendly (roda em Linux/WSL/CI); no Windows nativo,
`ansible-playbook` não funciona de qualquer forma (ver ansible/README.md).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

# Environment do Terraform usado como fonte dos outputs. Pode ser sobrescrito
# com a variável de ambiente TF_ENV_DIR.
DEFAULT_TF_ENV_DIR = (
    Path(__file__).resolve().parents[2] / "terraform" / "environments" / "dev"
)


def _load_terraform_outputs() -> dict:
    """Retorna o JSON de `terraform output -json`, de um arquivo ou ao vivo.

    Ordem de resolução:
    1. `ANSIBLE_TF_OUTPUTS` — caminho para um JSON já exportado (útil em CI
       para não depender de state/credenciais no momento do inventário).
    2. Executa `terraform output -json` no diretório apontado por
       `TF_ENV_DIR` (default: terraform/environments/dev).
    """
    outputs_file = os.environ.get("ANSIBLE_TF_OUTPUTS")
    if outputs_file:
        return json.loads(Path(outputs_file).read_text(encoding="utf-8"))

    tf_env_dir = Path(os.environ.get("TF_ENV_DIR", str(DEFAULT_TF_ENV_DIR)))
    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd=str(tf_env_dir),
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(result.stdout or "{}")
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as exc:
        sys.stderr.write(
            f"[dynamic_inventory] aviso: não foi possível ler outputs do "
            f"Terraform em {tf_env_dir} ({exc}). Retornando inventário vazio.\n"
        )
        return {}


def _build_inventory(tf_outputs: dict) -> dict:
    """Mapeia outputs do Terraform para grupos do Ansible.

    Convenção esperada (ajustar quando o módulo compute definir outputs
    reais): cada output é uma lista de objetos `{name, public_ip|private_ip}`.
      - web_instances -> grupo [linux_web]
      - db_instances  -> grupo [linux_db]
    """
    inventory: dict = {
        "_meta": {"hostvars": {}},
        "linux_web": {"hosts": []},
        "linux_db": {"hosts": []},
        "linux": {"children": ["linux_web", "linux_db"]},
    }

    group_map = {
        "web_instances": "linux_web",
        "db_instances": "linux_db",
    }

    for output_key, group_name in group_map.items():
        instances = tf_outputs.get(output_key, {}).get("value", [])
        for instance in instances:
            host_name = instance.get("name") or instance.get("id")
            host_ip = instance.get("private_ip") or instance.get("public_ip")
            if not host_name or not host_ip:
                continue
            inventory[group_name]["hosts"].append(host_name)
            inventory["_meta"]["hostvars"][host_name] = {
                "ansible_host": host_ip,
                "ansible_user": instance.get("ssh_user", "ec2-user"),
            }

    return inventory


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "--list":
        tf_outputs = _load_terraform_outputs()
        print(json.dumps(_build_inventory(tf_outputs), indent=2))
    elif len(sys.argv) > 2 and sys.argv[1] == "--host":
        # Inventário já retorna hostvars via _meta em --list; --host não
        # precisa devolver nada além de um objeto vazio.
        print(json.dumps({}))
    else:
        sys.stderr.write("Uso: dynamic_inventory.py --list | --host <hostname>\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
