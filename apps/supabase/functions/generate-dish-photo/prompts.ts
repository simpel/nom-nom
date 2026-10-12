// Image prompts for generate-dish-photo, written for Meta Muse Image (meta/muse-image-1.0).
//
// Muse plans the layout before it renders, so each prompt is a shoot brief in the order a
// photographer settles it: deliverable, subject, plating, surface, camera, light, style, and
// constraints last (https://runware.ai/docs/models/meta-muse-image/guides/prompting).
// - Plain sentences, one decision per clause; repeated or contradictory clauses get flattened.
// - Counts and positions stated outright; anything left open is re-decided on every call.
// - No `--ar` / `--no` flags or negative-prompt lists: Muse has no such parameters. The few
//   exclusions that matter (Muse likes to scatter props and garnish) are one closing sentence.
//
// Three subjects share one SETTING (same oak table, same overhead camera, same light):
// - recipe:   the plate alone, the cleanest shot of the food.
// - meal:     the same plate laid for eating: cutlery, a napkin and a drink beside it.
// - category: a spread of the category's signature dishes.

const PLATE =
  "round stoneware coupe plate with a shallow well and a low rim, in a matte off-white glaze with fine brown speckles";

const SURFACE =
  "one seamless slab of pale, lightly oiled European white oak with fine grain running left to right";

/** Everything every photo shares, so recipes, meals and categories read as one set. */
const SETTING = [
  `Everything sits on ${SURFACE}, and the oak fills the whole frame.`,
  "Shot from directly overhead with the camera pointing straight down, so plates and glasses read as full circles.",
  "Soft, diffused daylight comes from the upper left and casts gentle, open shadows toward the lower right; a soft ray of warm sunshine may fall across the wood, always with soft, blurred edges, never hard or harsh; exposure is bright and even, with neutral-warm colour.",
  "Sharp focus across all the food.",
  "Photoreal editorial food photography, natural colour, minimal styling.",
].join(" ");

/** One serving of one recipe, alone on one plate. */
export function recipePhotoPrompt(dish: string, elements: string, garnish: string): string {
  return [
    `A square cover photograph for a recipe in a recipe app showing one serving of ${dish}: ${elements}, finished with ${garnish}.`,
    `The food is generously plated in the centre of exactly one ${PLATE}, about 28 cm across. The plate is the only object in the photo.`,
    "The plate is centred and spans about three quarters of the frame's width, with an even margin of bare wood on every side.",
    SETTING,
    "The bare oak around the plate is clean: no cutlery, napkins, glasses, loose ingredients, crumbs or text anywhere in frame.",
  ].join("\n\n");
}

/** One serving as it was eaten: the plate laid with cutlery, a napkin and a drink. */
export function mealPhotoPrompt(dish: string, elements: string, garnish: string, beverage: string): string {
  return [
    `A square photograph of a meal at the table in a dinner diary app: one serving of ${dish}: ${elements}, finished with ${garnish}, laid for one person and ready to eat.`,
    `The food is generously plated on exactly one ${PLATE}, about 28 cm across, just left of centre.`,
    "To the right of the plate lie a fork and a knife on a folded natural linen napkin in an oatmeal tone.",
    `At the upper right of the plate stands ${beverage}.`,
    "The plate, napkin and drink together span about four fifths of the frame, with bare wood showing around them.",
    SETTING,
    "Only these four things are on the table: the plate, the cutlery, the napkin and the drink. No other dishes, loose ingredients, crumbs or text.",
  ].join("\n\n");
}

/** A spread of the category's signature dishes, each on its own plate or traditional vessel. */
export function categoryPhotoPrompt(category: string, dishes: string, vessels?: string): string {
  const plating = vessels
    ? `The dishes are served on ${vessels}; each plate is a ${PLATE}, and any traditional vessel is one typical of ${category}.`
    : `Each dish is served on a ${PLATE}, in sizes between 20 and 28 cm.`;

  return [
    `A square cover photograph for the ${category} category of a recipe app: a spread of ${dishes}, the food most typical of ${category}.`,
    `${plating} Every plate and vessel is generously filled with food.`,
    "The dishes are grouped together and cover about three quarters of the frame; every plate sits fully inside the frame with bare wood between it and each edge.",
    SETTING,
    "The bare oak around the dishes is clean: no cutlery, napkins, glasses, loose ingredients, crumbs or text anywhere in frame.",
  ].join("\n\n");
}

/**
 * Muse only renders eight fixed sizes; square is 1600x1600. Other models get the
 * OpenAI-style square size every image model on the Gateway accepts.
 */
export function imageSizeFor(model: string): string {
  return model.startsWith("meta/muse-image") ? "1600x1600" : "1024x1024";
}

/** The real format of the returned bytes (Muse returns WebP, most others PNG or JPEG). */
export function detectImageFormat(bytes: Uint8Array): { extension: string; contentType: string } {
  const ascii = (from: number, to: number) => String.fromCharCode(...bytes.slice(from, to));
  if (ascii(0, 4) === "RIFF" && ascii(8, 12) === "WEBP") return { extension: "webp", contentType: "image/webp" };
  if (bytes[0] === 0x89 && ascii(1, 4) === "PNG") return { extension: "png", contentType: "image/png" };
  return { extension: "jpg", contentType: "image/jpeg" };
}
