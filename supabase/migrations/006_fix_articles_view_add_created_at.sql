-- Fix: The articles_with_details view was missing created_at and reaction_counts.
-- ArticleModel.fromJson expects created_at (required) and reaction_counts.
-- Without created_at, parsing the Supabase response crashes at runtime.

CREATE OR REPLACE VIEW articles_with_details AS
SELECT
  a.id,
  a.title,
  a.source_url,
  a.cover_image_url,
  a.language,
  a.is_active,
  a.published_at,
  a.created_at,
  a.updated_at,
  ag.id          AS agency_id,
  ag.name        AS agency_name,
  ag.logo_url    AS agency_logo_url,
  ag.website_url AS agency_website,
  c.id           AS category_id,
  c.name_ar      AS category_name_ar,
  c.name_fr      AS category_name_fr,
  c.icon         AS category_icon,
  c.color_hex    AS category_color,
  jsonb_build_object(
    'like',  COALESCE(rc.like_count, 0),
    'wow',   COALESCE(rc.wow_count, 0),
    'sad',   COALESCE(rc.sad_count, 0),
    'angry', COALESCE(rc.angry_count, 0),
    'fire',  COALESCE(rc.fire_count, 0)
  ) AS reaction_counts
FROM articles a
JOIN agencies ag ON a.agency_id = ag.id
LEFT JOIN categories c ON a.category_id = c.id
LEFT JOIN article_reaction_counts rc ON a.id = rc.article_id
WHERE a.is_active = true
  AND ag.status = 'approved';
