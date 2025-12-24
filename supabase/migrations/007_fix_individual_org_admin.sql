-- Migration: Fix Individual Org Admin
-- Description: Corrige memberships de organizações individuais para serem admin
-- Problema: A migration anterior criava usuários de orgs individuais sem role_admin_org

-- Atualizar todos os membros de organizações individuais para serem admins
UPDATE organization_members om
SET role_admin_org = true
FROM organizations o
WHERE om.org_id = o.id
  AND o.type = 'individual'
  AND om.role_admin_org = false;

-- Comentário: Em orgs individuais, o dono é sempre admin

