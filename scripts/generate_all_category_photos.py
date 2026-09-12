#!/usr/bin/env python3
"""
Nom Nom — Category Photo Batch Generator
Generates editorial multi-dish spread food photographs for all culinary categories/kitchens
and persists them into Supabase Storage ('recipe-photos/categories/<slug>.jpg') and the
'public.categories' database table.

Locked Visual Environment:
- Matching round stoneware coupe plates (20-28cm, shallow well, matte beige reactive speckle glaze).
- Single continuous seamless oak surface (no planks, no joints, no grooves, fine horizontal grain).
- Elevated 3/4 angle looking down, cohesive multi-plate spread (75-80% frame coverage).
- Diffused upper-left natural daylight at 45 degrees, soft progressive shadow falloff.
- Strictly NO cutlery, forks, knives, spoons, chopsticks, napkins, glassware, or table props.
"""

import os
import sys
import json
import base64
import argparse
import urllib.request
import urllib.error

API_URL = os.environ.get("SUPABASE_URL", "http://127.0.0.1:54321")
SERVICE_ROLE_KEY = os.environ.get(
    "SUPABASE_SERVICE_ROLE_KEY",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
)

# Load AI Gateway key from supabase/functions/.env if not present in environment
def load_gateway_key():
    env_key = os.environ.get("VERCEL_AI_GATEWAY") or os.environ.get("AI_GATEWAY_API_KEY")
    if env_key:
        return env_key

    script_dir = os.path.dirname(os.path.abspath(__file__))
    fn_env = os.path.join(script_dir, "..", "supabase", "functions", ".env")
    if os.path.exists(fn_env):
        with open(fn_env, "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith("VERCEL_AI_GATEWAY="):
                    return line.split("=", 1)[1].strip()
    return None

GATEWAY_KEY = load_gateway_key()
GATEWAY_BASE_URL = os.environ.get("AI_GATEWAY_BASE_URL", "https://ai-gateway.vercel.sh/v1")
TEXT_MODEL = os.environ.get("AI_GATEWAY_TEXT_MODEL", "google/gemini-2.5-flash")
IMAGE_MODEL = os.environ.get("AI_IMAGE_MODEL", "bfl/flux-2-pro")


def fetch_categories():
    req = urllib.request.Request(f"{API_URL}/rest/v1/categories?select=*&order=slug.asc")
    req.add_header("apikey", SERVICE_ROLE_KEY)
    req.add_header("Authorization", f"Bearer {SERVICE_ROLE_KEY}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"Error fetching categories from database: {e}")
        return []


def resolve_category_dishes(category_name):
    prompt = f"""You are an expert culinary director and food photographer art director.
Analyze the culinary category / kitchen:
Category: {category_name}

Rules:
1. Category Spread: Select 3 to 4 iconic, visually complementary dishes representing the authentic culinary tradition of this kitchen/category.
2. Distinct Textures & Garnishes: Each dish should feature distinct textured components (e.g. braised, roasted, fresh, sauced) and classic culinary garnishes.
3. Category-Specific Traditional Vessels: If this culinary category has traditional, iconic plates or serving vessels strongly associated with its heritage (for example: a shallow rustic terracotta cazuela in Mexican or Spanish cuisine, a dark textured Japanese ceramic yakimono or tenmoku plate, an Indian hammered brass/earthenware handi, a Korean stone ttukbaegi bowl, or a French enameled cast-iron gratin dish), replace 1 or 2 of the plates in the picture with these authentic traditional vessels to better portray the category. The remaining dishes should stay on round stoneware coupe plates. If no unique traditional vessel is customary, use matching stoneware coupe plates throughout.
4. Strict Exclusion Rules: No Cutlery or Utensils (no forks, knives, spoons, chopsticks, skewers). No Table Props (no glasses, cups, napkins, ramekins, side bowls, condiment bottles, placemats). Never Render Empty Plates: every plate or vessel in the spread must be filled with food — no bare, unfilled, or empty dishware anywhere in frame.
5. Identify:
   - resolved_category: Canonical display name of the kitchen/category (e.g. "{category_name} Kitchen").
   - resolved_dishes: A descriptive narrative detailing the 3 to 4 dishes plated across the spread, explicitly specifying the plate or vessel each dish is served on (e.g. "a central round stoneware coupe plate of slow-braised cochinita pibil; a second dish of charred street-style elote served in an authentic shallow rustic Mexican terracotta cazuela; and a third coupe plate of fresh citrus ceviche").
   - vessels_narrative: Concise summary of the plating vessels (e.g. "two round stoneware coupe plates and one traditional rustic Mexican terracotta cazuela").

Return ONLY valid JSON matching:
{{
  "resolved_category": "string",
  "resolved_dishes": "string",
  "vessels_narrative": "string"
}}"""

    req = urllib.request.Request(
        f"{GATEWAY_BASE_URL}/chat/completions",
        data=json.dumps({
            "model": TEXT_MODEL,
            "messages": [{"role": "user", "content": prompt}],
            "response_format": {"type": "json_object"},
            "temperature": 0.3,
        }).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {GATEWAY_KEY}",
            "Content-Type": "application/json",
        }
    )

    resolved_cat = f"{category_name} Kitchen"
    resolved_dishes = "a central coupe plate with iconic regional main course, flanked by two complementary coupe plates of authentic side dishes and specialties"
    vessels_narrative = None

    try:
        with urllib.request.urlopen(req) as resp:
            res = json.loads(resp.read().decode("utf-8"))
            raw = res.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
            if raw.startswith("```json"): raw = raw[7:]
            if raw.startswith("```"): raw = raw[3:]
            if raw.endswith("```"): raw = raw[:-3]
            parsed = json.loads(raw.strip())
            resolved_cat = parsed.get("resolved_category", resolved_cat)
            resolved_dishes = parsed.get("resolved_dishes", resolved_dishes)
            vessels_narrative = parsed.get("vessels_narrative")
    except Exception as e:
        print(f"  [Notice] Using default dish narrative for {category_name} ({e})")

    return resolved_cat, resolved_dishes, vessels_narrative


def generate_category_image(resolved_cat, resolved_dishes, vessels_narrative=None):
    if vessels_narrative:
        plating_context = (
            f"The dishes are plated across {vessels_narrative}, harmoniously paired with round stoneware "
            f"coupe plates (20–28cm in diameter) with shallow curved wells (~1.5–2cm deep) and low uniform "
            f"raised rims (~1.5–2cm wide) with subtly hand-thrown edge profiles in a matte beige/off-white "
            f"glaze with fine brown-to-charcoal reactive speckles, where 1 or 2 plates are replaced by "
            f"authentic traditional serving vessels deeply characteristic of {resolved_cat} (such as rustic "
            f"earthenware, terracotta cazuela, or textured artisan ceramic)"
        )
    else:
        plating_context = (
            f"Each dish is neatly plated on round stoneware coupe plates of varying sizes (20–28cm in diameter) "
            f"with shallow curved wells (~1.5–2cm deep) and low uniform raised rims (~1.5–2cm wide) with subtly "
            f"hand-thrown edge profiles — matte beige/off-white glaze with fine brown-to-charcoal reactive speckles, "
            f"where 1 or 2 plates may be replaced by authentic traditional serving vessels deeply characteristic of {resolved_cat}"
        )

    image_prompt = (
        f"Directly overhead bird's-eye food photograph, camera mounted on an overhead rig pointing straight down at "
        f"the tabletop at exactly 90 degrees — a perfect right angle straight down (true top-down flat-lay perspective, like looking down through "
        f"the ceiling) — absolutely NOT eye-level, NOT a low angle, NOT a 3/4 angle, NOT a front-on or side-on view; "
        f"the viewer sees the tops of the plates as full circles/ovals with no vertical rim walls visible on the near "
        f"side. A professional editorial food photograph showcasing the essence of {resolved_cat}, "
        f"featuring a curated spread of {resolved_dishes}. {plating_context}. All vessels sit "
        f"harmoniously arranged together on a single continuous, seamless slab of natural oak — one uninterrupted "
        f"pale warm honey-beige wood surface — a consistent light tan/blonde oak color, exactly like fresh natural "
        f"European white oak flooring; the color must NEVER shift toward dark, reddish, orange, amber, walnut, or "
        f"rustic-distressed tones, and must show zero visible knots, zero dark mineral streaks, and zero patchy "
        f"color variation anywhere on the surface — with absolutely no plank boards, no joints, no seams, no grooves, "
        f"and no gaps anywhere; the grain of the wood runs perfectly horizontal, parallel to the bottom edge of the "
        f"frame, flowing left-to-right — the grain lines must never point toward or away from the camera, must never "
        f"run vertically (top-to-bottom), and must never run diagonally; fine, flat, straight-to-gently-wavy grain "
        f"lines flowing horizontally from left to right only, with no change "
        f"in surface height and no shadow lines suggesting a board edge, like one solid sanded panel. Finish is raw/lightly-oiled "
        f"matte — no gloss, scratches, stains, or props. The seamless oak wood tabletop completely fills the entire background "
        f"of the frame from edge to edge with no table edges, no room, no walls, no windows, no curtains, and no horizon line "
        f"visible anywhere — strictly wood surface and plates only. Shot straight down from directly overhead (true "
        f"top-down bird's-eye view, camera parallel to the tabletop), cohesive multi-plate spread composition occupying "
        f"75% of the frame with clean wood negative space around it; every plate and vessel must be fully contained "
        f"within the frame with a clear margin of wood on all sides — no plate or vessel may touch, overlap, extend "
        f"past, or be cropped by any edge of the frame. A single large, heavily diffused natural daylight source enters from the upper-left at roughly a 45-degree "
        f"angle (off-frame diffused daylight, no visible light source, no visible window, no curtains) — broad and wraparound, "
        f"with shadow edges that fade gradually rather than cutting a hard line, and shadows that stay open and detailed, never "
        f"going fully black. Exposure is medium-bright and evenly balanced, with no clipped white highlights and no crushed "
        f"blacks; neutral-to-warm color temperature, no artificial color cast. This creates gentle, low-intensity specular highlights "
        f"on glossy or oiled surfaces and smooth, soft tonal falloff on matte surfaces, with soft-edged, low-to-medium contrast "
        f"contact shadows falling diagonally to the lower-right of each vessel and food element. No backlight, no top light, "
        f"no fill light, no rim light, no spotlighting, no harsh direct sun, no hard-edged shadows, no blown highlights, no crushed "
        f"shadows. Critical sharp focus on food surface textures, shallow depth of field softly blurring the background wood into "
        f"clean negative space. Minimalist food styling, absolutely no cutlery, no forks, no knives, no spoons, no chopsticks, "
        f"no napkins, no glasses, no side bowls, curated dish vessels on wood only. Every plate and vessel in the spread must be "
        f"generously filled with food — never render an empty, bare, or unfilled plate or vessel anywhere in frame. --ar 1:1 --no "
        f"cutlery, forks, knives, spoons, chopsticks, napkins, glassware, cups, bottles, wood seams, plank lines, grooves, panel joints, "
        f"vertical wood grain, vertical grain, diagonal wood grain, table edges, walls, windows, curtains, room, background furniture, "
        f"empty plate, empty plates, bare plate, unfilled plate, empty vessel, empty bowl, eye-level angle, eye level shot, low angle, "
        f"front-on angle, side view, straight-on angle, 3/4 angle, oblique angle, dark wood, reddish wood, orange wood, "
        f"amber wood, walnut, rustic wood, distressed wood, weathered wood, wood knots, mineral streaks, uneven wood "
        f"color, patchy wood color, cropped plate, plate cut off, plate touching frame edge, plate extending past "
        f"frame, plate bleeding off edge --style raw --v 6.1"
    )

    req = urllib.request.Request(
        f"{GATEWAY_BASE_URL}/images/generations",
        data=json.dumps({
            "model": IMAGE_MODEL,
            "prompt": image_prompt,
            "n": 1,
            "size": "1024x1024",
        }).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {GATEWAY_KEY}",
            "Content-Type": "application/json",
        }
    )

    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        data = res.get("data", [])[0]
        if "b64_json" in data:
            return base64.b64decode(data["b64_json"])
        elif "url" in data:
            with urllib.request.urlopen(data["url"]) as img_resp:
                return img_resp.read()
        else:
            raise ValueError("No valid image data returned from AI gateway")


