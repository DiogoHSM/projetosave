# API_CONTRACTS.md

## Objetivo
Contratos das operações sensíveis. Define RPCs e Edge Functions permitidas e suas validações.

## Convenções
- Todas as funções devem falhar fechado.
- Toda função crítica gera audit_event.
- Entrada e saída bem definidas.
- Não vazar dados de outras orgs.

## RPCs (Postgres Functions)
### get_teacher_lesson(org_id, lesson_id)
- Quem chama:
- Validações:
- Retorno:
- Auditoria:

### get_answer_key(org_id, question_id)
- Quem chama:
- Validações:
- Retorno:
- Auditoria:

### create_invite(org_id, email, role, groups, grant_licenses?)
- Quem chama:
- Validações:
- Retorno:
- Auditoria:

### accept_invite(token)
- Quem chama:
- Validações:
- Retorno:
- Auditoria:

### allocate_license(org_id, target_user_id, license_type, qty, scope?)
- Quem chama:
- Validações:
- Retorno:
- Auditoria:

## Edge Functions
### payments_webhook()
- Provedor:
- Idempotência:
- Validações:
- Efeitos:
- Auditoria:

### admin_ops()
- Escopo:
- Operações permitidas:
- Validações:
- Auditoria:

## Erros padrão (a preencher)
- not_authenticated
- not_allowed
- subscription_inactive
- quota_exceeded
- not_found
- invalid_token

