-- Migration: RLS Policies
-- Description: Implementa todas as RLS policies conforme RLS_POLICY_MAP.md

-- ============================================================================
-- Habilitar RLS em todas as tabelas
-- ============================================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_license_pool ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_license_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE studies ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE answer_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipleships ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_releases ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_releases ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3.1 organizations
-- ============================================================================

CREATE POLICY org_select_member ON organizations
  FOR SELECT
  USING (is_member(id));

-- ============================================================================
-- 3.2 user_profiles
-- ============================================================================

CREATE POLICY profile_select_self ON user_profiles
  FOR SELECT
  USING (id = auth.uid());

CREATE POLICY profile_update_self ON user_profiles
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY profile_insert_self ON user_profiles
  FOR INSERT
  WITH CHECK (id = auth.uid());

-- ============================================================================
-- 3.3 organization_members
-- ============================================================================

CREATE POLICY org_members_select_self ON organization_members
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY org_members_select_admin ON organization_members
  FOR SELECT
  USING (is_admin_org(org_id));

CREATE POLICY org_members_update_admin ON organization_members
  FOR UPDATE
  USING (is_admin_org(org_id))
  WITH CHECK (is_admin_org(org_id));

-- ============================================================================
-- 3.4 groups
-- ============================================================================

CREATE POLICY groups_select_member ON groups
  FOR SELECT
  USING (is_member(org_id));

CREATE POLICY groups_write_admin ON groups
  FOR INSERT
  WITH CHECK (is_admin_org(org_id));

CREATE POLICY groups_write_admin_update ON groups
  FOR UPDATE
  USING (is_admin_org(org_id))
  WITH CHECK (is_admin_org(org_id));

-- ============================================================================
-- 3.5 group_memberships
-- ============================================================================

CREATE POLICY group_memberships_select_member_or_leader_or_admin ON group_memberships
  FOR SELECT
  USING (
    is_admin_org(org_id)
    OR leads_group(org_id, group_id)
    OR user_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM group_memberships gm2
      WHERE gm2.group_id = group_memberships.group_id
        AND gm2.user_id = auth.uid()
    )
  );

CREATE POLICY group_memberships_insert_admin ON group_memberships
  FOR INSERT
  WITH CHECK (is_admin_org(org_id));

CREATE POLICY group_memberships_insert_group_leader_scoped ON group_memberships
  FOR INSERT
  WITH CHECK (leads_group(org_id, group_id));

-- ============================================================================
-- 3.6 group_leaders
-- ============================================================================

CREATE POLICY group_leaders_select_member_or_admin ON group_leaders
  FOR SELECT
  USING (
    is_admin_org(org_id)
    OR EXISTS (
      SELECT 1
      FROM group_memberships gm
      WHERE gm.group_id = group_leaders.group_id
        AND gm.user_id = auth.uid()
    )
    OR user_id = auth.uid()
  );

CREATE POLICY group_leaders_write_admin ON group_leaders
  FOR INSERT
  WITH CHECK (is_admin_org(org_id));

CREATE POLICY group_leaders_write_admin_update ON group_leaders
  FOR UPDATE
  USING (is_admin_org(org_id))
  WITH CHECK (is_admin_org(org_id));

CREATE POLICY group_leaders_write_admin_delete ON group_leaders
  FOR DELETE
  USING (is_admin_org(org_id));

-- ============================================================================
-- 3.7 invites
-- ============================================================================

CREATE POLICY invites_select_creator_or_admin ON invites
  FOR SELECT
  USING (
    is_admin_org(org_id)
    OR created_by_user_id = auth.uid()
  );

CREATE POLICY invites_insert_admin ON invites
  FOR INSERT
  WITH CHECK (is_admin_org(org_id));

CREATE POLICY invites_insert_group_leader_scoped ON invites
  FOR INSERT
  WITH CHECK (
    role_to_grant IN ('member', 'disciple', 'mentor')
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)
  );

CREATE POLICY invites_update_creator_or_admin ON invites
  FOR UPDATE
  USING (
    is_admin_org(org_id)
    OR created_by_user_id = auth.uid()
  )
  WITH CHECK (
    is_admin_org(org_id)
    OR created_by_user_id = auth.uid()
  );

