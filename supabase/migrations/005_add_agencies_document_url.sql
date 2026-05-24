-- URL publique du document justificatif (inscription agence).
ALTER TABLE public.agencies
  ADD COLUMN IF NOT EXISTS document_url TEXT;

COMMENT ON COLUMN public.agencies.document_url IS
  'URL Storage du document justificatif uploadé à l''inscription';
