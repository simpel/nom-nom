#!/usr/bin/env bash
# ds-coverage: flag UI in the iOS app that has no equivalent in the design system.
#
# 1. Core/Components (errors): every file must map to a design-system component, i.e.
#    - its name starts with a component in design-system/components/ (ListRowSlots -> ListRow),
#      or with an alias below (SheetBody -> BottomSheet, DSSection -> Section), or
#    - it starts with `// DS-GAP` or its type name appears in Core/Design/DS-GAPS.md.
#    Foundations/ (axes, previews, camera plumbing) and *Gallery.swift previews are exempt.
# 2. Features/*/Components (warnings): a SwiftUI view that calls no design-system component
#    and is not named in DS-GAPS.md is probably hand-rolled.
#
# Usage: scripts/ds-coverage.sh
# Exit status: 0 when Core/Components is fully mapped, 1 otherwise. Warnings never fail.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DS_DIR="$ROOT/design-system/components"
IOS="$ROOT/apps/ios/NomNom"
GAPS="$IOS/Core/Design/DS-GAPS.md"

# Swift name prefix -> design-system component, where the two differ.
ALIASES="Sheet:BottomSheet DSSection:Section AppToggle:Toggle AppInput:Input RatingRow:RatingList"

COMPONENTS=()
while IFS= read -r d; do COMPONENTS+=("$(basename "$d")"); done < <(find "$DS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

# The Swift calls that count as "composes the design system" in a feature view.
DS_CALLS="AppButton|AppButtonLabel|Card|SectionCard|DSSection|ListRow|EmptyState|Badge|Avatar|Bar|ScoreValue|SectionHeader|AppToggle|Input|TextArea|PageHeader|DetailHeader|ScoreCard|PhotoCard|PhotoStrip|PhotoStripEditor|RatingList|Timeline|RecipeCard|RecipeLinkCard|RecipeShelf|PartyCard|SegmentedBar|ValueStepper|LabeledPhotoCard|TasteScoreSelector|SheetBody|SheetCard|SheetHero|SwipeableListCard|TrendChart|MediaViewerSheet|NameFieldsCard|PartyFormFields|VisibilityToggleCard|AccountActionsSection"

in_gaps() { grep -qw "$1" "$GAPS"; }

maps_to_ds() {
  local name="$1" c pair
  for c in "${COMPONENTS[@]}"; do [[ "$name" == "$c"* ]] && return 0; done
  for pair in $ALIASES; do [[ "$name" == "${pair%%:*}"* ]] && return 0; done
  return 1
}

errors=0
echo "Core/Components with no design-system equivalent:"
while IFS= read -r -d '' f; do
  rel="${f#"$ROOT/"}"
  name="$(basename "$f" .swift)"; name="${name%%+*}"
  [[ "$rel" == */Foundations/* || "$name" == *Gallery ]] && continue
  maps_to_ds "$name" && continue
  head -1 "$f" | grep -q '^// DS-GAP' && continue
  in_gaps "$name" && continue
  echo "  ERROR $rel: no design-system/components/<Name>/README.md and no DS-GAPS.md entry"
  errors=$((errors + 1))
done < <(find "$IOS/Core/Components" -type f -name '*.swift' -print0 | sort -z)
[[ $errors -eq 0 ]] && echo "  none"

warnings=0
echo "Feature views that use no design-system component:"
while IFS= read -r -d '' f; do
  rel="${f#"$ROOT/"}"
  name="$(basename "$f" .swift)"; name="${name%%+*}"
  grep -qE ':[[:space:]]*View[[:space:]]*\{|some View' "$f" || continue
  grep -qE "\\b($DS_CALLS)\\(" "$f" && continue
  in_gaps "$name" && continue
  echo "  WARN  $rel"
  warnings=$((warnings + 1))
done < <(find "$IOS/Features" -type f -path '*/Components/*' -name '*.swift' -print0 | sort -z)
[[ $warnings -eq 0 ]] && echo "  none"

echo "ds-coverage: $errors error(s), $warnings warning(s)"
[[ $errors -eq 0 ]]
