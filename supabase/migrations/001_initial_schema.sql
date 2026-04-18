-- 
-- PLATEFORME D'ACTUALITÉS MAURITANIENNE
-- Migration: 001_initial_schema.sql
-- Supabase / PostgreSQL
-- 

-- EXTENSIONS 
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ENUMS 

CREATE TYPE agency_status AS ENUM (
  'pending',
  'approved',
  'rejected',
  'suspended'
);

CREATE TYPE media_type AS ENUM (
  'news_agency',
  'newspaper',
  'blog',
  'tv_channel',
  'radio',
  'other'
);

CREATE TYPE article_language AS ENUM (
  'ar',
  'fr'
);

CREATE TYPE emoji_type AS ENUM (
  'like',
  'wow',
  'sad',
  'angry',
  'fire'
);

CREATE TYPE report_reason AS ENUM (
  'fake_news',
  'inappropriate',
  'broken_link',
  'duplicate',
  'other'
);

CREATE TYPE report_status AS ENUM (
  'pending',
  'resolved',
  'dismissed'
);

-- TABLE: categories
CREATE TABLE categories (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_ar       TEXT NOT NULL,
  name_fr       TEXT NOT NULL,
  icon          TEXT NOT NULL DEFAULT '📰',
  color_hex     TEXT NOT NULL DEFAULT '#00c8a0',
  display_order INT  NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TABLE: agencies 
CREATE TABLE agencies (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_user_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name           TEXT NOT NULL,
  email          TEXT NOT NULL UNIQUE,
  logo_url       TEXT,
  website_url    TEXT NOT NULL,
  media_type     media_type NOT NULL DEFAULT 'news_agency',
  status         agency_status NOT NULL DEFAULT 'pending',
  reject_reason  TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  validated_at   TIMESTAMPTZ,

  CONSTRAINT agencies_name_length CHECK (char_length(name) >= 2),
  CONSTRAINT agencies_website_url_format CHECK (website_url ~* '^https?://')
);

-- Index pour les requêtes admin (lister par status)
CREATE INDEX idx_agencies_status ON agencies(status);
CREATE INDEX idx_agencies_auth_user ON agencies(auth_user_id);

-- TABLE: articles 
CREATE TABLE articles (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  agency_id       UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  category_id     UUID REFERENCES categories(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  source_url      TEXT NOT NULL,
  cover_image_url TEXT,
  language        article_language NOT NULL DEFAULT 'ar',
  is_active       BOOLEAN NOT NULL DEFAULT true,
  published_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT articles_title_length CHECK (char_length(title) >= 3),
  CONSTRAINT articles_url_format CHECK (source_url ~* '^https?://')
);

-- Index critiques pour les performances du feed
CREATE INDEX idx_articles_published_at ON articles(published_at DESC);
CREATE INDEX idx_articles_published_date ON articles(DATE(published_at));
CREATE INDEX idx_articles_agency_id ON articles(agency_id);
CREATE INDEX idx_articles_category_id ON articles(category_id);
CREATE INDEX idx_articles_active ON articles(is_active) WHERE is_active = true;

-- Trigger: auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER articles_updated_at
  BEFORE UPDATE ON articles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- TABLE: reactions
CREATE TABLE reactions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  device_id   TEXT NOT NULL,
  emoji_type  emoji_type NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Un seul vote par appareil par article
  CONSTRAINT reactions_unique_device_article UNIQUE (article_id, device_id)
);

CREATE INDEX idx_reactions_article_id ON reactions(article_id);

CREATE TRIGGER reactions_updated_at
  BEFORE UPDATE ON reactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- TABLE: reports
CREATE TABLE reports (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  device_id   TEXT NOT NULL,
  reason      report_reason NOT NULL,
  status      report_status NOT NULL DEFAULT 'pending',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,

  -- Un seul signalement par appareil par article
  CONSTRAINT reports_unique_device_article UNIQUE (article_id, device_id)
);

CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_article_id ON reports(article_id);

-- 
-- ROW LEVEL SECURITY (RLS)
-- 

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE agencies   ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles   ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports    ENABLE ROW LEVEL SECURITY;

-- Helper function: get current user role 
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'user_metadata' ->> 'role'),
    'anonymous'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Helper function: get agency id for current user
