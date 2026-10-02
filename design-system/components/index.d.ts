// Nom Nom — the React API of components/bundle.js (window.NomNom). Types are documentation.
// Every component follows one convention:
//   variant    — colour role: 'primary' | 'secondary' | 'destructive' | 'pro' (+ Badge: 'warning' | 'reaction')
//   appearance — visual weight: 'solid' | 'soft' | 'outline' | 'ghost' | 'elevated' (Badge: 'soft' | 'solid' | 'elevated')
//   size       — 'xs' | 'sm' | 'md' | 'lg' (Badge: 'sm' | 'md'; Avatar and Bar: 'xs' … 'xl')
//   layout     — structural variant of a composite component (Card: 'block' | 'list'; ScoreCard: 'hero' | 'compact')
//   textStyle + tone — copy, always through <Text> (no component writes its own font rules)
//   icon + iconPosition — glyph name from bundle.css (`nn-i-<name>`), 'start' | 'end'
// Interaction states (hover, pressed, focus, disabled, loading, selected) are never appearance values.

/** Six-step taste scale. Raw values persist: -1, 1, 2, 3, 4, 5. `null` = not rated. */
export type Reaction = 'inedible' | 'bad' | 'meh' | 'good' | 'great' | 'amazing';
export type Variant = 'primary' | 'secondary' | 'destructive' | 'pro';
export type Appearance = 'solid' | 'soft' | 'outline' | 'ghost' | 'elevated';
export type Size = 'xs' | 'sm' | 'md' | 'lg';
export type IconPosition = 'start' | 'end';
/** A glyph name: sparkles, bolt, star, check-circle, thumbs-up, flame, wrench, repeat, calendar, archive,
 *  arrow-up-right, arrow-down-right, arrow-right, chevron-left, chevron-right, x, x-circle, search, heart,
 *  circle-dashed, plus, camera, trash, utensils, mail, clock, leaf. */
export type IconName = string;

export type TextStyle = 'serif-xs' | 'serif-sm' | 'serif-md' | 'serif-lg' | 'serif-xl' | 'sans-xs' | 'sans-sm' | 'sans-md' | 'sans-lg' | 'sans-xl';

/** The one way to set copy. */
/** Every component takes these. The system styles itself; `className` and `style` are for layout
 *  in the page around it, not for re-skinning a component. */
export interface BaseProps {
  className?: string;
  style?: Record<string, string | number>;
}

export interface TextProps extends BaseProps {
  /** A Typography token. @default 'sans-md' */
  textStyle?: TextStyle;
  /** primary = text-primary · accent = primary-text (scores, live counts). @default 'primary' */
  tone?: 'primary' | 'secondary' | 'tertiary' | 'accent';
  weight?: 'normal' | 'semibold';
  italic?: boolean;
  /** Tabular figures. */
  numeric?: boolean;
  align?: 'center';
  /** Clamp to N lines. */
  lines?: number;
  /** @default 'span' */
  as?: string;
  children?: unknown;
}

/** The one surface: panel, radius-3xl. */
export interface CardProps extends BaseProps {
  /** sm = spacing-4 · md = spacing-5. @default 'md' */
  size?: 'sm' | 'md';
  /** 'primary' = the featured tint (opacity-10). */
  variant?: 'primary';
  /** 'list' = rows separated by 1px line. @default 'block' */
  layout?: 'block' | 'list';
  /** Either makes the card pressable with a trailing chevron. */
  onClick?: () => void;
  href?: string;
  /** @default 'div' */
  as?: string;
  children?: unknown;
}

/** SectionHeader above any content. */
export interface SectionProps extends BaseProps {
  title?: string;
  trailing?: string;
  trailingTone?: 'tertiary' | 'accent';
  uppercase?: boolean;
  icon?: IconName;
  children?: unknown;
}

/** Score numeral (accent, tabular) + verdict word. */
export interface ScoreValueProps extends BaseProps {
  /** 0–100; null = "—" Unrated. */
  score: number | null;
  verdict?: string;
  /** xs = numeral only (rows) · sm · md · lg (hero). @default 'lg' */
  size?: 'xs' | 'sm' | 'md' | 'lg';
  showVerdict?: boolean;
}

