-- generate-dish-photo now also makes meal photos (the plate laid with cutlery, a
-- napkin and a drink) for meals logged without one. Muse Image returns WebP, so
-- meal-photos accepts it like recipe-photos and category-photos.

update storage.buckets
   set allowed_mime_types = array['image/jpeg', 'image/webp']
 where id = 'meal-photos';
