-- Migration: Create Invite with Token RPC
-- Description: RPC que cria convite e retorna o token para o admin copiar/compartilhar
-- Nota: Esta função é para uso no MVP. Em produção, considere enviar o token por email.

-- ============================================================================
-- create_invite_with_token
-- ============================================================================
-- Cria um convite e retorna o token (para copiar e compartilhar)
-- Apenas admins da org podem usar esta função

CREATE OR REPLACE FUNCTION create_invite_with_token(
  p_org_id uuid,
  p_email text,
  p_role_to_grant text,
  p_group_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_invite_id uuid;
  v_token text;
  v_token_hash text;
  v_uid uuid;
  v_is_admin boolean;
  v_is_group_leader boolean;
  v_org_name text;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Validar membership
  IF NOT is_member(p_org_id, v_uid) THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- Validar permissões
  v_is_admin := is_admin_org(p_org_id, v_uid);
  v_is_group_leader := is_group_leader(p_org_id, v_uid);

  IF NOT v_is_admin AND NOT v_is_group_leader THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  -- Se group_leader, validar escopo
  IF v_is_group_leader AND NOT v_is_admin THEN
    IF p_group_id IS NULL THEN
      RAISE EXCEPTION 'invalid_input' USING MESSAGE = 'group_id required for group_leader';
    END IF;

    IF NOT leads_group(p_org_id, v_uid, p_group_id) THEN
      RAISE EXCEPTION 'not_allowed' USING MESSAGE = 'group_leader can only invite to groups they lead';
    END IF;

    -- Group leader não pode conceder admin_org
    IF p_role_to_grant = 'admin_org' THEN
      RAISE EXCEPTION 'not_allowed' USING MESSAGE = 'group_leader cannot grant admin_org';
    END IF;
  END IF;

  -- Validar email
  IF p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    RAISE EXCEPTION 'invalid_input' USING MESSAGE = 'invalid email format';
  END IF;

  -- Validar role
  IF p_role_to_grant NOT IN ('member', 'mentor', 'admin_org', 'group_leader') THEN
    RAISE EXCEPTION 'invalid_input' USING MESSAGE = 'invalid role';
  END IF;

  -- Verificar se já existe convite pendente para este email nesta org
  IF EXISTS (
    SELECT 1 FROM invites 
    WHERE org_id = p_org_id 
    AND email = p_email 
    AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'duplicate_invite' USING MESSAGE = 'Já existe um convite pendente para este email';
  END IF;

  -- Gerar token e hash
  v_token := encode(gen_random_bytes(32), 'hex');
  v_token_hash := encode(digest(v_token, 'sha256'), 'hex');

  -- Buscar nome da org
  SELECT name INTO v_org_name FROM organizations WHERE id = p_org_id;

  -- Criar convite
  INSERT INTO invites (
    org_id,
    email,
    role_to_grant,
    group_id,
    token_hash,
    status,
    expires_at,
    created_by_user_id
  ) VALUES (
    p_org_id,
    p_email,
    p_role_to_grant,
    p_group_id,
    v_token_hash,
    'pending',
    now() + interval '7 days',
    v_uid
  ) RETURNING id INTO v_invite_id;

  -- Registrar auditoria
  INSERT INTO audit_events (
    org_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    p_org_id,
    v_uid,
    'invite_created',
    'invite',
    v_invite_id,
    jsonb_build_object('email', p_email, 'role', p_role_to_grant, 'group_id', p_group_id)
  );

  -- Retornar ID e token
  RETURN jsonb_build_object(
    'invite_id', v_invite_id,
    'token', v_token,
    'email', p_email,
    'role', p_role_to_grant,
    'org_name', v_org_name,
    'expires_at', (now() + interval '7 days')::text
  );
END;
$$;

-- ============================================================================
-- revoke_invite
-- ============================================================================
-- Revoga um convite pendente

CREATE OR REPLACE FUNCTION revoke_invite(p_invite_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_org_id uuid;
  v_is_admin boolean;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Buscar org_id do convite
  SELECT org_id INTO v_org_id FROM invites WHERE id = p_invite_id;
  
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'not_found' USING MESSAGE = 'Invite not found';
  END IF;

  -- Validar permissões (apenas admin pode revogar)
  v_is_admin := is_admin_org(v_org_id, v_uid);
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  -- Revogar convite
  UPDATE invites 
  SET status = 'revoked', updated_at = now()
  WHERE id = p_invite_id AND status = 'pending';

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
    'invite_revoked',
    'invite',
    p_invite_id,
    '{}'::jsonb
  );

  RETURN TRUE;
END;
$$;

-- ============================================================================
-- get_org_invites
-- ============================================================================
-- Lista convites da organização (para admins)

CREATE OR REPLACE FUNCTION get_org_invites(p_org_id uuid)
RETURNS TABLE (
  id uuid,
  email text,
  role_to_grant text,
  status text,
  created_at timestamptz,
  expires_at timestamptz,
  created_by_email text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_is_admin boolean;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Validar permissões
  v_is_admin := is_admin_org(p_org_id, v_uid);
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  RETURN QUERY
  SELECT 
    i.id,
    i.email,
    i.role_to_grant,
    i.status,
    i.created_at,
    i.expires_at,
    u.email as created_by_email
  FROM invites i
  LEFT JOIN auth.users u ON u.id = i.created_by_user_id
  WHERE i.org_id = p_org_id
  ORDER BY i.created_at DESC;
END;
$$;

-- ============================================================================
-- get_org_members
-- ============================================================================
-- Lista membros da organização (para admins)

CREATE OR REPLACE FUNCTION get_org_members(p_org_id uuid)
RETURNS TABLE (
  user_id uuid,
  email text,
  full_name text,
  status text,
  role_admin_org boolean,
  role_group_leader boolean,
  joined_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_is_admin boolean;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Validar permissões (admin pode ver todos, membro comum só vê a si mesmo)
  v_is_admin := is_admin_org(p_org_id, v_uid);
  
  IF NOT is_member(p_org_id, v_uid) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  RETURN QUERY
  SELECT 
    om.user_id,
    u.email,
    u.raw_user_meta_data->>'full_name' as full_name,
    om.status,
    om.role_admin_org,
    om.role_group_leader,
    om.created_at as joined_at
  FROM organization_members om
  JOIN auth.users u ON u.id = om.user_id
  WHERE om.org_id = p_org_id
    AND (v_is_admin OR om.user_id = v_uid) -- Admin vê todos, outros só a si mesmo
  ORDER BY om.created_at DESC;
END;
$$;

