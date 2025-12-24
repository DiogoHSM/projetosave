-- Migration: Initial Schema
-- Description: Cria todas as tabelas base do Projeto SAVE conforme DATA_MODEL.md

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable RLS by default (will be enabled per table)
ALTER DATABASE postgres SET row_security = on;

-- ============================================================================
-- 4.1 Organizações e usuários
-- ============================================================================

-- organizations
CREATE TABLE organizations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  type text NOT NULL CHECK (type IN ('church', 'individual')),
  name text NOT NULL,
  slug text UNIQUE,
  contact_email text,
  logo_url text,
  theme_json jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_organizations_type ON organizations(type);
CREATE INDEX idx_organizations_slug ON organizations(slug) WHERE slug IS NOT NULL;

-- user_profiles
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  phone text,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
-- 4.2 Membros e papéis administrativos
-- ============================================================================

-- organization_members
CREATE TABLE organization_members (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  role_admin_org boolean NOT NULL DEFAULT false,
  role_group_leader boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(org_id, user_id)
);

CREATE INDEX idx_org_members_org_id ON organization_members(org_id);
CREATE INDEX idx_org_members_user_id ON organization_members(user_id);
CREATE INDEX idx_org_members_status ON organization_members(status);

-- ============================================================================
-- 4.3 Igreja: grupos e escopo
-- ============================================================================

-- groups
CREATE TABLE groups (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(org_id, name)
);

CREATE INDEX idx_groups_org_id ON groups(org_id);

-- group_memberships
CREATE TABLE group_memberships (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(group_id, user_id)
);

CREATE INDEX idx_group_memberships_org_id ON group_memberships(org_id);
CREATE INDEX idx_group_memberships_group_id ON group_memberships(group_id);
CREATE INDEX idx_group_memberships_user_id ON group_memberships(user_id);

-- group_leaders
CREATE TABLE group_leaders (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(group_id, user_id)
);

CREATE INDEX idx_group_leaders_org_id ON group_leaders(org_id);
CREATE INDEX idx_group_leaders_group_id ON group_leaders(group_id);
CREATE INDEX idx_group_leaders_user_id ON group_leaders(user_id);

-- ============================================================================
-- 4.4 Convites e onboarding
-- ============================================================================

-- invites
CREATE TABLE invites (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email text NOT NULL,
  role_to_grant text NOT NULL CHECK (role_to_grant IN ('disciple', 'mentor', 'member', 'admin_org', 'group_leader')),
  group_id uuid REFERENCES groups(id) ON DELETE SET NULL,
  license_grants_json jsonb,
  token_hash text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'revoked', 'expired')),
  expires_at timestamptz,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_invites_org_id ON invites(org_id);
CREATE INDEX idx_invites_token_hash ON invites(token_hash);
CREATE INDEX idx_invites_status ON invites(status);
CREATE INDEX idx_invites_email ON invites(email);

-- ============================================================================
-- 4.5 Pagamentos e licenças
-- ============================================================================

-- org_subscriptions
CREATE TABLE org_subscriptions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  provider text NOT NULL,
  provider_customer_id text,
  provider_subscription_id text,
  status text NOT NULL,
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_org_subscriptions_org_id ON org_subscriptions(org_id);
CREATE INDEX idx_org_subscriptions_status ON org_subscriptions(status);