/** Read-only bar: primary fill over the track. */
/** One segment of a Bar. */
export interface BarSegment {
  value: number;
  /** Paints the step's reaction fill. */
  reaction?: Reaction;
  /** Any other colour token, e.g. 'var(--chart-series2)'. */
  color?: string;
  /** Tooltip text; the visible key is SegmentedBar's job. */
  label?: string;
}

/** The one bar. One fill or several blocks, xs to xl. */
export interface BarProps extends BaseProps {
  /** Single fill: 0–max; null = empty ("Not rated"). Ignored when `segments` is given. */
  value?: number | null;
  /** Several blocks, each sized by its share of the sum — or of `max`, which leaves a remainder of track. */
  segments?: BarSegment[];
  /** @default 100 for a single fill; the sum of the segments otherwise. */
  max?: number;
  /** Thickness 4 / 6 / 8 / 10 / 12 px (spacing-1 / 1.5 / 2 / 2.5 / 3). @default 'md' */
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  /** Accessible name. A single fill defaults to '<value> out of <max>'; segments need one. */
  label?: string;
}

export interface AppButtonProps extends BaseProps {
  /** Or pass as children. With `iconOnly` it becomes the accessible name. */
  label?: string;
  /** 'reaction' only inside rating controls (TasteScoreSelector). @default 'primary' */
  variant?: Variant | 'reaction';
  /** With variant 'reaction'. */
  reaction?: Reaction;
  /** @default 'solid' */
  appearance?: Appearance;
  /** Heights spacing-9 / 11 / 12 (36 / 44 / 48). @default 'md' */
  size?: Size;
  icon?: IconName;
  /** @default 'start' */
  iconPosition?: IconPosition;
  /** Circle as wide as it is tall; `label` is required. */
  iconOnly?: boolean;
  fullWidth?: boolean;
  /** Spinner in the icon slot, button disabled, aria-busy. */
  loading?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
}

export interface BadgeProps extends BaseProps {
  /** Or pass as children. Sentence case. */
  label?: string;
  /** @default 'primary' */
  variant?: Variant | 'warning' | 'reaction';
  /** Required with variant 'reaction'. */
  reaction?: Reaction;
  /** @default 'soft'. 'solid' falls back to soft for reaction (a reaction fill never carries text). */
  appearance?: 'soft' | 'solid' | 'elevated';
  /** Heights spacing-5 / 6 (20 / 24). @default 'md' */
  size?: 'sm' | 'md';
  icon?: IconName;
  /** @default 'start' */
  iconPosition?: IconPosition;
  /** Tooltip, e.g. the score behind a verdict word. A badge never combines a number and a word. */
  title?: string;
}

export interface InputProps extends BaseProps {
  placeholder?: string;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  /** Lifts the field to spacing-14 and sets the label sans-xs above the text. */
  label?: string;
  leadingIcon?: IconName;
  trailingIcon?: IconName;
  /** One style: `soft`, a sunken ground with a 1px line. `plain` is not a style — it strips the ground and
   *  padding for a field inside a Card list row, where the row already draws them. @default 'soft' */
  appearance?: 'soft' | 'plain';
  /** Adds the clear button once there is text. */
  clearable?: boolean;
  /** A sentence under the field, replaced by `error`. */
  hint?: string;
  /** true draws the error state; a string also prints it under the field with an alert glyph. */
  error?: boolean | string;
  /** Shown, not editable: panel ground, text-secondary. Not the same as disabled. */
  readOnly?: boolean;
  disabled?: boolean;
  /** Any other attribute of the control goes straight to the <input>: id, name, type,
   *  autoComplete, inputMode, required, pattern, min, max, onBlur, onFocus, and so on. */
  [attr: string]: unknown;
}

export interface TextAreaProps extends BaseProps {
  placeholder?: string;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  label?: string;
  /** @default 3 */
  rows?: number;
  appearance?: 'soft' | 'plain';
  /** Adds a live "{n} / {max}" counter; going over turns the field and the counter to the error state. */
  maxLength?: number;
  hint?: string;
  error?: boolean | string;
  readOnly?: boolean;
  disabled?: boolean;
  /** Any other attribute of the control goes straight to the <textarea>. */
  [attr: string]: unknown;
}