CREATE OR REPLACE FUNCTION get_current_agency_id()
RETURNS UUID AS $$
  SELECT id FROM agencies
  WHERE auth_user_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- POLICIES: categories

-- Tout le monde peut lire les catégories actives
CREATE POLICY "categories_select_all"
  ON categories FOR SELECT
  USING (is_active = true);

-- Seul l'admin peut gérer les catégories
CREATE POLICY "categories_insert_admin"
  ON categories FOR INSERT
  WITH CHECK (get_user_role() = 'admin');

CREATE POLICY "categories_update_admin"
  ON categories FOR UPDATE
  USING (get_user_role() = 'admin');

CREATE POLICY "categories_delete_admin"
  ON categories FOR DELETE
  USING (get_user_role() = 'admin');

-- POLICIES: agencies

-- Inscription libre (tout utilisateur auth peut créer son agence)
CREATE POLICY "agencies_insert_any_auth"
  ON agencies FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = auth_user_id);

-- Une agence peut lire son propre profil
CREATE POLICY "agencies_select_own"
  ON agencies FOR SELECT
  USING (auth_user_id = auth.uid());

-- L'admin peut tout lire
CREATE POLICY "agencies_select_admin"
  ON agencies FOR SELECT
  USING (get_user_role() = 'admin');

-- Une agence peut modifier ses propres infos (pas le status)
CREATE POLICY "agencies_update_own"
  ON agencies FOR UPDATE
  USING (auth_user_id = auth.uid())
  WITH CHECK (
    auth_user_id = auth.uid()
    AND status = (SELECT status FROM agencies WHERE id = agencies.id)
  );

-- L'admin peut tout modifier (dont le status)
CREATE POLICY "agencies_update_admin"
  ON agencies FOR UPDATE
  USING (get_user_role() = 'admin');

-- POLICIES: articles

-- Tout le monde peut lire les articles actifs
CREATE POLICY "articles_select_all"
  ON articles FOR SELECT
  USING (is_active = true);

-- L'agence peut voir ses propres articles (actifs ou non)
CREATE POLICY "articles_select_own_agency"
  ON articles FOR SELECT
  USING (
    agency_id = get_current_agency_id()
    AND get_user_role() = 'agency'
  );

-- L'admin peut tout voir
CREATE POLICY "articles_select_admin"
  ON articles FOR SELECT
  USING (get_user_role() = 'admin');

-- Seule une agence approuvée peut publier
CREATE POLICY "articles_insert_approved_agency"
  ON articles FOR INSERT
  WITH CHECK (
    get_user_role() = 'agency'
    AND agency_id = get_current_agency_id()
    AND EXISTS (
      SELECT 1 FROM agencies
      WHERE id = get_current_agency_id()
      AND status = 'approved'
    )
  );

-- Une agence peut modifier/supprimer ses propres articles
CREATE POLICY "articles_update_own_agency"
  ON articles FOR UPDATE
  USING (
    agency_id = get_current_agency_id()
    AND get_user_role() = 'agency'
  );

CREATE POLICY "articles_delete_own_agency"
  ON articles FOR DELETE
  USING (
    agency_id = get_current_agency_id()
    AND get_user_role() = 'agency'
  );

-- L'admin peut supprimer tout article
CREATE POLICY "articles_delete_admin"
  ON articles FOR DELETE
  USING (get_user_role() = 'admin');

-- L'admin peut désactiver tout article
CREATE POLICY "articles_update_admin"
  ON articles FOR UPDATE
  USING (get_user_role() = 'admin');

-- POLICIES: reactions

-- Tout le monde peut lire les réactions
CREATE POLICY "reactions_select_all"
  ON reactions FOR SELECT
  USING (true);

-- Tout le monde peut réagir (via device_id)
CREATE POLICY "reactions_insert_all"
  ON reactions FOR INSERT
  WITH CHECK (char_length(device_id) > 0);