-- org_license_pool
CREATE TABLE org_license_pool (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL UNIQUE REFERENCES organizations(id) ON DELETE CASCADE,
  disciple_seats_total int NOT NULL DEFAULT 0,
  mentor_seats_total int NOT NULL DEFAULT 0,
  updated_by_user_id uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_license_pool_org_id ON org_license_pool(org_id);

-- org_license_allocations
CREATE TABLE org_license_allocations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  group_id uuid REFERENCES groups(id) ON DELETE SET NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  license_type text NOT NULL CHECK (license_type IN ('disciple', 'mentor')),
  quantity int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  granted_by_user_id uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_license_allocations_org_id ON org_license_allocations(org_id);
CREATE INDEX idx_license_allocations_user_id ON org_license_allocations(user_id);
CREATE INDEX idx_license_allocations_status ON org_license_allocations(status);
CREATE INDEX idx_license_allocations_group_id ON org_license_allocations(group_id) WHERE group_id IS NOT NULL;

-- ============================================================================
-- 4.6 Currículo (conteúdo base)
-- ============================================================================

-- studies
CREATE TABLE studies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid REFERENCES organizations(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  version int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_studies_org_id ON studies(org_id) WHERE org_id IS NOT NULL;
CREATE INDEX idx_studies_status ON studies(status);

-- modules
CREATE TABLE modules (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  study_id uuid NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  title text NOT NULL,
  position int NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(study_id, position)
);

CREATE INDEX idx_modules_study_id ON modules(study_id);

-- lessons
CREATE TABLE lessons (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  module_id uuid NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  title text NOT NULL,
  position int NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(module_id, position)
);

CREATE INDEX idx_lessons_module_id ON lessons(module_id);

-- lesson_blocks
CREATE TABLE lesson_blocks (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  block_type text NOT NULL CHECK (block_type IN ('text', 'image', 'video')),
  content_text text,
  media_url text,
  caption text,
  position int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(lesson_id, position)
);

CREATE INDEX idx_lesson_blocks_lesson_id ON lesson_blocks(lesson_id);

-- questions
CREATE TABLE questions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  question_type text NOT NULL CHECK (question_type IN ('open_text', 'multiple_choice', 'matching', 'true_false')),
  prompt text NOT NULL,
  options_json jsonb,
  position int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(lesson_id, position)
);

CREATE INDEX idx_questions_lesson_id ON questions(lesson_id);

-- teacher_notes (conteúdo do professor - sensível)
CREATE TABLE teacher_notes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  notes_text text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(lesson_id)
);

CREATE INDEX idx_teacher_notes_lesson_id ON teacher_notes(lesson_id);

-- answer_keys (gabarito - sensível)
CREATE TABLE answer_keys (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id uuid NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  answer_key_json jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(question_id)
);

CREATE INDEX idx_answer_keys_question_id ON answer_keys(question_id);

-- ============================================================================
-- 4.7 Discipulados
-- ============================================================================

-- discipleships
CREATE TABLE discipleships (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  mentor_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  disciple_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_discipleships_org_id ON discipleships(org_id);
CREATE INDEX idx_discipleships_mentor_user_id ON discipleships(mentor_user_id);
CREATE INDEX idx_discipleships_disciple_user_id ON discipleships(disciple_user_id);
CREATE INDEX idx_discipleships_status ON discipleships(status);

-- ============================================================================
-- 4.8 Liberação de conteúdo (por lição)
-- ============================================================================

-- lesson_releases
CREATE TABLE lesson_releases (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  discipleship_id uuid NOT NULL REFERENCES discipleships(id) ON DELETE CASCADE,
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  released_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  released_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(discipleship_id, lesson_id)
);

CREATE INDEX idx_lesson_releases_org_id ON lesson_releases(org_id);
CREATE INDEX idx_lesson_releases_discipleship_id ON lesson_releases(discipleship_id);
CREATE INDEX idx_lesson_releases_lesson_id ON lesson_releases(lesson_id);

-- question_releases
CREATE TABLE question_releases (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  discipleship_id uuid NOT NULL REFERENCES discipleships(id) ON DELETE CASCADE,
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  released_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  released_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(discipleship_id, lesson_id)
);

CREATE INDEX idx_question_releases_org_id ON question_releases(org_id);
CREATE INDEX idx_question_releases_discipleship_id ON question_releases(discipleship_id);
CREATE INDEX idx_question_releases_lesson_id ON question_releases(lesson_id);

-- ============================================================================
-- 4.9 Respostas e revisão
-- ============================================================================

-- answers
CREATE TABLE answers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  discipleship_id uuid NOT NULL REFERENCES discipleships(id) ON DELETE CASCADE,
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  question_id uuid NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  disciple_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'in_review', 'needs_changes', 'approved')),
  answer_payload jsonb NOT NULL,
  submitted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(discipleship_id, question_id)
);

