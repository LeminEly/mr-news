-- Bucket manquant pour le document justificatif à l'inscription agence.
-- (article-covers et agency-logos existent déjà ; le code utilise agency-documents)

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'agency-documents',
  'agency-documents',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

CREATE POLICY "agency_documents_agency_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'agency-documents'
    AND auth.uid() IS NOT NULL
  );

CREATE POLICY "agency_documents_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'agency-documents');
