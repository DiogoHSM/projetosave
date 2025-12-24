-- Migration: Create Church Organization RPC
-- Description: RPC para criar organização do tipo igreja (para MVP/teste)

CREATE OR REPLACE FUNCTION create_church_org(
  p_org_name text,
  p_contact_email text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_org_id uuid;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Validar nome
  IF p_org_name IS NULL OR length(trim(p_org_name)) < 3 THEN
    RAISE EXCEPTION 'invalid_input' USING MESSAGE = 'Nome da organização deve ter pelo menos 3 caracteres';
  END IF;

  -- Criar organização
  INSERT INTO organizations (
    name,
    type,
    contact_email
  ) VALUES (
    trim(p_org_name),
    'church',
    p_contact_email
  ) RETURNING id INTO v_org_id;

  -- Criar membership (usuário como admin da nova org)
  INSERT INTO organization_members (
    org_id,
    user_id,
    status,
    role_admin_org,
    role_group_leader
  ) VALUES (
    v_org_id,
    v_uid,
    'active',
    true,  -- Criador é admin
    false
  );

  -- Criar license pool vazio
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
    v_uid,
    'organization_created',
    'organization',
    v_org_id,
    jsonb_build_object('name', p_org_name, 'type', 'church')
  );

  RETURN jsonb_build_object(
    'org_id', v_org_id,
    'name', trim(p_org_name),
    'type', 'church'
  );
END;
$$;