def upload_to_storage_and_update_db(slug, name, image_bytes):
    storage_path = f"{slug}.jpg"
    upload_url = f"{API_URL}/storage/v1/object/category-photos/{storage_path}"

    # 1. Upload to Supabase Storage
    req = urllib.request.Request(upload_url, data=image_bytes, method="POST")
    req.add_header("apikey", SERVICE_ROLE_KEY)
    req.add_header("Authorization", f"Bearer {SERVICE_ROLE_KEY}")
    req.add_header("Content-Type", "image/jpeg")
    req.add_header("x-upsert", "true")

    try:
        with urllib.request.urlopen(req) as resp:
            pass
    except urllib.error.HTTPError as e:
        # If POST fails with 400 duplicate, try PUT for update
        req_put = urllib.request.Request(upload_url, data=image_bytes, method="PUT")
        req_put.add_header("apikey", SERVICE_ROLE_KEY)
        req_put.add_header("Authorization", f"Bearer {SERVICE_ROLE_KEY}")
        req_put.add_header("Content-Type", "image/jpeg")
        with urllib.request.urlopen(req_put) as resp_put:
            pass

    # 2. Update categories table
    patch_url = f"{API_URL}/rest/v1/categories?slug=eq.{slug}"
    patch_req = urllib.request.Request(
        patch_url,
        data=json.dumps({
            "photo_path": storage_path,
        }).encode("utf-8"),
        method="PATCH"
    )
    patch_req.add_header("apikey", SERVICE_ROLE_KEY)
    patch_req.add_header("Authorization", f"Bearer {SERVICE_ROLE_KEY}")
    patch_req.add_header("Content-Type", "application/json")
    patch_req.add_header("Prefer", "return=representation")

    with urllib.request.urlopen(patch_req) as patch_resp:
        pass

    return storage_path


