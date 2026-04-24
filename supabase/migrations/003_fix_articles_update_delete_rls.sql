-- Les anciennes policies utilisaient get_user_role() = 'agency' (JWT user_metadata).
-- Si le rôle n'est pas présent dans le JWT, UPDATE/DELETE ne touchent aucune ligne
-- mais PostgREST renvoie quand même un succès → l'app affiche "supprimé" / "enregistré"
-- sans changement réel. On aligne sur la possession de l'agence (comme l'INSERT).

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