-- ============================================================================
-- 3.8 org_subscriptions
-- ============================================================================

CREATE POLICY org_subscriptions_select_admin ON org_subscriptions
  FOR SELECT
  USING (is_admin_org(org_id));

-- ============================================================================
-- 3.9 org_license_pool
-- ============================================================================

CREATE POLICY license_pool_select_admin_or_group_leader ON org_license_pool
  FOR SELECT
  USING (
    is_admin_org(org_id)
    OR is_group_leader(org_id)
  );

CREATE POLICY license_pool_update_admin ON org_license_pool
  FOR UPDATE
  USING (is_admin_org(org_id))
  WITH CHECK (is_admin_org(org_id));

-- ============================================================================
-- 3.10 org_license_allocations
-- ============================================================================

CREATE POLICY license_allocations_select_self ON org_license_allocations
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY license_allocations_select_admin ON org_license_allocations
  FOR SELECT
  USING (is_admin_org(org_id));

CREATE POLICY license_allocations_select_group_leader_scoped ON org_license_allocations
  FOR SELECT
  USING (
    is_group_leader(org_id)
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)
  );

CREATE POLICY license_allocations_write_admin ON org_license_allocations
  FOR INSERT
  WITH CHECK (is_admin_org(org_id));

CREATE POLICY license_allocations_write_admin_update ON org_license_allocations
  FOR UPDATE
  USING (is_admin_org(org_id))
  WITH CHECK (is_admin_org(org_id));

CREATE POLICY license_allocations_write_group_leader_scoped ON org_license_allocations
  FOR INSERT
  WITH CHECK (
    is_group_leader(org_id)
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)
  );

CREATE POLICY license_allocations_write_group_leader_scoped_update ON org_license_allocations
  FOR UPDATE
  USING (
    is_group_leader(org_id)
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)
  )
  WITH CHECK (
    is_group_leader(org_id)
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)
  );

-- ============================================================================
-- 3.11 studies / modules / lessons / lesson_blocks / questions
-- ============================================================================

CREATE POLICY content_select_published_member ON studies
  FOR SELECT
  USING (
    (org_id IS NULL OR is_member(org_id))
    AND status = 'published'
  );

CREATE POLICY content_select_published_member ON modules
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM studies s
      WHERE s.id = modules.study_id
        AND (s.org_id IS NULL OR is_member(s.org_id))
        AND s.status = 'published'
    )
    AND status = 'published'
  );

CREATE POLICY content_select_published_member ON lessons
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM modules m
      JOIN studies s ON s.id = m.study_id
      WHERE m.id = lessons.module_id
        AND (s.org_id IS NULL OR is_member(s.org_id))
        AND s.status = 'published'
        AND m.status = 'published'
    )
    AND status = 'published'
  );

CREATE POLICY content_select_published_member ON lesson_blocks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM lessons l
      JOIN modules m ON m.id = l.module_id
      JOIN studies s ON s.id = m.study_id
      WHERE l.id = lesson_blocks.lesson_id
        AND (s.org_id IS NULL OR is_member(s.org_id))
        AND s.status = 'published'
        AND m.status = 'published'
        AND l.status = 'published'
    )
  );

CREATE POLICY content_select_published_member ON questions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM lessons l
      JOIN modules m ON m.id = l.module_id
      JOIN studies s ON s.id = m.study_id
      WHERE l.id = questions.lesson_id
        AND (s.org_id IS NULL OR is_member(s.org_id))
        AND s.status = 'published'
        AND m.status = 'published'
        AND l.status = 'published'
    )
  );

-- ============================================================================
-- 3.12 teacher_notes
-- ============================================================================

-- Nenhuma policy de SELECT (bloqueado - acesso somente via RPC)

-- ============================================================================
-- 3.13 answer_keys
-- ============================================================================

-- Nenhuma policy de SELECT (bloqueado - acesso somente via RPC)

-- ============================================================================
-- 3.14 discipleships
-- ============================================================================

CREATE POLICY discipleships_select_participants ON discipleships
  FOR SELECT
  USING (
    mentor_user_id = auth.uid()
    OR disciple_user_id = auth.uid()
  );