-- On peut modifier sa propre réaction (changer d'emoji)
CREATE POLICY "reactions_update_own"
  ON reactions FOR UPDATE
  USING (true);

-- POLICIES: reports

-- Tout le monde peut signaler
CREATE POLICY "reports_insert_all"
  ON reports FOR INSERT
  WITH CHECK (char_length(device_id) > 0);

-- Seul l'admin peut lire et gérer les signalements
CREATE POLICY "reports_select_admin"
  ON reports FOR SELECT
  USING (get_user_role() = 'admin');

CREATE POLICY "reports_update_admin"
  ON reports FOR UPDATE
  USING (get_user_role() = 'admin');

-- 
-- VIEWS (pour faciliter les requêtes frontend)
-- 

-- Vue: articles avec infos agence et catégorie
CREATE OR REPLACE VIEW articles_with_details AS
SELECT
  a.id,
  a.title,
  a.source_url,
  a.cover_image_url,
  a.language,
  a.is_active,
  a.published_at,
  a.updated_at,
  ag.id          AS agency_id,
  ag.name        AS agency_name,
  ag.logo_url    AS agency_logo_url,
  ag.website_url AS agency_website,
  c.id           AS category_id,
  c.name_ar      AS category_name_ar,
  c.name_fr      AS category_name_fr,
  c.icon         AS category_icon,
  c.color_hex    AS category_color
FROM articles a
JOIN agencies ag ON a.agency_id = ag.id
LEFT JOIN categories c ON a.category_id = c.id
WHERE a.is_active = true
  AND ag.status = 'approved';

-- Vue: comptage des réactions par article
CREATE OR REPLACE VIEW article_reaction_counts AS
SELECT
  article_id,
  COUNT(*) FILTER (WHERE emoji_type = 'like')  AS like_count,
  COUNT(*) FILTER (WHERE emoji_type = 'wow')   AS wow_count,
  COUNT(*) FILTER (WHERE emoji_type = 'sad')   AS sad_count,
  COUNT(*) FILTER (WHERE emoji_type = 'angry') AS angry_count,
  COUNT(*) FILTER (WHERE emoji_type = 'fire')  AS fire_count,
  COUNT(*)                                      AS total_count
FROM reactions
GROUP BY article_id;

-- Vue: articles avec leurs comptages de réactions et signalements (pour admin)
CREATE OR REPLACE VIEW admin_articles_overview AS
SELECT
  a.id,
  a.title,
  a.source_url,
  a.language,
  a.is_active,
  a.published_at,
  ag.name        AS agency_name,
  c.name_fr      AS category_name,
  COALESCE(rc.total_count, 0) AS reaction_count,
  COALESCE(rp.report_count, 0) AS report_count
FROM articles a
JOIN agencies ag ON a.agency_id = ag.id
LEFT JOIN categories c ON a.category_id = c.id
LEFT JOIN article_reaction_counts rc ON a.id = rc.article_id
LEFT JOIN (
  SELECT article_id, COUNT(*) AS report_count
  FROM reports WHERE status = 'pending'
  GROUP BY article_id
) rp ON a.id = rp.article_id;

--
-- SEED DATA — Catégories par défaut
--

INSERT INTO categories (name_ar, name_fr, icon, color_hex, display_order) VALUES
  ('سياسة',    'Politique',    '🏛️', '#ef4444', 1),
  ('اقتصاد',   'Économie',     '📈', '#f59e0b', 2),
  ('رياضة',    'Sport',        '⚽', '#10b981', 3),
  ('تكنولوجيا','Technologie',  '💻', '#3b82f6', 4),
  ('مجتمع',    'Société',      '👥', '#8b5cf6', 5),
  ('صحة',      'Santé',        '🏥', '#ec4899', 6),
  ('ثقافة',    'Culture',      '🎭', '#f97316', 7),
  ('دولي',     'International','🌍', '#06b6d4', 8);

-- 
-- STORAGE BUCKETS CONFIG
--

-- Bucket: article-covers (public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'article-covers',
  'article-covers',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg','image/jpg','image/png','image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Bucket: agency-logos (public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'agency-logos',
  'agency-logos',
  true,
  2097152, -- 2MB
  ARRAY['image/jpeg','image/jpg','image/png','image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Storage RLS: agences peuvent upload leurs propres images
CREATE POLICY "article_covers_agency_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'article-covers'
    AND auth.uid() IS NOT NULL
  );

CREATE POLICY "article_covers_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'article-covers');

CREATE POLICY "agency_logos_agency_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'agency-logos'
    AND auth.uid() IS NOT NULL
  );

CREATE POLICY "agency_logos_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'agency-logos');