export interface TasteScoreSelectorProps extends BaseProps {
  value?: Reaction | null;
  defaultValue?: Reaction | null;
  onChange?: (next: Reaction | null) => void;
  /** Accessible group name. @default 'Taste' */
  label?: string;
  /** The verdict word under the row. @default true */
  showVerdict?: boolean;
  disabled?: boolean;
}

/** The one small label, wherever it sits — above a list or inside a card. It draws no surface and reserves
 *  no space around itself; the parent does both. Pass `title` to Section, SectionCard or Card rather than
 *  nesting a header, and those place it correctly. */
export interface SectionHeaderProps extends BaseProps {
  title: string;
  /** false sets the label as written, for a possessive or personal label ("Joel's note"). @default true */
  uppercase?: boolean;
  /** One figure on the right — a count, a byline, a score. Never a second label, never a button. */
  trailing?: unknown;
  /** The figure's ink. 'accent' for a live count. @default 'tertiary' */
  trailingTone?: 'tertiary' | 'accent';
  icon?: IconName;
  /** 'primary' — title primary-text semibold. Only inside a featured card, and only on one label there. */
  variant?: 'primary';
  /** The title element: 'h2' above content, 'span' inside a card or header. @default 'h2' */
  as?: string;
}

/** A Card whose label sits inside it. One shape — Card + Eyebrow + optional quote.
 *  A label *above* a card is `<Section title=…><Card>…</Card></Section>`, not this. */
export interface SectionCardProps extends BaseProps {
  /** The Eyebrow inside the card. */
  title?: string;
  /** One figure beside the label — a count, a date. */
  trailing?: unknown;
  trailingTone?: 'tertiary' | 'accent';
  /** false for a possessive label ("Joel's note"). @default true */
  uppercase?: boolean;
  icon?: IconName;
  /** 'primary' tints the card and turns the label primary-text semibold. */
  variant?: 'primary';
  /** The cook's note: italic serif-xs, no quotation marks. */
  quote?: string;
  onClick?: () => void;
  children?: unknown;
}

export interface AvatarProps extends BaseProps {
  /** The name is visible beside the avatar: hide it from assistive tech so it is not read twice. */
  decorative?: boolean;
  /** Accessible name; first + last word give the initials. */
  name: string;
  photo?: string;
  /** 24 / 32 / 40 / 56 / 80 (spacing-6 / 8 / 10 / 14 / 20). @default 'md' */
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  /** Shown instead of the initials (max two characters). */
  text?: string;
}

export interface PhotoCardProps extends BaseProps {
  src?: string;
  alt?: string;
  /** The tile's LONG edge: xs 80 (RecipeLinkCard, no badge) · sm and md 192 · lg 288 (PhotoStrip). @default 'md' */
  size?: 'xs' | 'sm' | 'md' | 'lg';
  /** The tile's shape. Portrait and landscape are both 3:4, so a size gives 80/192/288 on the long edge and
   *  60/144/216 on the short one. Defaults per size: xs square · sm portrait · md square · lg portrait. */
  format?: 'square' | 'portrait' | 'landscape';
  /** 0–100; renders the verdict as an elevated reaction Badge, bottom-right. */
  score?: number | null;
  verdict?: string;
  /** Any Badge instead of the verdict. */
  badge?: BadgeProps;
  /** 2px primary ring. */
  selected?: boolean;
  /** Is it a favourite? Fills the heart and turns it destructive-text; false leaves it outlined. */
  favorite?: boolean;
  /** Makes the heart pressable and shows it even when `favorite` is false. Without it the heart is a marker. */
  onToggleFavorite?: () => void;
  /** Extra overlays, e.g. a favourite heart. */
  children?: unknown;
}