CREATE POLICY discipleships_select_admin ON discipleships
  FOR SELECT
  USING (is_admin_org(org_id));

CREATE POLICY discipleships_select_group_leader_scoped ON discipleships
  FOR SELECT
  USING (
    is_group_leader(org_id)
    AND shares_group_with_leader(org_id, mentor_user_id)
    AND shares_group_with_leader(org_id, disciple_user_id)
  );

CREATE POLICY discipleships_insert_mentor ON discipleships
  FOR INSERT
  WITH CHECK (
    org_id IS NOT NULL
    AND mentor_user_id = auth.uid()
    AND is_member(org_id)
    AND has_active_mentor_subscription(org_id)
  );

CREATE POLICY discipleships_update_mentor ON discipleships
  FOR UPDATE
  USING (
    mentor_user_id = auth.uid()
    AND org_id IS NOT NULL
  )
  WITH CHECK (
    mentor_user_id = auth.uid()
    AND org_id IS NOT NULL
  );

CREATE POLICY discipleships_update_admin ON discipleships
  FOR UPDATE
  USING (is_admin_org(org_id))
  WITH CHECK (is_admin_org(org_id));

-- ============================================================================
-- 3.15 lesson_releases
-- ============================================================================

CREATE POLICY lesson_releases_select_participants ON lesson_releases
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = lesson_releases.discipleship_id
        AND (d.mentor_user_id = auth.uid() OR d.disciple_user_id = auth.uid())
    )
  );

CREATE POLICY lesson_releases_insert_mentor ON lesson_releases
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = lesson_releases.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )
  );

-- ============================================================================
-- 3.16 question_releases
-- ============================================================================

CREATE POLICY question_releases_select_participants ON question_releases
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = question_releases.discipleship_id
        AND (d.mentor_user_id = auth.uid() OR d.disciple_user_id = auth.uid())
    )
  );

CREATE POLICY question_releases_insert_mentor ON question_releases
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = question_releases.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )
  );

-- ============================================================================
-- 3.17 answers
-- ============================================================================

CREATE POLICY answers_select_disciple ON answers
  FOR SELECT
  USING (disciple_user_id = auth.uid());

CREATE POLICY answers_select_mentor ON answers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = answers.discipleship_id
        AND d.mentor_user_id = auth.uid()
    )
  );

CREATE POLICY answers_select_admin ON answers
  FOR SELECT
  USING (is_admin_org(org_id));

CREATE POLICY answers_insert_disciple_when_released ON answers
  FOR INSERT
  WITH CHECK (
    disciple_user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = answers.discipleship_id
        AND d.disciple_user_id = auth.uid()
        AND d.status = 'active'
    )
    AND EXISTS (
      SELECT 1
      FROM question_releases qr
      WHERE qr.discipleship_id = answers.discipleship_id
        AND qr.lesson_id = answers.lesson_id
    )
  );

CREATE POLICY answers_update_disciple_limited ON answers
  FOR UPDATE
  USING (
    disciple_user_id = auth.uid()
    AND status IN ('draft', 'needs_changes')
  )
  WITH CHECK (disciple_user_id = auth.uid());

CREATE POLICY answers_update_mentor_limited ON answers
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = answers.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )
    AND status IN ('submitted', 'in_review', 'needs_changes')
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = answers.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )
  );

-- ============================================================================
-- 3.18 reviews
-- ============================================================================

CREATE POLICY reviews_select_mentor ON reviews
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = reviews.discipleship_id
        AND d.mentor_user_id = auth.uid()
    )
    OR is_admin_org(org_id)
  );

CREATE POLICY reviews_insert_mentor ON reviews
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = reviews.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )
  );

-- ============================================================================
-- 3.19 audit_events
-- ============================================================================

CREATE POLICY audit_select_admin_org ON audit_events
  FOR SELECT
  USING (
    org_id IS NOT NULL
    AND is_admin_org(org_id)
  );

-- ============================================================================
-- 3.20 webhook_logs
-- ============================================================================

-- Nenhuma policy (somente service role / edge functions)

