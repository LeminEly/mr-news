-- Fix: les agences en attente de validation ne pouvaient pas insérer d'articles
-- (policy "articles_insert_approved_agency" exigeait status = 'approved').
-- La vue publique articles_with_details filtre déjà ag.status = 'approved',
-- donc les articles d'une agence non approuvée ne sont pas exposés au feed.

DROP POLICY IF EXISTS "articles_insert_approved_agency" ON public.articles;

CREATE POLICY "articles_insert_own_agency"
  ON public.articles FOR INSERT
  TO authenticated
  WITH CHECK (
    agency_id IN (
      SELECT id FROM public.agencies
      WHERE auth_user_id = auth.uid()
    )
  );
