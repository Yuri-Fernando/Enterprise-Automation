package terraform.tags

# Falha se algum recurso taggeável não tiver as tags obrigatórias.
required := {"project", "environment", "managed_by"}

deny[msg] {
  resource := input.resource_changes[_]
  tags := object.get(resource.change.after, "tags", {})
  missing := required - {k | tags[k]}
  count(missing) > 0
  msg := sprintf("%s (%s): tags obrigatórias ausentes: %v", [resource.address, resource.type, missing])
}