export interface RecipeCardProps extends BaseProps {
  /** Alt text for the photo. Leave unset only when the title beside it names the dish. */
  alt?: string;
  title: string;
  photo?: string;
  /** Eyebrow, e.g. 'Italian'. @default 'Recipe' */
  category?: string;
  /** Owner's short name when it isn't the viewer. */
  by?: string;
  favorite?: boolean;
  /** 0–100; shown as its verdict word in an elevated reaction Badge on the photo. */
  score?: number | null;
  /** Overrides the verdict word. */
  verdict?: string;
}

export interface PhotoStripProps extends BaseProps {
  /** PhotoCard's format, shared by every tile — a strip never mixes formats. @default 'portrait' */
  format?: 'square' | 'portrait' | 'landscape';
  /** Rendered as PhotoCard lg. */
  photos: { src: string; alt?: string; score?: number | null }[];
  /** Omit when the viewer can't add photos. Renders an Add photo tile as the strip's last tile, the same size and format as a photo (the only tile when there are no photos). */
  onAddPhoto?: () => void;
  /** Label of the add tile when there are no photos. @default 'Add a photo' */
  emptyTitle?: string;
  /** @deprecated No effect: the floating Add photo button was replaced by the trailing add tile. */
  collapsed?: boolean;
}

export interface DetailHeaderProps extends BaseProps {
  title: string;
  /** Uppercase category above the title (recipes). */
  eyebrow?: string;
  /** Above the title; below it when there is an eyebrow or avatar. */
  meta?: string;
  summary?: string;
  /** Rendered at size 'xl' unless given. */
  avatar?: AvatarProps;
  /** Badges, variant 'secondary' by default. */
  /** Metadata about the subject — time, method, servings. Joined with " · " into one tertiary line, not chips. */
  facts?: string[];
  /** The few things that are a status rather than a fact: Staple, Pro, Archived. Badge props. */
  badges?: BadgeProps[];
  /** Up to two; rendered lg, sharing the row. One solid action per header. */
  actions?: AppButtonProps[];
  /** @default 'start' */
  align?: 'start' | 'center';
}

export interface RecipeLinkCardProps extends BaseProps {
  /** Alt text for the thumbnail. */
  alt?: string;
  /** The thumbnail's PhotoCard format. @default 'portrait' */
  format?: 'square' | 'portrait' | 'landscape';
  name: string;
  photo?: string;
  /** @default 'Recipe' */
  eyebrow?: string;
  /** Joined with " · ", e.g. ['30–60 min', 'Baking', 'Pizza']. */
  meta?: string[];
  href?: string;
}

export interface ScoreCardProps extends BaseProps {
  /** @default 'hero' */
  layout?: 'hero' | 'compact';
  /** 'primary' features the score (health): tinted card, primary label, larger numeral. */
  variant?: 'primary';
  /** Glyph before the title, e.g. 'leaf'. */
  icon?: IconName;
  /** One line under the bar. */
  caption?: string;
  /** 0–100; null = unrated ("—", "Unrated"). */
  score: number | null;
  /** @default verdict for the score */
  verdict?: string;
  /** Uppercase label, e.g. 'Household score'. */
  title?: string;
  /** Signed change; renders a Badge (primary up, warning down, secondary flat). */
  delta?: number;
  /** Hero only: the sentence after the delta Badge. */
  deltaText?: string;
  deltaReference?: string;
  /** e.g. '12 meals'. */
  count?: string;
  /** Makes the card a button with a chevron. */
  onClick?: () => void;
}

/** One row of a RatingList: a label, an optional note, a trailing value. */
export interface RatingListRow {
  label: unknown;
  note?: unknown;
  value?: unknown;
}

/** The one "section header + meter + list of rows" block. Pass `raters` for the meal shape,
 *  or `rows` + `bar` for any other distribution (SegmentedBar's breakdown uses the latter). */
export interface RatingListProps extends BaseProps {
  /** @default 'Who rated' */
  title?: string;
  /** Right-hand figure in the header. Defaults to "{rated} of {total}" when `total` is given. */
  trailing?: unknown;
  /** score null = not rated yet; vsUsual: signed change, 0 = as usual, 'new' = first rating. */
  raters?: { name: string; role?: string; score?: number | null; vsUsual?: number | 'new' }[];
  /** The general shape. Takes precedence over `raters`. */
  rows?: RatingListRow[];
  rated?: number;
  total?: number;
  /** Replaces the default Bar above the card — SegmentedBar passes its own here. */
  bar?: unknown;
}

