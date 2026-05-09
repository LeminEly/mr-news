-- À exécuter dans Supabase Dashboard → SQL Editor
--
-- Corrige l'erreur PostgREST 42501 :
--   new row violates row-level security policy for table "articles"
-- IMPORTANT :
-- Pour BLOQUER la publication tant que l'agence n'est pas approuvée,
-- on réactive une policy INSERT qui exige status = 'approved'.

DROP POLICY IF EXISTS "articles_insert_approved_agency" ON public.articles;
DROP POLICY IF EXISTS "articles_insert_own_agency" ON public.articles;

CREATE POLICY "articles_insert_approved_agency"
  ON public.articles FOR INSERT
  TO authenticated
  WITH CHECK (
    agency_id IN (
      SELECT id FROM public.agencies
      WHERE auth_user_id = auth.uid()
        AND status = 'approved'
    )
  );

-- Si vous aviez exécuté une ancienne version de ce fichier, retirer les doublons éventuels :
DROP POLICY IF EXISTS "agency_insert_articles" ON public.articles;
DROP POLICY IF EXISTS "agency_select_own_articles" ON public.articles;
DROP POLICY IF EXISTS "agency_update_own_articles" ON public.articles;
DROP POLICY IF EXISTS "agency_delete_own_articles" ON public.articles;
DROP POLICY IF EXISTS "agency_select_own_profile" ON public.agencies;
DROP POLICY IF EXISTS "agency_insert_own_profile" ON public.agencies;

CREATE POLICY "agency_insert_own_profile"
  ON public.agencies FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "agency_select_own_profile"
  ON public.agencies FOR SELECT
  TO authenticated
  USING (auth.uid() = auth_user_id);

-- Public can select approved agencies (to show names in feed)
DROP POLICY IF EXISTS "public_select_approved_agencies" ON public.agencies;
CREATE POLICY "public_select_approved_agencies"
  ON public.agencies FOR SELECT
  TO anon, authenticated
  USING (status = 'approved');

-- ─────────────────────────────────────────────────────────────────────────────
-- UPDATE / DELETE articles : aligner sur auth.uid() ↔ agencies (voir migration 003)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "articles_update_own_agency" ON public.articles;
DROP POLICY IF EXISTS "articles_delete_own_agency" ON public.articles;

CREATE POLICY "articles_update_own_agency"
  ON public.articles FOR UPDATE
  TO authenticated
  USING (
    agency_id IN (
      SELECT id FROM public.agencies
      WHERE auth_user_id = auth.uid()
    )
  )
  WITH CHECK (
    agency_id IN (
      SELECT id FROM public.agencies
      WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "articles_delete_own_agency"
  ON public.articles FOR DELETE
  TO authenticated
  USING (
    agency_id IN (
      SELECT id FROM public.agencies
      WHERE auth_user_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- UPDATE agencies : allow admins to change status
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "admin_update_agencies" ON public.agencies;

CREATE POLICY "admin_update_agencies"
  ON public.agencies FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
  )
  WITH CHECK (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- ADMIN ACCESS : COMPLETE POLICIES
-- ─────────────────────────────────────────────────────────────────────────────

-- Agencies SELECT for Admins
DROP POLICY IF EXISTS "admin_select_agencies" ON public.agencies;
CREATE POLICY "admin_select_agencies"
  ON public.agencies FOR SELECT
  TO authenticated
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Agencies UPDATE for Admins
DROP POLICY IF EXISTS "admin_update_agencies" ON public.agencies;
CREATE POLICY "admin_update_agencies"
  ON public.agencies FOR UPDATE
  TO authenticated
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  )
  WITH CHECK (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Reports SELECT for Admins
DROP POLICY IF EXISTS "admin_select_reports" ON public.reports;
CREATE POLICY "admin_select_reports"
  ON public.reports FOR SELECT
  TO authenticated
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- Reports UPDATE for Admins
DROP POLICY IF EXISTS "admin_update_reports" ON public.reports;
CREATE POLICY "admin_update_reports"
  ON public.reports FOR UPDATE
  TO authenticated
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );
