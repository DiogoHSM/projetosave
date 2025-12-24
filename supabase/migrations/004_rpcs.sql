-- Migration: Essential RPCs
-- Description: Implementa RPCs essenciais conforme API_CONTRACTS.md

-- ============================================================================
-- 3. Convites e onboarding
-- ============================================================================

-- 3.1 create_invite
CREATE OR REPLACE FUNCTION create_invite(
  p_org_id uuid,
  p_email text,
  p_role_to_grant text,
  p_group_id uuid DEFAULT NULL,
  p_license_grants_json jsonb DEFAULT NULL
)
RETURNS uuid
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

  -- Gerar token e hash
  v_token := encode(gen_random_bytes(32), 'hex');
  v_token_hash := encode(digest(v_token, 'sha256'), 'hex');

  -- Criar convite
  INSERT INTO invites (
    org_id,
    email,
    role_to_grant,
    group_id,
    license_grants_json,
    token_hash,
    status,
    expires_at,
    created_by_user_id
  ) VALUES (
    p_org_id,
    p_email,
    p_role_to_grant,
    p_group_id,
    p_license_grants_json,
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

  -- Retornar ID (token será enviado por email/outro canal, não retornado aqui)
  RETURN v_invite_id;
END;
$$;

-- 3.2 accept_invite
CREATE OR REPLACE FUNCTION accept_invite(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_token_hash text;
  v_invite invites%ROWTYPE;
  v_uid uuid;
  v_membership_id uuid;
  v_org_id uuid;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Hash do token recebido
  v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

  -- Buscar convite
  SELECT * INTO v_invite
  FROM invites
  WHERE token_hash = v_token_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_token';
  END IF;

  -- Validar status
  IF v_invite.status != 'pending' THEN
    IF v_invite.status = 'accepted' THEN
      RAISE EXCEPTION 'conflict' USING MESSAGE = 'invite already accepted';
    ELSIF v_invite.status = 'revoked' THEN
      RAISE EXCEPTION 'invalid_token' USING MESSAGE = 'invite revoked';
    ELSIF v_invite.status = 'expired' THEN
      RAISE EXCEPTION 'expired_token';
    ELSE
      RAISE EXCEPTION 'invalid_token';
    END IF;
  END IF;

  -- Validar expiração
  IF v_invite.expires_at IS NOT NULL AND v_invite.expires_at < now() THEN
    UPDATE invites SET status = 'expired' WHERE id = v_invite.id;
    RAISE EXCEPTION 'expired_token';
  END IF;

  -- Validar que usuário não já é membro
  IF EXISTS (
    SELECT 1
    FROM organization_members
    WHERE org_id = v_invite.org_id
      AND user_id = v_uid
      AND status = 'active'
  ) THEN
    -- Já é membro, apenas atualizar convite como aceito
    UPDATE invites
    SET status = 'accepted', updated_at = now()
    WHERE id = v_invite.id;
    
    RETURN jsonb_build_object(
      'org_id', v_invite.org_id,
      'status', 'already_member'
    );
  END IF;

  -- Criar membership
  INSERT INTO organization_members (
    org_id,
    user_id,
    status,
    role_admin_org,
    role_group_leader
  ) VALUES (
    v_invite.org_id,
    v_uid,
    'active',
    CASE WHEN v_invite.role_to_grant = 'admin_org' THEN true ELSE false END,
    CASE WHEN v_invite.role_to_grant = 'group_leader' THEN true ELSE false END
  ) RETURNING id INTO v_membership_id;

  -- Adicionar a grupo se especificado
  IF v_invite.group_id IS NOT NULL THEN
    INSERT INTO group_memberships (org_id, group_id, user_id)
    VALUES (v_invite.org_id, v_invite.group_id, v_uid)
    ON CONFLICT (group_id, user_id) DO NOTHING;
  END IF;

  -- Conceder licenças se especificado
  IF v_invite.license_grants_json IS NOT NULL THEN
    -- TODO: Implementar lógica de concessão de licenças
    -- Por enquanto, apenas registrar
  END IF;

  -- Marcar convite como aceito
  UPDATE invites
  SET status = 'accepted', updated_at = now()
  WHERE id = v_invite.id;

  -- Registrar auditoria
  INSERT INTO audit_events (
    org_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    v_invite.org_id,
    v_uid,
    'invite_accepted',
    'invite',
    v_invite.id,
    jsonb_build_object('email', v_invite.email)
  );

  RETURN jsonb_build_object(
    'org_id', v_invite.org_id,
    'membership_id', v_membership_id,
    'group_id', v_invite.group_id
  );
END;
$$;

-- ============================================================================
-- 4. Licenças e assinaturas
-- ============================================================================

-- 4.1 allocate_license
CREATE OR REPLACE FUNCTION allocate_license(
  p_org_id uuid,
  p_user_id uuid,
  p_license_type text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_is_admin boolean;
  v_is_group_leader boolean;
  v_allocation_id uuid;
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

  -- Validar tipo de licença
  IF p_license_type NOT IN ('disciple', 'mentor') THEN
    RAISE EXCEPTION 'invalid_input' USING MESSAGE = 'license_type must be disciple or mentor';
  END IF;

  -- Validar permissões
  v_is_admin := is_admin_org(p_org_id, v_uid);
  v_is_group_leader := is_group_leader(p_org_id, v_uid);

  IF NOT v_is_admin AND NOT v_is_group_leader THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  -- Se group_leader, validar escopo (usuário deve estar em grupo que ele lidera)
  IF v_is_group_leader AND NOT v_is_admin THEN
    IF NOT EXISTS (
      SELECT 1
      FROM group_leaders gl
      JOIN group_memberships gm ON gm.group_id = gl.group_id
      WHERE gl.org_id = p_org_id
        AND gl.user_id = v_uid
        AND gm.user_id = p_user_id
    ) THEN
      RAISE EXCEPTION 'not_allowed' USING MESSAGE = 'group_leader can only allocate to members of their groups';
    END IF;
  END IF;

  -- Verificar pool disponível (simplificado - verificar se há seats totais)
  -- TODO: Implementar verificação completa de pool vs allocations

  -- Criar ou atualizar allocation
  INSERT INTO org_license_allocations (
    org_id,
    user_id,
    license_type,
    quantity,
    status,
    granted_by_user_id
  ) VALUES (
    p_org_id,
    p_user_id,
    p_license_type,
    1,
    'active',
    v_uid
  )
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_allocation_id;

  -- Se não inseriu (já existe), atualizar
  IF v_allocation_id IS NULL THEN
    UPDATE org_license_allocations
    SET status = 'active',
        quantity = quantity + 1,
        updated_at = now()
    WHERE org_id = p_org_id
      AND user_id = p_user_id
      AND license_type = p_license_type
    RETURNING id INTO v_allocation_id;
  END IF;

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
    'license_allocated',
    'license_allocation',
    v_allocation_id,
    jsonb_build_object('target_user_id', p_user_id, 'license_type', p_license_type)
  );
END;
$$;

-- 4.2 revoke_license
CREATE OR REPLACE FUNCTION revoke_license(
  p_org_id uuid,
  p_user_id uuid,
  p_license_type text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_is_admin boolean;
  v_allocation_id uuid;
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

  -- Validar permissões (apenas admin por enquanto)
  v_is_admin := is_admin_org(p_org_id, v_uid);
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  -- Buscar allocation
  SELECT id INTO v_allocation_id
  FROM org_license_allocations
  WHERE org_id = p_org_id
    AND user_id = p_user_id
    AND license_type = p_license_type
    AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found';
  END IF;

  -- TODO: Validar se licença está em uso (discipulado ativo)

  -- Revogar
  UPDATE org_license_allocations
  SET status = 'revoked',
      updated_at = now()
  WHERE id = v_allocation_id;

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
    'license_revoked',
    'license_allocation',
    v_allocation_id,
    jsonb_build_object('target_user_id', p_user_id, 'license_type', p_license_type)
  );
END;
$$;

-- ============================================================================
-- 5. Discipulados
-- ============================================================================

-- 5.1 create_discipleship
CREATE OR REPLACE FUNCTION create_discipleship(
  p_org_id uuid,
  p_disciple_user_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_discipleship_id uuid;
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

  -- Validar assinatura ativa
  IF NOT has_active_mentor_subscription(p_org_id, v_uid) THEN
    RAISE EXCEPTION 'subscription_inactive';
  END IF;

  -- Validar que discípulo é membro da org
  IF NOT is_member(p_org_id, p_disciple_user_id) THEN
    RAISE EXCEPTION 'not_found' USING MESSAGE = 'disciple is not a member of the organization';
  END IF;

  -- Validar que não existe discipulado ativo duplicado
  IF EXISTS (
    SELECT 1
    FROM discipleships
    WHERE org_id = p_org_id
      AND mentor_user_id = v_uid
      AND disciple_user_id = p_disciple_user_id
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'conflict' USING MESSAGE = 'active discipleship already exists';
  END IF;

  -- Criar discipulado
  INSERT INTO discipleships (
    org_id,
    mentor_user_id,
    disciple_user_id,
    status
  ) VALUES (
    p_org_id,
    v_uid,
    p_disciple_user_id,
    'active'
  ) RETURNING id INTO v_discipleship_id;

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
    'discipleship_created',
    'discipleship',
    v_discipleship_id,
    jsonb_build_object('disciple_user_id', p_disciple_user_id)
  );

  RETURN v_discipleship_id;
END;
$$;

-- 5.2 complete_discipleship
CREATE OR REPLACE FUNCTION complete_discipleship(
  p_discipleship_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_discipleship discipleships%ROWTYPE;
  v_is_admin boolean;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Buscar discipulado
  SELECT * INTO v_discipleship
  FROM discipleships
  WHERE id = p_discipleship_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found';
  END IF;

  -- Validar membership
  IF NOT is_member(v_discipleship.org_id, v_uid) THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- Validar permissões
  v_is_admin := is_admin_org(v_discipleship.org_id, v_uid);
  IF v_discipleship.mentor_user_id != v_uid AND NOT v_is_admin THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  -- Validar status
  IF v_discipleship.status != 'active' THEN
    RAISE EXCEPTION 'conflict' USING MESSAGE = 'discipleship is not active';
  END IF;

  -- Encerrar discipulado
  UPDATE discipleships
  SET status = 'completed',
      completed_at = now(),
      updated_at = now()
  WHERE id = p_discipleship_id;

  -- TODO: Reemitir seat de disciple para o mentor
  -- TODO: Criar desconto para o discípulo

  -- Registrar auditoria
  INSERT INTO audit_events (
    org_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    v_discipleship.org_id,
    v_uid,
    'discipleship_completed',
    'discipleship',
    p_discipleship_id,
    jsonb_build_object()
  );
END;
$$;

-- ============================================================================
-- 6. Liberação de conteúdo
-- ============================================================================

-- 6.1 release_lesson
CREATE OR REPLACE FUNCTION release_lesson(
  p_discipleship_id uuid,
  p_lesson_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_discipleship discipleships%ROWTYPE;
  v_release_id uuid;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Buscar discipulado
  SELECT * INTO v_discipleship
  FROM discipleships
  WHERE id = p_discipleship_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found';
  END IF;

  -- Validar que é mentor
  IF v_discipleship.mentor_user_id != v_uid THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  -- Validar status
  IF v_discipleship.status != 'active' THEN
    RAISE EXCEPTION 'conflict' USING MESSAGE = 'discipleship is not active';
  END IF;

  -- Validar que lição está publicada
  IF NOT EXISTS (
    SELECT 1
    FROM lessons
    WHERE id = p_lesson_id
      AND status = 'published'
  ) THEN
    RAISE EXCEPTION 'not_found' USING MESSAGE = 'lesson not found or not published';
  END IF;

  -- Criar release (idempotente via unique constraint)
  INSERT INTO lesson_releases (
    org_id,
    discipleship_id,
    lesson_id,
    released_by_user_id
  ) VALUES (
    v_discipleship.org_id,
    p_discipleship_id,
    p_lesson_id,
    v_uid
  )
  ON CONFLICT (discipleship_id, lesson_id) DO NOTHING
  RETURNING id INTO v_release_id;

  -- Se já existe, buscar ID
  IF v_release_id IS NULL THEN
    SELECT id INTO v_release_id
    FROM lesson_releases
    WHERE discipleship_id = p_discipleship_id
      AND lesson_id = p_lesson_id;
  END IF;

  -- Registrar auditoria
  INSERT INTO audit_events (
    org_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    v_discipleship.org_id,
    v_uid,
    'lesson_released',
    'lesson_release',
    v_release_id,
    jsonb_build_object('lesson_id', p_lesson_id)
  );

  RETURN v_release_id;
END;
$$;

-- 6.2 release_questions
CREATE OR REPLACE FUNCTION release_questions(
  p_discipleship_id uuid,
  p_lesson_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_discipleship discipleships%ROWTYPE;
  v_release_id uuid;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Buscar discipulado
  SELECT * INTO v_discipleship
  FROM discipleships
  WHERE id = p_discipleship_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found';
  END IF;

  -- Validar que é mentor
  IF v_discipleship.mentor_user_id != v_uid THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  -- Validar status
  IF v_discipleship.status != 'active' THEN
    RAISE EXCEPTION 'conflict' USING MESSAGE = 'discipleship is not active';
  END IF;

  -- Validar que lição já foi liberada
  IF NOT EXISTS (
    SELECT 1
    FROM lesson_releases
    WHERE discipleship_id = p_discipleship_id
      AND lesson_id = p_lesson_id
  ) THEN
    RAISE EXCEPTION 'conflict' USING MESSAGE = 'lesson must be released first';
  END IF;

  -- Criar release (idempotente)
  INSERT INTO question_releases (
    org_id,
    discipleship_id,
    lesson_id,
    released_by_user_id
  ) VALUES (
    v_discipleship.org_id,
    p_discipleship_id,
    p_lesson_id,
    v_uid
  )
  ON CONFLICT (discipleship_id, lesson_id) DO NOTHING
  RETURNING id INTO v_release_id;

  -- Se já existe, buscar ID
  IF v_release_id IS NULL THEN
    SELECT id INTO v_release_id
    FROM question_releases
    WHERE discipleship_id = p_discipleship_id
      AND lesson_id = p_lesson_id;
  END IF;

  -- Registrar auditoria
  INSERT INTO audit_events (
    org_id,
    actor_user_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    v_discipleship.org_id,
    v_uid,
    'questions_released',
    'question_release',
    v_release_id,
    jsonb_build_object('lesson_id', p_lesson_id)
  );

  RETURN v_release_id;
END;
$$;

-- ============================================================================
-- 7. Conteúdo do professor (sensível)
-- ============================================================================

-- 7.1 get_teacher_lesson
CREATE OR REPLACE FUNCTION get_teacher_lesson(p_lesson_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_lesson lessons%ROWTYPE;
  v_notes teacher_notes%ROWTYPE;
  v_org_id uuid;
  v_is_admin boolean;
  v_is_group_leader boolean;
  v_has_subscription boolean;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Buscar lição
  SELECT * INTO v_lesson
  FROM lessons
  WHERE id = p_lesson_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found';
  END IF;

  -- Buscar org_id da lição
  SELECT s.org_id INTO v_org_id
  FROM lessons l
  JOIN modules m ON m.id = l.module_id
  JOIN studies s ON s.id = m.study_id
  WHERE l.id = p_lesson_id;

  -- Se org_id não é NULL, validar membership
  IF v_org_id IS NOT NULL THEN
    IF NOT is_member(v_org_id, v_uid) THEN
      RAISE EXCEPTION 'not_member';
    END IF;

    -- Validar permissões
    v_is_admin := is_admin_org(v_org_id, v_uid);
    v_is_group_leader := is_group_leader(v_org_id, v_uid);
    v_has_subscription := has_active_mentor_subscription(v_org_id, v_uid);

    IF NOT v_is_admin AND NOT v_is_group_leader AND NOT v_has_subscription THEN
      RAISE EXCEPTION 'not_allowed';
    END IF;
  END IF;

  -- Buscar notas do professor
  SELECT * INTO v_notes
  FROM teacher_notes
  WHERE lesson_id = p_lesson_id;

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
    'teacher_lesson_viewed',
    'lesson',
    p_lesson_id,
    jsonb_build_object()
  );

  -- Retornar dados
  RETURN jsonb_build_object(
    'lesson_id', p_lesson_id,
    'notes_text', COALESCE(v_notes.notes_text, '')
  );
END;
$$;

-- 7.2 get_answer_key
CREATE OR REPLACE FUNCTION get_answer_key(p_question_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid;
  v_question questions%ROWTYPE;
  v_answer_key answer_keys%ROWTYPE;
  v_org_id uuid;
  v_is_admin boolean;
  v_is_group_leader boolean;
  v_has_subscription boolean;
BEGIN
  -- Validar autenticação
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Buscar questão
  SELECT * INTO v_question
  FROM questions
  WHERE id = p_question_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found';
  END IF;

  -- Buscar org_id da questão
  SELECT s.org_id INTO v_org_id
  FROM questions q
  JOIN lessons l ON l.id = q.lesson_id
  JOIN modules m ON m.id = l.module_id
  JOIN studies s ON s.id = m.study_id
  WHERE q.id = p_question_id;

  -- Se org_id não é NULL, validar membership
  IF v_org_id IS NOT NULL THEN
    IF NOT is_member(v_org_id, v_uid) THEN
      RAISE EXCEPTION 'not_member';
    END IF;

    -- Validar permissões
    v_is_admin := is_admin_org(v_org_id, v_uid);
    v_is_group_leader := is_group_leader(v_org_id, v_uid);
    v_has_subscription := has_active_mentor_subscription(v_org_id, v_uid);

    IF NOT v_is_admin AND NOT v_is_group_leader AND NOT v_has_subscription THEN
      RAISE EXCEPTION 'not_allowed';
    END IF;
  END IF;

  -- Buscar gabarito
  SELECT * INTO v_answer_key
  FROM answer_keys
  WHERE question_id = p_question_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING MESSAGE = 'answer key not found';
  END IF;

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
    'answer_key_viewed',
    'question',
    p_question_id,
    jsonb_build_object()
  );

  -- Retornar dados
  RETURN jsonb_build_object(
    'question_id', p_question_id,
    'answer_key_json', v_answer_key.answer_key_json
  );
END;
$$;