CREATE INDEX idx_answers_org_id ON answers(org_id);
CREATE INDEX idx_answers_discipleship_id ON answers(discipleship_id);
CREATE INDEX idx_answers_disciple_user_id ON answers(disciple_user_id);
CREATE INDEX idx_answers_status ON answers(status);

-- reviews
CREATE TABLE reviews (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  discipleship_id uuid NOT NULL REFERENCES discipleships(id) ON DELETE CASCADE,
  lesson_id uuid NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  question_id uuid NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  answer_id uuid NOT NULL REFERENCES answers(id) ON DELETE CASCADE,
  reviewer_user_id uuid NOT NULL REFERENCES auth.users(id),
  decision text NOT NULL CHECK (decision IN ('approved', 'needs_changes')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_reviews_org_id ON reviews(org_id);
CREATE INDEX idx_reviews_discipleship_id ON reviews(discipleship_id);
CREATE INDEX idx_reviews_answer_id ON reviews(answer_id);

-- ============================================================================
-- 4.10 Auditoria e webhooks
-- ============================================================================

-- audit_events
CREATE TABLE audit_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id uuid REFERENCES organizations(id) ON DELETE SET NULL,
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  entity_type text,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_events_org_id ON audit_events(org_id) WHERE org_id IS NOT NULL;
CREATE INDEX idx_audit_events_actor_user_id ON audit_events(actor_user_id) WHERE actor_user_id IS NOT NULL;
CREATE INDEX idx_audit_events_event_type ON audit_events(event_type);
CREATE INDEX idx_audit_events_created_at ON audit_events(created_at DESC);

-- webhook_logs
CREATE TABLE webhook_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider text NOT NULL,
  event_id text NOT NULL,
  status text NOT NULL CHECK (status IN ('received', 'processed', 'failed')),
  payload jsonb NOT NULL,
  error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(provider, event_id)
);

CREATE INDEX idx_webhook_logs_provider ON webhook_logs(provider);
CREATE INDEX idx_webhook_logs_status ON webhook_logs(status);
CREATE INDEX idx_webhook_logs_created_at ON webhook_logs(created_at DESC);

-- ============================================================================
-- Triggers para updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em todas as tabelas com updated_at
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organization_members_updated_at BEFORE UPDATE ON organization_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_groups_updated_at BEFORE UPDATE ON groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_group_memberships_updated_at BEFORE UPDATE ON group_memberships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_group_leaders_updated_at BEFORE UPDATE ON group_leaders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invites_updated_at BEFORE UPDATE ON invites
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_org_subscriptions_updated_at BEFORE UPDATE ON org_subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_org_license_pool_updated_at BEFORE UPDATE ON org_license_pool
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_org_license_allocations_updated_at BEFORE UPDATE ON org_license_allocations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_studies_updated_at BEFORE UPDATE ON studies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modules_updated_at BEFORE UPDATE ON modules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lesson_blocks_updated_at BEFORE UPDATE ON lesson_blocks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON questions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teacher_notes_updated_at BEFORE UPDATE ON teacher_notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_answer_keys_updated_at BEFORE UPDATE ON answer_keys
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_discipleships_updated_at BEFORE UPDATE ON discipleships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lesson_releases_updated_at BEFORE UPDATE ON lesson_releases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_question_releases_updated_at BEFORE UPDATE ON question_releases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_answers_updated_at BEFORE UPDATE ON answers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_webhook_logs_updated_at BEFORE UPDATE ON webhook_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