export interface TimelineProps extends BaseProps {
  /** 'md' (default): PhotoCard sm tiles with the verdict Badge under a "N times" header. 'mini': PhotoCard xs squares with the date only, no badge and no header unless `title` is given — for cards (PartyCard's recent meals). */
  size?: 'md' | 'mini';
  /** @default 'This recipe over time' (md); none (mini) */
  title?: string;
  /** `score` drives the verdict Badge (md only; mini ignores it). */
  occasions: { date?: string; score?: number; verdict?: string; photo?: string; alt?: string; current?: boolean; href?: string }[];
}

export interface BottomSheetProps extends BaseProps {
  /** The heading element for the title, so a nested block does not skip a level. @default 'h2' */
  titleAs?: string;
  title: string;
  onClose?: () => void;
  /** Hero numeral; verdict defaults to the score's. */
  score?: number;
  verdict?: string;
  /** One sentence under the hero. */
  lead?: unknown;
  children?: unknown;
}

/** The one row. Leading slot · title + meta · value · trailing slot · chevron. Lives inside <Card layout="list">. */
export interface ListRowProps extends BaseProps {
  /** Avatar, PhotoCard 'xs', a rank numeral, an Icon. */
  leading?: unknown;
  /** A string is set for you (semibold when the row is pressable or unread). */
  title: unknown;
  /** The second line: a string becomes sans-sm / secondary. */
  meta?: unknown;
  /** Right-aligned value of a key–value row (tabular). Mutually exclusive with `trailing` in practice. */
  value?: unknown;
  /** Badge, ScoreValue 'xs', AppButton 'sm', Toggle. Giving this to a pressable row splits the row:
   *  the title region becomes the button or link and the trailing slot stays its sibling, so an
   *  interactive control is never nested inside another. */
  trailing?: unknown;
  /** @default true when pressable */
  chevron?: boolean;
  /** Unread notification: a primary dot in the gutter and a semibold title. */
  unread?: boolean;
  /** Accessible name for the pressable region when the title alone is not enough (split rows only). */
  'aria-label'?: string;
  /** 'destructive' for Leave, Delete account and the like. */
  variant?: 'destructive';
  /** @default 'md' (spacing-14 minimum) */
  size?: 'sm' | 'md';
  onClick?: () => void;
  href?: string;
  children?: unknown;
}

/** The one switch: an AppButton restyled as a track. Only ever a ListRow trailing slot. */
export interface ToggleProps extends BaseProps {
  checked?: boolean;
  defaultChecked?: boolean;
  onChange?: (checked: boolean) => void;
  disabled?: boolean;
  /** Required when the row's title is not the accessible name. */
  label?: string;
}

/** An AppButton an EmptyState builds for you. */
export interface EmptyStateAction {
  label: string;
  onClick?: () => void;
  href?: string;
  icon?: IconName;
  /** Overrides the default role: 'pro' for an upgrade, 'secondary' to soften. */
  variant?: Variant;
}

/** Nothing here yet. No artwork — the system defines none. */
export interface EmptyStateProps extends BaseProps {
  /** The heading element for the title, so a nested block does not skip a level. @default 'h2' */
  titleAs?: string;
  /** screen = the whole view has nothing (serif-md, solid action) · card = a block on a screen that has other content ·
   *  plain = inside a Card or sheet that already draws the surface · row = one line inside <Card layout="list">.
   *  @default 'card' */
  layout?: 'screen' | 'card' | 'plain' | 'row';
  /** The fact, in the household voice. 'row' shows only this. */
  title: string;
  /** One sentence saying what to do. Not used by 'row'. */
  message?: string;
  icon?: IconName;
  action?: EmptyStateAction;
  /** A second, quieter way out ("Clear filters"). Never a third. */
  secondaryAction?: EmptyStateAction;
}