def main():
    parser = argparse.ArgumentParser(description="Batch generate category photographs with AI Gateway.")
    parser.add_argument("--list", action="store_true", help="List all categories and photo statuses")
    parser.add_argument("--category", type=str, help="Generate for a specific category slug or name")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing category photos")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of categories to generate")
    args = parser.parse_args()

    categories = fetch_categories()
    if not categories:
        print("No categories found in database. Make sure local Supabase is running and migrations applied.")
        sys.exit(1)

    if args.list:
        print(f"\nFound {len(categories)} categories:")
        for c in categories:
            status = f"[Has Photo: {c.get('photo_path')}]" if c.get('photo_path') else "[No Photo]"
            print(f"  • {c['slug']:<18} ({c['name']:<16}) {status}")
        return

    if not GATEWAY_KEY:
        print("Error: VERCEL_AI_GATEWAY key not found. Please set VERCEL_AI_GATEWAY in environment or supabase/functions/.env")
        sys.exit(1)

    targets = categories
    if args.category:
        target_name = args.category.strip().lower()
        targets = [c for c in categories if c['slug'].lower() == target_name or c['name'].lower() == target_name]
        if not targets:
            print(f"Category '{args.category}' not found in database. Creating custom entry...")
            targets = [{"slug": target_name.replace(" ", "-"), "name": args.category, "photo_path": None}]
    elif not args.overwrite:
        targets = [c for c in categories if not c.get("photo_path")]

    if args.limit:
        targets = targets[:args.limit]

    print(f"\nTargeting {len(targets)} categories for generation (overwrite={args.overwrite})...")
    for i, cat in enumerate(targets, 1):
        slug = cat["slug"]
        name = cat["name"]
        print(f"\n[{i}/{len(targets)}] Resolving dishes for {name} ({slug})...")
        resolved_cat, resolved_dishes, vessels_narrative = resolve_category_dishes(name)
        print(f"  Resolved: {resolved_cat}")
        print(f"  Dishes: {resolved_dishes[:80]}...")
        if vessels_narrative:
            print(f"  Vessels: {vessels_narrative}")

        print(f"  Generating image via {IMAGE_MODEL}...")
        try:
            img_bytes = generate_category_image(resolved_cat, resolved_dishes, vessels_narrative)
            path = upload_to_storage_and_update_db(slug, name, img_bytes)
            print(f"  ✔ Successfully saved to {path} and updated categories table!")
        except Exception as e:
            print(f"  ✖ Failed to generate/upload for {name}: {e}")

    print("\nBatch generation process completed.")


if __name__ == "__main__":
    main()
