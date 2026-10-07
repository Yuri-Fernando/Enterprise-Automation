package terraform.tags

import rego.v1

# Falha se algum recurso taggeável do plano não tiver as tags obrigatórias.
#
# Tags exigidas aqui = o subconjunto de terraform/providers.tf's
# `default_tags` (Environment, Project, ManagedBy — Owner/CostCenter também
# são propagadas mas não bloqueiam o gate) que todo módulo deste repositório
# recebe automaticamente via provider default_tags.
#
# BUG CORRIGIDO (ver PROJECT_LOG.md / CHANGELOG.md): a versão anterior desta
# policy exigia chaves minúsculas ("project", "environment", "managed_by"),
# que nunca correspondem às tags reais geradas por este provider
# (capitalizadas: "Environment", "Project", "ManagedBy") — toda avaliação
# contra um plano real falhava, mesmo com tagging 100% correto. Confirmado
# rodando `terraform plan` de verdade (via LocalStack, sem custo AWS) contra
# terraform/environments/dev e testando esta policy com `conftest` contra o
# plan.json resultante.
required_tags := {"Environment", "Project", "ManagedBy"}

# Usa `tags_all` (não `tags`): é o atributo que o provider AWS expõe com o
# conjunto de tags *efetivamente aplicado* (tags do recurso + default_tags
# do provider combinados) em todo recurso que suporta tagging — um recurso
# pode não declarar `tags` localmente e ainda estar corretamente tagueado
# via default_tags só. Resources sem suporte a tagging (ex.: aws_lb_listener)
# não têm a chave `tags_all` em `change.after` e são ignorados (não é
# "tags ausentes", é "tagging não se aplica a este tipo de recurso").
deny contains msg if {
	resource := input.resource_changes[_]
	resource.mode == "managed"
	after := resource.change.after
	after != null
	tags := object.get(after, "tags_all", null)
	tags != null
	missing := required_tags - {k | some k, _ in tags}
	count(missing) > 0
	msg := sprintf("%s (%s): tags obrigatórias ausentes: %v", [resource.address, resource.type, missing])
}
