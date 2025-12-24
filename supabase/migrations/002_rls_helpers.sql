-- Migration: RLS Helper Functions
-- Description: Implementa funções auxiliares para RLS conforme DATA_MODEL.md 3.5

-- ============================================================================
-- 3.5.1 Predicados base
-- ============================================================================

-- is_member: verifica se usuário é membro ativo da organização
CREATE OR REPLACE FUNCTION is_member(p_org_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM organization_members
    WHERE org_id = p_org_id
      AND user_id = p_user_id
      AND status = 'active'
  );
$$;

-- is_admin_org: verifica se usuário é admin da organização
CREATE OR REPLACE FUNCTION is_admin_org(p_org_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM organization_members
    WHERE org_id = p_org_id
      AND user_id = p_user_id
      AND status = 'active'
      AND role_admin_org = true
  );
$$;

-- is_group_leader: verifica se usuário lidera ao menos um grupo da org
CREATE OR REPLACE FUNCTION is_group_leader(p_org_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM group_leaders gl
    JOIN groups g ON g.id = gl.group_id
    WHERE g.org_id = p_org_id
      AND gl.user_id = p_user_id
  );
$$;

-- leads_group: verifica se usuário lidera um grupo específico
CREATE OR REPLACE FUNCTION leads_group(p_org_id uuid, p_user_id uuid, p_group_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM group_leaders gl
    JOIN groups g ON g.id = gl.group_id
    WHERE g.org_id = p_org_id
      AND gl.group_id = p_group_id
      AND gl.user_id = p_user_id
  );
$$;

-- shares_group_with_leader: verifica se mentor e discípulo compartilham grupo liderado pelo líder
CREATE OR REPLACE FUNCTION shares_group_with_leader(
  p_org_id uuid,
  p_leader_user_id uuid,
  p_member_user_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM group_leaders gl
    JOIN group_memberships gm1 ON gm1.group_id = gl.group_id
    JOIN group_memberships gm2 ON gm2.group_id = gl.group_id
    WHERE gl.org_id = p_org_id
      AND gl.user_id = p_leader_user_id
      AND gm1.user_id = p_leader_user_id
      AND gm2.user_id = p_member_user_id
      AND gm1.org_id = p_org_id
      AND gm2.org_id = p_org_id
  );
$$;

-- ============================================================================
-- 3.5.2 Assinatura ativa do discipulador (canonical)
-- ============================================================================

-- has_active_mentor_subscription: verifica se usuário tem assinatura ativa de mentor
CREATE OR REPLACE FUNCTION has_active_mentor_subscription(p_org_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_org_type text;
  v_subscription_active boolean;
  v_license_active boolean;
BEGIN
  -- Obter tipo da organização
  SELECT type INTO v_org_type
  FROM organizations
  WHERE id = p_org_id;

  IF v_org_type IS NULL THEN
    RETURN false;
  END IF;

  -- Org individual: verificar assinatura ativa da org
  IF v_org_type = 'individual' THEN
    SELECT EXISTS (
      SELECT 1
      FROM org_subscriptions
      WHERE org_id = p_org_id
        AND status IN ('active', 'trialing')
        AND (current_period_end IS NULL OR current_period_end >= now())
    ) INTO v_subscription_active;
    
    RETURN v_subscription_active;
  END IF;

  -- Org igreja: verificar assinatura da org E licença alocada ao usuário
  IF v_org_type = 'church' THEN
    -- Verificar assinatura da org
    SELECT EXISTS (
      SELECT 1
      FROM org_subscriptions
      WHERE org_id = p_org_id
        AND status IN ('active', 'trialing')
        AND (current_period_end IS NULL OR current_period_end >= now())
    ) INTO v_subscription_active;

    -- Verificar licença de mentor alocada
    SELECT EXISTS (
      SELECT 1
      FROM org_license_allocations
      WHERE org_id = p_org_id
        AND user_id = p_user_id
        AND license_type = 'mentor'
        AND status = 'active'
    ) INTO v_license_active;

    RETURN v_subscription_active AND v_license_active;
  END IF;

  RETURN false;
END;
$$;

-- ============================================================================
-- Funções auxiliares para RLS policies (usando auth.uid())
-- ============================================================================

-- Wrapper para is_member usando auth.uid()
CREATE OR REPLACE FUNCTION is_member(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT is_member(p_org_id, auth.uid());
$$;

-- Wrapper para is_admin_org usando auth.uid()
CREATE OR REPLACE FUNCTION is_admin_org(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT is_admin_org(p_org_id, auth.uid());
$$;

-- Wrapper para is_group_leader usando auth.uid()
CREATE OR REPLACE FUNCTION is_group_leader(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT is_group_leader(p_org_id, auth.uid());
$$;

-- Wrapper para leads_group usando auth.uid()
CREATE OR REPLACE FUNCTION leads_group(p_org_id uuid, p_group_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT leads_group(p_org_id, auth.uid(), p_group_id);
$$;

-- Wrapper para shares_group_with_leader usando auth.uid() como leader
CREATE OR REPLACE FUNCTION shares_group_with_leader(p_org_id uuid, p_member_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT shares_group_with_leader(p_org_id, auth.uid(), p_member_user_id);
$$;

-- Wrapper para has_active_mentor_subscription usando auth.uid()
CREATE OR REPLACE FUNCTION has_active_mentor_subscription(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT has_active_mentor_subscription(p_org_id, auth.uid());
$$;

-- ============================================================================
-- Funções auxiliares para discipulados
-- ============================================================================

-- is_disciple_in_discipleship: verifica se usuário é discípulo do discipulado
CREATE OR REPLACE FUNCTION is_disciple_in_discipleship(p_discipleship_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM discipleships
    WHERE id = p_discipleship_id
      AND disciple_user_id = auth.uid()
  );
$$;

-- is_mentor_in_discipleship: verifica se usuário é mentor do discipulado
CREATE OR REPLACE FUNCTION is_mentor_in_discipleship(p_discipleship_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM discipleships
    WHERE id = p_discipleship_id
      AND mentor_user_id = auth.uid()
  );
$$;

-- ============================================================================
-- Função para admin_platform (futuro - pode usar claims do auth)
-- ============================================================================

-- is_admin_platform: verifica se usuário é admin da plataforma
-- Por enquanto, retorna false. Pode ser implementado via claims do auth ou tabela separada
CREATE OR REPLACE FUNCTION is_admin_platform()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  -- TODO: Implementar verificação de admin_platform
  -- Pode ser via auth.jwt()->>'role' = 'admin_platform'
  -- ou tabela platform_admins
  SELECT false;
$$;

