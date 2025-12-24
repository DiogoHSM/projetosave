-- Migration: Create Individual Organization RPC
-- Description: RPC para criar organização individual automaticamente após registro

-- ============================================================================
-- create_individual_org
-- ============================================================================

CREATE OR REPLACE FUNCTION create_individual_org(p_user_id uuid, p_org_name text DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_org_id uuid;
  v_user_email text;
  v_org_name text;
BEGIN
  -- Validar autenticação
  IF p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'not_allowed' USING MESSAGE = 'can only create org for current user';
  END IF;

  -- Buscar email do usuário
  SELECT email INTO v_user_email
  FROM auth.users
  WHERE id = p_user_id;

  IF v_user_email IS NULL THEN
    RAISE EXCEPTION 'not_found' USING MESSAGE = 'user not found';
  END IF;

  -- Definir nome da organização
  IF p_org_name IS NULL OR p_org_name = '' THEN
    v_org_name := 'Minha Organização';
  ELSE
    v_org_name := p_org_name;
  END IF;

  -- Verificar se usuário já tem organização individual
  IF EXISTS (
    SELECT 1
    FROM organizations o
    JOIN organization_members om ON om.org_id = o.id
    WHERE o.type = 'individual'
      AND om.user_id = p_user_id
      AND om.status = 'active'
  ) THEN
    -- Retornar org existente
    SELECT o.id INTO v_org_id
    FROM organizations o
    JOIN organization_members om ON om.org_id = o.id
    WHERE o.type = 'individual'
      AND om.user_id = p_user_id
      AND om.status = 'active'
    LIMIT 1;
    
    RETURN v_org_id;
  END IF;

  -- Criar organização individual
  INSERT INTO organizations (
    type,
    name,
    contact_email
  ) VALUES (
    'individual',
    v_org_name,
    v_user_email
  ) RETURNING id INTO v_org_id;

  -- Criar membership (usuário como membro ativo e admin da própria org individual)
  INSERT INTO organization_members (
    org_id,
    user_id,
    status,
    role_admin_org,
    role_group_leader
  ) VALUES (
    v_org_id,
    p_user_id,
    'active',
    true,  -- É admin da própria organização individual
    false
  );

  -- Criar license pool vazio (sem seats inicialmente)
  INSERT INTO org_license_pool (
    org_id,
    disciple_seats_total,
    mentor_seats_total
  ) VALUES (
    v_org_id,
    0,
    0
  );

  -- Registrar auditoria
  INSERT INTO audit_events (
    org_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    v_org_id,
    p_user_id,
    'individual_org_created',
    'organization',
    v_org_id,
    jsonb_build_object('type', 'individual')
  );

  RETURN v_org_id;
END;
$$;

