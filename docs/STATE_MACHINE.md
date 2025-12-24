# STATE_MACHINE.md – Projeto SAVE

## 1. Objetivo
Definir as máquinas de estado oficiais do Projeto SAVE.

Este documento é a fonte de verdade para:
- transições válidas de estado
- quem pode executar cada transição
- efeitos colaterais (auditoria, desbloqueios, métricas)

Se uma transição não estiver descrita aqui, ela é inválida.

---

## 2. Princípios gerais

1. Estados são explícitos e finitos.
2. Toda transição deve:
   - ter um ator autorizado
   - gerar evento de auditoria
3. Estados finais são somente leitura.
4. Não há “atalhos” de estado.
5. Estados refletem o **fluxo pedagógico**, não apenas técnico.

---

## 3. Máquina de estado — Discipulado (`discipleships.status`)

### Estados possíveis
- `active`
- `completed`
- `cancelled`

### Estado inicial
- `active`

### Transições

| De        | Para        | Quem pode | Observações |
|----------|-------------|-----------|-------------|
| active   | completed   | mentor, admin_org | Encerramento normal |
| active   | cancelled   | admin_org | Excepcional |

### Regras
- Após `completed` ou `cancelled`, o discipulado:
  - torna-se somente leitura
  - não aceita novas liberações nem respostas
- Ao completar:
  - registrar `completed_at`
  - liberar nova licença de disciple para o mentor (quando aplicável)

---

## 4. Máquina de estado — Liberação de lições

### Entidades
- `lesson_releases`
- `question_releases`

### Estados implícitos
- `not_released`
- `released`

### Regras
- Apenas mentor pode liberar
- Liberação é:
  - idempotente
  - irreversível
- Perguntas só podem ser liberadas após a lição correspondente

---

## 5. Máquina de estado — Respostas (`answers.status`)

### Estados possíveis
- `draft`
- `submitted`
- `in_review`
- `needs_changes`
- `approved`

### Estado inicial
- `draft`

### Transições

| De            | Para           | Quem pode |
|---------------|----------------|-----------|
| draft         | submitted      | disciple  |
| submitted     | in_review      | mentor    |
| in_review     | approved       | mentor    |
| in_review     | needs_changes  | mentor    |
| needs_changes | draft          | disciple  |

### Regras
- O disciple pode editar respostas apenas em:
  - `draft`
  - `needs_changes`
- `approved` é estado final e somente leitura
- Toda mudança gera auditoria

---

## 6. Máquina de estado — Revisões (`reviews.decision`)

### Decisões possíveis
- `approved`
- `needs_changes`
- `comment_only`

### Estado inicial
- não aplicável (cada review é um evento)

### Significado das decisões

#### `approved`
- Resposta aceita
- Pode gerar:
  - avanço no discipulado
  - contagem para métricas/conquistas

#### `needs_changes`
- Resposta devolvida ao disciple
- Força transição da resposta para `needs_changes`

#### `comment_only`
- Comentário pedagógico
- **Não altera o estado da resposta**
- Usado quando:
  - mentor quer orientar
  - elogiar
  - sugerir reflexão adicional
- Não bloqueia progresso

### Regras
- Apenas mentor do discipulado pode criar reviews
- Cada review:
  - está ligada a uma resposta
  - gera `audit_event`
- Múltiplos `comment_only` podem existir para a mesma resposta

---

## 7. Máquina de estado — Convites (`invites.status`)

### Estados possíveis
- `pending`
- `accepted`
- `expired`
- `revoked`

### Estado inicial
- `pending`

### Transições

| De       | Para      | Quem pode |
|----------|-----------|-----------|
| pending  | accepted  | usuário convidado |
| pending  | revoked   | criador, admin_org |
| pending  | expired   | sistema (tempo) |

### Regras
- Convites são:
  - uso único
  - imutáveis após aceitos
- Token não pode ser reutilizado

---

## 8. Máquina de estado — Licenças (`org_license_allocations.status`)

### Estados possíveis
- `active`
- `revoked`

### Estado inicial
- `active`

### Transições

| De      | Para     | Quem pode |
|--------|----------|-----------|
| active | revoked  | admin_org, group_leader (escopo) |

### Regras
- Licenças revogadas:
  - não são reutilizadas
  - não são deletadas
- Não é permitido revogar licença:
  - em uso por discipulado ativo (mentor)

---

## 9. Auditoria obrigatória

Toda transição deve gerar evento em `audit_events`, incluindo:
- actor_user_id
- org_id
- entity_type
- entity_id
- from_state (quando aplicável)
- to_state (quando aplicável)

---

## 10. Regras finais

- Se um estado não estiver aqui, ele não existe.
- Se uma transição não estiver aqui, ela é inválida.
- Backend valida estados **antes** de executar qualquer ação.
- Frontend nunca força mudança de estado.