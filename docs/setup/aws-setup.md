# Setup AWS (sua parte)

Este projeto **não roda `terraform apply` sozinho**. Tudo é construído e
validado (`fmt`, `validate`, `plan`, `checkov`) sem tocar na sua conta AWS.
Quando você decidir aplicar de verdade, siga este checklist.

## 1. Pré-requisitos

- [x] AWS CLI instalado e configurado (`aws configure list`) — já detectado
      localmente, região `sa-east-1`.
- [x] Terraform instalado (`terraform -version`) — instalado nesta sessão
      (v1.15.8, via winget).
- [ ] Confirmar que o usuário/role usado tem apenas as permissões
      necessárias (não `AdministratorAccess` em produção real — para o
      ambiente `dev` de laboratório é aceitável, mas documente a decisão).

## 2. Backend remoto do Terraform (state)

Antes do primeiro `apply`, crie manualmente (ou via um `bootstrap/`
separado, fora do state principal) um bucket S3 + tabela DynamoDB para state
locking:

```bash
aws s3api create-bucket --bucket <seu-bucket-tfstate> --region sa-east-1 \
  --create-bucket-configuration LocationConstraint=sa-east-1
aws dynamodb create-table --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region sa-east-1
```

Depois preencha `terraform/backend.tf` com esses valores (não commitar
nomes sensíveis se preferir — pode usar `-backend-config` na hora do init).

## 3. Validar sem custo (o que já está pronto)

```bash
cd terraform/environments/dev
terraform init -backend=false
terraform validate
terraform fmt -check -recursive
```

## 4. Plan (ainda sem custo)

```bash
terraform init   # agora com backend real, se já criado
terraform plan -out=tfplan
```

Revise o plano com atenção — confira contagem de recursos e custo estimado
(ex.: via `infracost`, opcional).

## 5. Apply (gera custo real — decisão sua)

```bash
terraform apply tfplan
```

Recomendação: aplique primeiro só o módulo `networking` + `iam` (custo
~zero), depois avalie se quer subir `compute`/`database` (EC2/RDS já geram
custo por hora).

## 6. Destruir ao terminar de demonstrar

```bash
terraform destroy
```

Não esqueça — EC2/RDS/NAT Gateway cobram por hora mesmo parados/ociosos
(NAT Gateway principalmente).

## 7. GitHub Actions usando sua conta AWS

Para o CI rodar `terraform plan` de verdade nos PRs, cadastre credenciais
como GitHub Secrets — ver [`github-setup.md`](github-setup.md). Prefira
OIDC (`aws-actions/configure-aws-credentials` com `role-to-assume`) a
Access Keys de longa duração.
