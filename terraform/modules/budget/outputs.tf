output "budget_id" {
  description = "ID of the created budget."
  value       = aws_budgets_budget.monthly_cost.id
}

output "budget_name" {
  description = "Name of the created budget."
  value       = aws_budgets_budget.monthly_cost.name
}
