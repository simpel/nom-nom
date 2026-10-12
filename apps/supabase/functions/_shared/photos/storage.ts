// Saves a generated photo and attaches it to the row it was made for.

import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

type ImageFormat = { extension: string; contentType: string };

/**
 * A photo for one row that keeps a `photo_paths` array (recipes, meals): uploaded to
 * `<bucket>/<id>/<uuid>.<ext>` and put first in the row's photo_paths. Returns the path.
 */
export async function attachRowPhoto(
  admin: SupabaseClient,
  target: { bucket: string; table: "recipes" | "meals"; id: string },
  bytes: Uint8Array,
  format: ImageFormat,
): Promise<string | null> {
  const path = `${target.id.toLowerCase()}/${crypto.randomUUID().toLowerCase()}.${format.extension}`;

  const { error: uploadErr } = await admin.storage
    .from(target.bucket)
    .upload(path, bytes, { contentType: format.contentType, upsert: true });
  if (uploadErr) {
    console.error(`Failed to upload photo to ${target.bucket}:`, uploadErr);
    return null;
  }

  const { data: row } = await admin.from(target.table).select("photo_paths").eq("id", target.id).single();
  const existing: string[] = row?.photo_paths || [];
  const { error: dbErr } = await admin
    .from(target.table)
    .update({ photo_paths: [path, ...existing.filter((p) => p !== path)] })
    .eq("id", target.id);
  if (dbErr) {
    console.error(`Failed to attach generated photo to ${target.table} ${target.id}:`, dbErr);
  }
  return path;
}

/** A category's photo: `category-photos/<slug>.<ext>`, upserted onto the categories row. */
export async function saveCategoryPhoto(
  admin: SupabaseClient,
  name: string,
  bytes: Uint8Array,
  format: ImageFormat,
): Promise<string | null> {
  const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  const path = `${slug}.${format.extension}`;

  const { error: uploadErr } = await admin.storage
    .from("category-photos")
    .upload(path, bytes, { contentType: format.contentType, upsert: true });
  if (uploadErr) {
    console.error("Failed to upload category image to storage:", uploadErr);
    return null;
  }

  const { error: dbErr } = await admin
    .from("categories")
    .upsert(
      { slug, name: name.trim(), photo_path: path, updated_at: new Date().toISOString() },
      { onConflict: "slug" },
    );
  if (dbErr) console.error("Failed to update categories table:", dbErr);
  return path;
}
