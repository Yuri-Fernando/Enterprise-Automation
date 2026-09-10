# ADR-003 — Escopo do self-healing (remediação automática limitada e auditável)

**Status:** Aceito · **Data:** 2026-08

## Contexto

O `automation/troubleshooting/` detecta e corrige problemas comuns
(serviço parado, disco cheio, config drift). Remediação automática sem
limites é perigosa (loop de correção, mascarar causa-raiz).

## Decisão

Self-healing só para um **catálogo fixo e revisado** de problemas, cada um
com: condição de detecção, ação idempotente, limite de tentativas e
registro obrigatório no banco (`database/`) + evento. Fora do catálogo →
abre incidente, não age. Nenhuma ação destrutiva (terminar instância,
dropar volume) é automática.

## Consequências

- (+) Reduz MTTR nos casos comuns sem esconder incidentes reais.
- (−) Casos novos exigem PR para entrar no catálogo (intencional — cada
  automação de remediação passa por review).
