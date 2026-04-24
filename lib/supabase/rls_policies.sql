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
