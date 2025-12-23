# CHECKLISTS.md

## Objetivo
Checklists rápidos para validar entregas e reduzir bugs/brechas.

## Checklist de segurança
- [ ] RLS em todas as tabelas
- [ ] Policies mínimas e específicas
- [ ] Teacher content sem SELECT direto
- [ ] RPCs com checagens explícitas
- [ ] Sem service_role no client
- [ ] Webhooks idempotentes e logados

## Checklist de convites
- [ ] Token hash armazenado
- [ ] Expiração
- [ ] Revogação e reenvio
- [ ] Aceite cria membership corretamente
- [ ] Aceite não permite replay

## Checklist de licenças
- [ ] Pool atualizado no webhook
- [ ] Alocação por usuário respeitada
- [ ] Quota do líder de grupo aplicada
- [ ] Auditoria em todas as concessões

## Checklist de fluxo do discipulado
- [ ] Liberação manual funciona
- [ ] Questões só aparecem se liberadas
- [ ] Rascunho e envio funcionam
- [ ] Revisão e histórico funcionam
- [ ] Encerramento bloqueia interação e mantém leitura

## Checklist de admin de conteúdo
- [ ] Editor de lição com blocos
- [ ] Upload/seleção de imagens
- [ ] Vídeo como bloco
- [ ] Editor de questões por tipo
- [ ] Publicação e versionamento básico