/** A distribution as one bar: reaction tiers, macros, health tiers. */
export interface SegmentedBarProps extends BaseProps {
  /** Widths are each value's share of the sum. `reaction` paints the step's fill and gives the key a reaction Badge;
   *  `color` is any other token and gives it a dot. */
  segments: { label: string; value: number; reaction?: Reaction; color?: string }[];
  /** true = Badges and dots wrapped under the bar · 'rows' = a <Card layout="list"> of ListRows, for a full breakdown. */
  legend?: boolean | 'rows';
  /** Legend figures. @default 'count' */
  format?: 'count' | 'percent';
  /** @default 'md' */
  size?: 'sm' | 'md' | 'lg';
  /** The bar's accessible name. */
  label?: string;
  /** Wraps the bar in a <Section> with this SectionHeader; `trailing` is the header's right-hand figure. */
  title?: string;
  trailing?: unknown;
}

/** Minus · value · plus. Servings, people, counts. */
export interface ValueStepperProps extends BaseProps {
  value?: number;
  defaultValue?: number;
  onChange?: (value: number) => void;
  /** @default 1 */
  min?: number;
  /** @default 99 */
  max?: number;
  /** @default 1 */
  step?: number;
  /** Appended to the numeral ("4 servings"). Only when nothing beside the stepper names the number —
   *  in a labelled row the numeral stands alone. */
  unit?: string;
  formatValue?: (value: number) => string;
  size?: 'sm' | 'md';
  label?: string;
}

/** The title block of a screen with no subject: sign-in, onboarding, paywall.
 *  A fixed composition of SectionHeader, Text and AppButton — it owns the type steps, the measure and the single h1,
 *  the way Section and SectionCard own theirs. */
export interface PageHeaderProps extends BaseProps {
  title: unknown;
  subtitle?: unknown;
  /** An uppercase eyebrow above the title (a SectionHeader). */
  eyebrow?: string;
  /** AppButtons the header builds: the first solid, the rest ghost. Full width when centred. */
  actions?: EmptyStateAction[];
  /** 'sm' drops the title to serif-md and the actions to md. @default 'md' */
  size?: 'sm' | 'md';
  align?: 'start' | 'center';
  children?: unknown;
}

/** One glyph. `label` gives it a name; without one it is decorative and hidden. */
export interface IconProps extends BaseProps {
  name: IconName;
  label?: string;
}

/** A Card for sheet content: serif title, provenance line, then children. */
export interface SheetCardProps extends BaseProps {
  title?: string;
  titleAs?: string;
  provenance?: string;
  children?: unknown;
}

/** One reason inside a sheet: a title, a detail line, an optional weight. */
export interface ReasonProps extends BaseProps {
  title: string;
  detail?: string;
  weight?: number;
}

/** A photo tile with a scrim label: a category, a cuisine, a cover. */
export interface LabeledPhotoCardProps extends BaseProps {
  label: string;
  meta?: string;
  photo?: string;
  size?: 'sm' | 'md' | 'lg';
  format?: 'square' | 'portrait' | 'landscape';
  /** A button gets aria-pressed; a link gets aria-current. */
  selected?: boolean;
  onClick?: () => void;
  href?: string;
}

/** A section header over a horizontal row of RecipeCards. */
export interface RecipeShelfProps extends BaseProps {
  title?: string;
  trailing?: unknown;
  recipes?: RecipeCardProps[];
  /** Shown instead of the row when `recipes` is empty. */
  emptyState?: EmptyStateProps;
}

/** A dinner party at a glance. 'mine' shows its score; 'discover' offers the join action. */
export interface PartyCardProps extends BaseProps {
  name: string;
  titleAs?: string;
  mode?: 'mine' | 'discover';
  avatar?: AvatarProps;
  score?: number | null;
  memberCount?: number;
  meta?: string;
  summary?: string;
  /** Rendered as a Timeline size 'mini': a square thumbnail and its date per meal, newest first. */
  recentMeals?: { src?: string; alt?: string; date?: string; current?: boolean; href?: string }[];
  onClick?: () => void;
  href?: string;
  /** 'discover' only: renders "Ask to join" as a sibling of the card's pressable region. */
  onJoin?: () => void;
}
