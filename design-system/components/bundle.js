/* @ds-bundle: {"format":4,"namespace":"NomNom","components":[{"name":"Text"},{"name":"Card"},{"name":"AppButton"},{"name":"Badge"},{"name":"Input"},{"name":"TextArea"},{"name":"TasteScoreSelector"},{"name":"SectionHeader"},{"name":"Section"},{"name":"SectionCard"},{"name":"Avatar"},{"name":"ScoreValue"},{"name":"Bar"},{"name":"PhotoCard"},{"name":"RecipeCard"},{"name":"PhotoStrip"},{"name":"RecipeLinkCard"},{"name":"ScoreCard"},{"name":"RatingList"},{"name":"Timeline"},{"name":"BottomSheet"},{"name":"ListRow"},{"name":"Toggle"},{"name":"EmptyState"},{"name":"Skeleton"},{"name":"SegmentedBar"},{"name":"ValueStepper"},{"name":"ScreenHeader"},{"name":"Facts"},{"name":"LabeledPhotoCard"},{"name":"RecipeShelf"},{"name":"PartyCard"},{"name":"ProMark"},{"name":"ProCard"},{"name":"ProView"},{"name":"ProGate"},{"name":"ProLinkCard"},{"name":"CollectionSection"},{"name":"AddRow"},{"name":"BarButton"},{"name":"BarAction"},{"name":"TagToggle"},{"name":"ChoiceTile"},{"name":"NoteField"},{"name":"NoteEditor"},{"name":"PersonHeaderRow"},{"name":"PageMenu"},{"name":"TrendChart"},{"name":"MediaViewer"},{"name":"FieldGroup"},{"name":"ToggleCard"},{"name":"AccountActions"},{"name":"CodeField"},{"name":"PackageCard"},{"name":"StepList"},{"name":"CheckRow"},{"name":"IngredientList"},{"name":"SelectRow"},{"name":"BrandMark"},{"name":"SwipeRow"},{"name":"EditorialText"},{"name":"ScannerOverlay"},{"name":"UnitToggle"},{"name":"DismissibleNotice"},{"name":"Reorder"},{"name":"ReorderTarget"}]} */
(function () {
  'use strict';
  var React = window.React;
  var h = React.createElement;
  var useState = React.useState;

  // ---------- helpers
  function cx() {
    var out = [];
    for (var i = 0; i < arguments.length; i++) if (arguments[i]) out.push(arguments[i]);
    return out.join(' ');
  }
  var warned = {};
  /** A renamed prop keeps working for one major, loudly. */
  function legacy(p, from, to, where) {
    if (p[from] === undefined || p[to] !== undefined) return p;
    if (!warned[where + from]) {
      warned[where + from] = 1;
      if (typeof console !== 'undefined' && console.warn) console.warn('NomNom: ' + where + '.' + from + ' is renamed to ' + to + '; the old name goes away in the next major.');
    }
    var q = Object.assign({}, p); q[to] = p[from]; delete q[from]; return q;
  }
  function omit(obj, keys) {
    var o = {};
    for (var k in obj) if (Object.prototype.hasOwnProperty.call(obj, k) && keys.indexOf(k) < 0) o[k] = obj[k];
    return o;
  }
  var REACTIONS = [
    { key: 'inedible', value: -1, label: '\u22121', name: "Can't eat" },
    { key: 'bad', value: 1, label: '1', name: 'Bad' },
    { key: 'meh', value: 2, label: '2', name: 'Meh' },
    { key: 'good', value: 3, label: '3', name: 'Good' },
    { key: 'great', value: 4, label: '4', name: 'Great' },
    { key: 'amazing', value: 5, label: '5', name: 'Amazing' }
  ];
  /** 0–100 score → reaction key, the ScoreBadge thresholds from the app. */
  function reactionForScore(score) {
    if (score >= 85) return 'amazing';
    if (score >= 70) return 'great';
    if (score >= 50) return 'good';
    if (score >= 30) return 'meh';
    if (score >= 15) return 'bad';
    return 'inedible';
  }
  function verdictForScore(score) {
    var k = reactionForScore(score);
    for (var i = 0; i < REACTIONS.length; i++) if (REACTIONS[i].key === k) return REACTIONS[i].name;
    return '';
  }
  function useControlled(value, defaultValue, onChange) {
    var st = useState(defaultValue === undefined ? null : defaultValue);
    var controlled = value !== undefined;
    return [controlled ? value : st[0], function (next) { if (!controlled) st[1](next); if (onChange) onChange(next); }];
  }
  function minus(n) { return n < 0 ? '−' + Math.abs(n) : n > 0 ? '+' + n : '±0'; }

  // ---------- Icon
  /** A single-ink glyph from bundle.css (`nn-i-<name>`); decorative unless given a label. */
  function Icon(props) {
    return h('i', { className: cx('nn-icon', 'nn-i-' + props.name, props.className), 'aria-hidden': props.label ? undefined : true, 'aria-label': props.label, role: props.label ? 'img' : undefined });
  }

  // ---------- Text: every piece of copy is set on the type scale through this one component
  var TEXT_STYLES = ['serif-xs', 'serif-sm', 'serif-md', 'serif-lg', 'serif-xl', 'sans-xs', 'sans-sm', 'sans-md', 'sans-lg', 'sans-xl'];
  /** textStyle: a type-scale step · tone: primary | secondary | tertiary | accent · weight · italic · numeric · lines (clamp). */
  function Text(props) {
    var p = props;
    var rest = omit(p, ['as', 'textStyle', 'tone', 'weight', 'italic', 'numeric', 'lines', 'align', 'className', 'children', 'style']);
    return h(p.as || 'span', Object.assign({
      className: cx('nn-text', p.className),
      'data-style': TEXT_STYLES.indexOf(p.textStyle) >= 0 ? p.textStyle : 'sans-md',
      'data-tone': p.tone && p.tone !== 'primary' ? p.tone : undefined,
      'data-weight': p.weight === 'semibold' ? 'semibold' : p.weight === 'normal' ? 'normal' : undefined,
      'data-italic': p.italic ? '' : undefined,
      'data-numeric': p.numeric ? '' : undefined,
      'data-align': p.align,
      style: p.lines ? Object.assign({ '--nn-lines': p.lines }, p.style) : p.style,
      'data-lines': p.lines ? '' : undefined
    }, rest), p.children);
  }

  // ---------- Card: the one surface (panel, radius-3xl); pressable cards get a trailing chevron
  /** size md (spacing-5) | sm (spacing-4) · layout block | list (rows with hairlines) · variant primary (featured tint) · onClick / href. */
  function Card(props) {
    var p = props;
    var pressable = !!(p.onClick || p.href);
    // A card holds flow content, so it is never itself a <button>: an onClick card is a <div> with a
    // stretched hit button over it. A link card stays an <a>, which may contain flow content.
    var tag = p.href ? 'a' : (p.as || 'div');
    var rest = omit(p, ['as', 'size', 'layout', 'variant', 'className', 'children', 'chevron', 'onClick', 'aria-label']);
    var hit = (!p.href && p.onClick) ? h('button', { key: 'hit', type: 'button', className: 'nn-card__hit', onClick: p.onClick, 'aria-label': p['aria-label'] }) : null;
    return h(tag, Object.assign({
      className: cx('nn-card', p.className),
      href: p.href,
      'aria-label': p.href ? p['aria-label'] : undefined,
      'data-size': p.size === 'sm' ? 'sm' : undefined,
      'data-layout': p.layout === 'list' ? 'list' : undefined,
      'data-variant': p.variant === 'primary' ? 'primary' : undefined,
      'data-pressable': pressable ? '' : undefined
    }, rest), hit, pressable && p.chevron !== false ? [h('span', { key: 'b', className: 'nn-card__body' }, p.children), h(Icon, { key: 'c', name: 'chevron-right', className: 'nn-card__chevron' })] : p.children);
  }

  function AppButton(props) {
    // An icon-only button with no string name renders unnamed; fail loudly in development.

    var p = props;
    var label = p.label !== undefined ? p.label : p.children;
    var rest = omit(p, ['variant', 'reaction', 'appearance', 'size', 'icon', 'iconPosition', 'iconOnly', 'fullWidth', 'loading', 'label', 'children', 'className', 'type', 'disabled', 'onClick']);
    var icon = p.loading ? h('span', { className: 'nn-spinner', 'aria-hidden': true }) : (p.icon ? h(Icon, { name: p.icon }) : null);
    return h('button', Object.assign({
      type: p.type || 'button',
      className: cx('nn-button', p.className),
      'data-variant': p.variant || 'primary',
      'data-reaction': p.variant === 'reaction' ? (p.reaction || 'good') : undefined,
      'data-appearance': p.appearance || 'solid',
      'data-size': p.size || 'md',
      'data-icon-position': (p.iconPosition === 'trailing' || p.iconPosition === 'end') ? 'trailing' : undefined,
      'data-icon-only': p.iconOnly ? '' : undefined,
      'data-full-width': p.fullWidth ? '' : undefined,
      'aria-busy': p.loading ? 'true' : undefined,
      'aria-disabled': p.loading ? 'true' : undefined,
      'aria-label': p.iconOnly ? (typeof label === 'string' ? label : p['aria-label']) : p['aria-label'],
      // A pending button keeps focus: disabling it mid-action drops focus to <body>.
      disabled: p.disabled,
      onClick: p.loading ? undefined : p.onClick
    }, rest), icon, p.iconOnly ? null : label);
  }

  // ---------- Badge
  var BADGE_APPEARANCES = ['soft', 'solid', 'elevated'];
  function Badge(props) {
    var p = props;
    var label = p.label !== undefined ? p.label : p.children;
    var variant = p.variant || 'primary';
    return h('span', {
      className: cx('nn-badge', p.className),
      'data-variant': variant,
      'data-reaction': variant === 'reaction' ? (p.reaction || 'good') : undefined,
      'data-appearance': BADGE_APPEARANCES.indexOf(p.appearance) >= 0 ? p.appearance : 'soft',
      'data-size': p.size === 'sm' ? 'sm' : 'md',
      'data-icon-position': (p.iconPosition === 'trailing' || p.iconPosition === 'end') ? 'trailing' : undefined,
      title: p.title
    }, p.icon ? h(Icon, { name: p.icon }) : null, label);
  }

  // ---------- Input / TextArea
  var FIELD_OWN = ['value', 'defaultValue', 'onChange', 'label', 'leadingIcon', 'trailingIcon',
    'appearance', 'clearable', 'hint', 'error', 'className', 'rows', 'maxLength', 'id'];
  function fieldClass(p, extra) {
    return cx('nn-field', extra);
  }
  /** Data attributes carry the axes; the states are read off the control itself in CSS
   *  (`:has([aria-invalid])`, `:has(:disabled)`), so there is one source of truth for each. */
  function fieldAttrs(p, extra) {
    return { className: fieldClass(p, extra),
      'data-appearance': p.appearance === 'plain' ? 'plain' : undefined,
      'data-labeled': p.label ? '' : undefined };
  }
  /** The label is associated by id, so it wraps nothing: a clear button inside a <label> would
   *  otherwise join the field's accessible name ("Email Clear text"). Hint and error sit outside
   *  too and are linked with aria-describedby. */
  function fieldBlock(p, field, describedBy, msg) {
    return h('div', { className: cx('nn-field-block', p.className) },
      field,
      msg ? h(Text, { className: 'nn-field__msg', as: 'span', id: describedBy, role: p.error ? 'alert' : undefined, textStyle: 'sans-xs', tone: p.error ? undefined : 'secondary' },
        p.error ? h(Icon, { name: 'alert' }) : null, msg) : null);
  }
  function fieldLabel(p, id) {
    return h(Text, { as: 'label', htmlFor: id, className: 'nn-field__label', textStyle: 'sans-xs', tone: 'secondary' }, p.label);
  }
  function Input(props) {
    var p = props;
    var st = useState(p.defaultValue || '');
    var value = p.value !== undefined ? p.value : st[0];
    var msg = typeof p.error === 'string' ? p.error : p.hint;
    var autoId = useId('nn-field');
    var id = p.id || autoId;
    var msgId = id + '-msg';
    function set(v) { if (p.value === undefined) st[1](v); if (p.onChange) p.onChange(v); }
    // Everything the consumer did not name as ours goes to the control: id, name, type,
    // autoComplete, inputMode, required, onBlur, pattern, min, max…
    var input = h('input', Object.assign({}, omit(p, FIELD_OWN), {
      id: id, value: value, placeholder: p.placeholder,
      'aria-invalid': p.error ? 'true' : undefined,
      'aria-describedby': msg ? msgId : p['aria-describedby'],
      onChange: function (e) { set(e.target.value); } }));
    return fieldBlock(p, h('span', fieldAttrs(p),
      p.leadingIcon ? h(Icon, { name: p.leadingIcon }) : null,
      p.label ? h('span', { className: 'nn-field__stack' }, fieldLabel(p, id), input) : input,
      p.clearable && value && !p.disabled && !p.readOnly ? h(AppButton, { className: 'nn-field__clear', variant: 'secondary', appearance: 'ghost', size: 'sm', iconOnly: true, icon: 'x-circle', label: 'Clear text', onClick: function (e) { e.preventDefault(); set(''); } }) : null,
      p.trailingIcon ? h(Icon, { name: p.trailingIcon }) : null), msgId, msg);
  }
  function TextArea(props) {
    var p = props;
    var st = useState(p.defaultValue || '');
    var value = p.value !== undefined ? p.value : st[0];
    var over = p.maxLength ? value.length > p.maxLength : false;
    var msg = typeof p.error === 'string' ? p.error : p.hint;
    var autoId = useId('nn-field');
    var id = p.id || autoId;
    var msgId = id + '-msg';
    var countId = id + '-count';
    var describedBy = [msg ? msgId : null, p.maxLength ? countId : null].filter(Boolean).join(' ') || p['aria-describedby'];
    var area = h('textarea', Object.assign({}, omit(p, FIELD_OWN), {
      id: id, rows: p.rows || 3, value: value, placeholder: p.placeholder,
      'aria-invalid': p.error || over ? 'true' : undefined, 'aria-describedby': describedBy,
      onChange: function (e) { if (p.value === undefined) st[1](e.target.value); if (p.onChange) p.onChange(e.target.value); } }));
    var field = h('span', fieldAttrs(over ? Object.assign({}, p, { error: true }) : p, 'nn-textarea'),
      p.label ? h('span', { className: 'nn-field__stack' }, fieldLabel(p, id), area) : area);
    if (!p.maxLength) return fieldBlock(p, field, msgId, msg);
    return h('div', { className: cx('nn-field-block', p.className) }, field,
      h('span', { className: 'nn-field__footer' },
        h(Text, { className: 'nn-field__msg', as: 'span', id: msgId, role: p.error ? 'alert' : undefined, textStyle: 'sans-xs', tone: p.error ? undefined : 'secondary' },
          p.error ? h(Icon, { name: 'alert' }) : null, msg || ''),
        h(Text, { className: 'nn-field__count', as: 'span', id: countId, textStyle: 'sans-xs', numeric: true, tone: over ? undefined : 'tertiary', 'data-over': over ? '' : undefined },
          value.length + ' / ' + p.maxLength)));
  }

  // ---------- Rating controls
  function TasteScoreSelector(props) {
    var p = legacy(props, 'label', 'aria-label', 'TasteScoreSelector');
    var s = useControlled(p.value, p.defaultValue, p.onChange);
    var sel = null;
    for (var i = 0; i < REACTIONS.length; i++) if (REACTIONS[i].key === s[0]) sel = REACTIONS[i];
    return h('div', { className: 'nn-taste' },
      // Toggle buttons, not radios: a radio cannot be unchecked by clicking it, and this scale can —
      // tapping the chosen step clears the rating. role=group + aria-pressed says exactly that, and
      // keeps six ordinary Tab stops instead of a roving-tabindex radiogroup.
      h('div', { className: 'nn-taste__row', role: 'group', 'aria-label': p['aria-label'] || 'Taste' }, REACTIONS.map(function (r) {
        var on = s[0] === r.key;
        return h(AppButton, { key: r.key, 'aria-pressed': on ? 'true' : 'false', 'aria-label': r.label + ': ' + r.name, size: 'lg',
          variant: on ? 'reaction' : 'secondary', reaction: r.key, appearance: on ? 'soft' : 'elevated', disabled: p.disabled,
          onClick: function () { s[1](on ? null : r.key); } }, r.label);
      })),
      p.showVerdict === false ? null : h(Text, { as: 'div', align: 'center', textStyle: 'sans-sm', tone: sel ? 'primary' : 'tertiary' }, sel ? sel.name : 'Not rated yet'));
  }

  // ---------- Layout
  /** The one small label, everywhere: title, optional icon, optional trailing figure.
   *  It draws no surface and reserves no space around itself — the parent does both. */
  function SectionHeader(props) {
    var p = legacy(props, 'trailingVariant', 'trailingTone', 'SectionHeader');
    var Tag = p.as || 'h2';
    // count: the figure that follows the title ("MEAL HISTORY 31"). action: the ONE verb a section offers on its right
    // ({ label, onClick | href, 'aria-label' }): "Add", "New", "See all". Pass it only when the viewer can act; empty, hand it to EmptyState.
    var act = p.action;
    var actNode = act ? h(AppButton, { className: 'nn-section-header__action', variant: 'primary', appearance: 'soft', size: 'sm',
      onClick: act.onClick, 'aria-label': act['aria-label'], disabled: act.disabled }, act.label) : null;
    return h('div', { className: cx('nn-section-header', p.className), 'data-case': p.uppercase === false ? 'normal' : undefined, 'data-variant': p.variant === 'primary' ? 'primary' : undefined, 'data-action': act ? '' : undefined },
      h('span', { className: 'nn-section-header__lead' },
        h(Text, { className: 'nn-section-header__title', as: Tag, textStyle: 'sans-xs', tone: 'tertiary' },
          p.icon ? h(Icon, { name: p.icon }) : null, p.title),
        p.count !== undefined && p.count !== null ? h(Text, { className: 'nn-section-header__count', as: 'span', textStyle: 'sans-xs', tone: 'tertiary', numeric: true }, p.count) : null),
      p.trailing ? h(Text, { className: 'nn-section-header__trailing', as: 'span', textStyle: 'sans-xs', tone: p.trailingTone === 'accent' || p.trailingTone === 'primary' ? 'accent' : 'tertiary', numeric: true }, p.trailing) : null,
      actNode);
  }
  /** A SectionHeader over any content: the one way a screen section starts. */
  /** A SectionHeader over any content. The Section owns the label's side inset and the gap below it. */
  function Section(props) {
    var p = props;
    return h('section', { className: cx('nn-section', p.className) },
      p.title ? h(SectionHeader, { className: 'nn-section__head', title: p.title, count: p.count, action: p.action, trailing: p.trailing, trailingVariant: p.trailingVariant, uppercase: p.uppercase, icon: p.icon }) : null,
      p.children);
  }
  /** A Card whose label sits inside it: Card + SectionHeader + optional quote. One shape.
   *  A label *above* a card is Section + Card — this component does not do that. */
  function SectionCard(props) {
    var p = props;
    return h(Card, { variant: p.variant, className: cx('nn-section-card', p.className), as: 'section', onClick: p.onClick },
      p.title ? h(SectionHeader, { as: 'span',  title: p.title, trailing: p.trailing, trailingVariant: p.trailingVariant, uppercase: p.uppercase, icon: p.icon, variant: p.variant }) : null,
      p.quote ? h(Text, { as: 'p', textStyle: 'serif-xs', italic: true }, p.quote) : null,
      p.children);
  }

  // ---------- People
  function initials(name) {
    var parts = String(name || '').trim().split(/\s+/).filter(Boolean);
    if (!parts.length) return '?';
    if (parts.length > 1) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    return parts[0][0].toUpperCase();
  }
  var AVATAR_SIZES = ['xs', 'sm', 'md', 'lg', 'xl'];
  /** A circle with a photo, else text (initials from `name` by default). */
  function Avatar(props) {
    var p = props;
    // An empty name is a bare primary-soft circle, not "?" (onboarding before the name is typed).
    var text = p.text || (p.name === '' ? '' : initials(p.name));
    var circle = h('span', { className: cx('nn-avatar', p.onEdit ? null : p.className), 'data-size': AVATAR_SIZES.indexOf(p.size) >= 0 ? p.size : 'md',
      'data-chars': p.photo ? undefined : String(text.length),
      role: p.decorative || p.onEdit ? undefined : 'img', 'aria-label': p.decorative || p.onEdit ? undefined : p.name,
      'aria-hidden': p.decorative || p.onEdit ? 'true' : undefined },
      p.photo ? h('img', { src: p.photo, alt: '' }) : text);
    if (!p.onEdit) return circle;
    // Edit mode (xl): the whole avatar is the button; the camera badge is visual only.
    return h('button', { type: 'button', className: cx('nn-avatar-edit', p.className), onClick: p.onEdit, 'aria-label': p.editLabel || ('Change photo for ' + (p.name || 'you')) },
      circle, h('span', { className: 'nn-avatar-edit__badge', 'aria-hidden': true }, h(Icon, { name: 'camera' })));
  }

  // ---------- Content
  var PHOTO_SIZES = ['xs', 'sm', 'md', 'lg'];
  var PHOTO_FORMATS = ['square', 'portrait', 'landscape'];
  var PHOTO_FORMAT_DEFAULT = { xs: 'square', sm: 'portrait', md: 'square', lg: 'portrait' };
  /** The one photo tile: a rounded photo (or the no-photo tile), optional favourite heart and verdict Badge.
   *  `size` is the tile's long edge; `format` square | portrait | landscape is its shape (3:4 either way). */
  function PhotoCard(props) {
    var p = props;
    var size = PHOTO_SIZES.indexOf(p.size) >= 0 ? p.size : 'md';
    var format = PHOTO_FORMATS.indexOf(p.format) >= 0 ? p.format : PHOTO_FORMAT_DEFAULT[size];
    var rated = p.score !== undefined && p.score !== null;
    var badge = p.badge || (rated && size !== 'xs' ? { variant: 'reaction', reaction: reactionForScore(p.score), label: p.verdict || verdictForScore(p.score), title: p.score + ' out of 100' } : null);
    return h('div', { className: cx('nn-photo-card', p.className), 'data-size': size, 'data-format': format, 'data-selected': p.selected ? '' : undefined },
      p.src ? h('img', { src: p.src, alt: p.alt || '' })
        : h('span', { className: 'nn-photo-card__none' }, h(Icon, { name: 'utensils' }), size !== 'xs' ? h(Text, { textStyle: 'sans-xs', tone: 'tertiary' }, 'No photo yet') : null),
      p.onToggleFavorite
        ? h(AppButton, { className: 'nn-photo-card__fav', variant: 'secondary', appearance: 'elevated', iconOnly: true,
            icon: p.favorite ? 'heart' : 'heart-outline',
            label: p.favorite ? 'Remove from favourites' : 'Add to favourites',
            onClick: p.onToggleFavorite, 'aria-pressed': p.favorite ? 'true' : 'false' })
        // No handler: a marker, not a control — a focusable button that does nothing is worse than none.
        : p.favorite ? h('span', { className: 'nn-photo-card__fav', 'data-marker': '' }, h(Icon, { name: 'heart', label: 'Favourite' })) : null,
      p.children,
      badge ? h(Badge, Object.assign({ className: 'nn-photo-card__badge', appearance: 'elevated', size: 'sm' }, badge)) : null);
  }
  function RecipeCard(props) {
    var p = props;
    return h('article', { className: 'nn-recipe-card' },
      h(PhotoCard, { src: p.photo, alt: p.alt, size: 'md', score: p.score, verdict: p.verdict, favorite: p.favorite }),
      h('div', { className: 'nn-recipe-card__meta' },
        h(SectionHeader, { as: 'span',  title: p.category || 'Recipe', trailing: p.by ? 'by ' + p.by : null }),
        h(Text, { as: 'div', textStyle: 'sans-sm', weight: 'semibold', lines: 2 }, p.title)));
  }
  /** `format` is PhotoCard's: square | portrait (default) | landscape. The whole strip shares one — it never mixes formats. */
  function PhotoStrip(props) {
    var p = props;
    var photos = p.photos || [];
    var format = PHOTO_FORMATS.indexOf(p.format) >= 0 ? p.format : 'portrait';
    var canAdd = !!p.onAddPhoto;
    if (p.editing) {
      // Edit mode: PhotoCard `sm` tiles, Remove on each, a Cover / Page badge, Camera + Library to add. Reorder is by menu, never drag.
      return h(Section, { title: p.title || 'Photos', trailing: p.trailing === undefined ? 'Optional' : p.trailing, className: 'nn-photo-strip-editor' },
        photos.length ? h('div', { className: 'nn-photo-strip-editor__track nn-scroller' }, photos.map(function (ph, i) {
          var badge = i === 0 && !p.pages ? 'Cover' : (p.pages ? 'Page ' + (i + 1) : null);
          return h('div', { key: i, className: 'nn-photo-strip-editor__tile' },
            h(PhotoCard, { src: ph.src, alt: ph.alt, size: 'sm', format: format }),
            badge ? h(Badge, { className: 'nn-photo-strip-editor__badge', appearance: 'elevated', size: 'sm' }, badge) : null,
            h(AppButton, { className: 'nn-photo-strip-editor__remove', variant: 'secondary', appearance: 'elevated', iconOnly: true, icon: 'x', label: 'Remove photo ' + (i + 1), onClick: function () { if (p.onRemove) p.onRemove(i); } }));
        })) : null,
        h('div', { className: 'nn-photo-strip-editor__actions' },
          h(AppButton, { variant: 'secondary', appearance: 'soft', size: 'sm', icon: 'camera', onClick: p.onAddPhoto }, 'Camera'),
          h(AppButton, { variant: 'secondary', appearance: 'soft', size: 'sm', onClick: p.onPickLibrary || p.onAddPhoto }, 'Library')));
    }
    if (!photos.length && !canAdd) {
      return h('div', { className: 'nn-photo-strip', 'data-format': format }, h(PhotoCard, { size: 'lg', format: format }));
    }
    // The add tile is the strip's last tile, the same size as a photo: adding is part of the set, not an overlay.
    var add = canAdd ? h('button', { key: 'add', type: 'button', className: 'nn-photo-strip__add-tile', 'data-format': format, onClick: p.onAddPhoto },
      h(Icon, { name: 'camera' }),
      h(Text, { textStyle: 'sans-sm', weight: 'semibold' }, photos.length ? 'Add photo' : (p.emptyTitle || 'Add a photo')),
      h(Text, { textStyle: 'sans-sm', tone: 'tertiary' }, 'Camera or library')) : null;
    return h('div', { className: 'nn-photo-strip', 'data-format': format },
      h('div', { className: 'nn-photo-strip__track nn-scroller' },
        photos.map(function (ph, i) { return h(PhotoCard, Object.assign({ key: i, size: 'lg', format: format }, ph)); }),
        add));
  }
  /** Thumb is a PhotoCard `xs`; `format` is PhotoCard's, portrait by default. */
  function RecipeLinkCard(props) {
    var p = legacy(props, 'name', 'title', 'RecipeLinkCard');
    return h(Card, { size: 'sm', href: p.href, onClick: p.onClick, className: 'nn-recipe-link' },
      h(PhotoCard, { src: p.photo, alt: p.alt, size: 'xs', format: p.format || 'portrait' }),
      h('span', { className: 'nn-recipe-link__body' },
        h(SectionHeader, { as: 'span',  title: p.eyebrow || 'Recipe' }),
        h(Text, { textStyle: 'serif-sm' }, p.title),
        h(Text, { textStyle: 'sans-sm', tone: 'tertiary' }, (p.meta || []).join(' · '))));
  }

  // ---------- Ratings
  var BAR_SIZES = ['xs', 'sm', 'md', 'lg', 'xl'];
  function barFill(s) { return s.reaction ? 'var(--reaction-' + s.reaction + '-fill)' : (s.color || 'var(--primary)'); }
  /** The one bar. One fill (`value` / `max`) or several (`segments`); `size` xs…xl is its thickness. */
  function Bar(props) {
    var p = legacy(props, 'label', 'aria-label', 'Bar');
    var size = BAR_SIZES.indexOf(p.size) >= 0 ? p.size : 'md';
    if (!p.segments) {
      var none = p.value === undefined || p.value === null;
      var max = p.max || 100;
      return h('div', {
        className: cx('nn-bar', p.className), 'data-size': size, role: none ? 'img' : 'meter',
        'aria-valuemin': 0, 'aria-valuemax': max, 'aria-valuenow': none ? undefined : p.value,
        'aria-label': p['aria-label'] || (none ? 'Not rated yet' : p.value + ' out of ' + max)
      }, none ? null : h('span', { className: 'nn-bar__seg', style: { width: (Math.max(0, Math.min(1, p.value / max)) * 100) + '%' } }));
    }
    var segs = p.segments;
    var total = p.max || 0;
    if (!p.max) for (var i = 0; i < segs.length; i++) total += segs[i].value || 0;
    return h('div', { className: cx('nn-bar', p.className), 'data-size': size, role: 'img',
      'aria-label': p['aria-label'] || segs.filter(function (x) { return x.label; }).map(function (x) { return x.label + ' ' + x.value; }).join(', ') },
      total === 0 ? null : segs.map(function (s, i) {
        return s.value > 0 ? h('span', { key: i, className: 'nn-bar__seg', style: { width: (s.value / total * 100) + '%', background: barFill(s) }, title: s.label ? s.label + ' ' + s.value : undefined }) : null;
      }));
  }
  var SCORE_STYLES = { xs: ['serif-xs', null], sm: ['serif-sm', 'serif-sm'], md: ['serif-md', 'serif-sm'], lg: ['serif-xl', 'serif-sm'] };
  /** The score numeral (primary-text, tabular) and its verdict word, baseline-aligned. null = "—" Unrated. */
  function ScoreValue(props) {
    var p = props;
    var size = SCORE_STYLES[p.size] ? p.size : 'lg';
    var rated = p.score !== undefined && p.score !== null;
    var st = SCORE_STYLES[size];
    var showVerdict = p.showVerdict !== undefined ? p.showVerdict : !!st[1];
    // ink: accent (default) \u00b7 reaction (a sheet hero: the verdict's own text colour) \u00b7 pro (a Pro score)
    var inkColor = !rated ? undefined : p.ink === 'pro' ? 'var(--pro-text)' : p.ink === 'reaction' ? 'var(--reaction-' + reactionForScore(p.score) + '-text)' : undefined;
    return h('span', { className: cx('nn-score', p.className), 'data-size': size, 'data-ink': p.ink || undefined },
      h(Text, { textStyle: st[0], tone: rated ? 'accent' : 'tertiary', numeric: true, style: inkColor ? { color: inkColor } : undefined }, rated ? p.score : '\u2014'),
      showVerdict ? h(Text, { textStyle: st[1] || 'serif-sm', tone: rated ? 'primary' : 'tertiary' }, p.verdict || (rated ? verdictForScore(p.score) : 'Not rated yet')) : null);
  }
  /** A signed change as a Badge: primary up, warning down, secondary flat. */
  function deltaBadge(n, size, key) {
    if (n === 0) return h(Text, { key: key, textStyle: 'sans-sm', tone: 'tertiary', numeric: true }, '\u00b10');
    return h(Badge, { key: key, variant: n < 0 ? 'warning' : n > 0 ? 'primary' : 'secondary', size: size || 'md' }, minus(n));
  }
  /** One score readout in two layouts: 'hero' (the meal screen) and 'compact' (household, health and per-person scores). */
  function ScoreCard(props) {
    var p = props;
    var layout = p.layout === 'compact' ? 'compact' : 'hero';
    var rated = p.score !== undefined && p.score !== null;
    var hasDelta = p.delta !== undefined && p.delta !== null;
    var isPro = p.variant === 'pro';
    if (!rated && p.onRemind !== undefined || (!rated && p.unratedText)) {
      // Unrated: not pressable, no empty bar. "No score yet" + who is missing + (optionally) a Remind button.
      return h(Card, { className: 'nn-score-card', 'data-layout': layout, 'data-unrated': '' },
        p.title ? h(SectionHeader, { as: 'span', title: p.title }) : null,
        h('span', { className: 'nn-score-card__unrated' },
          h('span', { className: 'nn-score-card__unrated-text' },
            h(Text, { textStyle: 'serif-sm' }, 'No score yet'),
            p.unratedText ? h(Text, { textStyle: 'sans-sm', tone: 'secondary' }, p.unratedText) : null),
          p.onRemind ? h(AppButton, { variant: 'secondary', appearance: 'soft', size: 'sm', onClick: p.onRemind }, 'Remind') : null));
    }
    if (isPro) {
      // A Pro score: ProCard's ground, ProMark, a pro numeral and Bar. Without Pro: the score only and one Unlock button.
      var pressablePro = !p.locked && !!p.onClick;
      return h('section', { className: cx('nn-pro-card', 'nn-score-card', p.className), 'data-layout': layout, 'data-score': '', 'data-pressable': pressablePro ? '' : undefined },
        pressablePro ? h('button', { type: 'button', className: 'nn-card__hit', onClick: p.onClick, 'aria-label': p.title || 'Pro score' }) : null,
        h('span', { className: 'nn-score-card__pro-head' }, h(ProMark, null), pressablePro ? h(Icon, { name: 'chevron-right', className: 'nn-pro-card__chevron' }) : null),
        p.title ? h(Text, { as: 'h3', textStyle: 'serif-sm' }, p.title) : null,
        h(ScoreValue, { score: p.score, verdict: p.verdict, size: 'md', ink: 'pro' }),
        p.locked ? null : h(Bar, { segments: [{ value: p.score || 0, color: 'var(--pro)' }], max: 100, size: 'lg' }),
        p.caption ? h(Text, { textStyle: 'sans-sm', tone: 'secondary' }, p.caption) : null,
        p.locked ? h(AppButton, { variant: 'pro', size: 'lg', icon: 'sparkles', fullWidth: true, onClick: p.onUnlock }, 'Unlock with Pro') : null);
    }
    var barNode = p.barSegments
      ? h(Bar, { size: 'md', max: 100, 'aria-label': (p.score || 0) + ' out of 100', segments: p.barSegments.map(function (s, i) {
          return { value: s.value, label: s.label, color: 'var(--chart-series' + (i % 7 + 1) + ')' }; }) })
      : null;
    var valueSize = layout === 'hero' ? 'lg' : p.variant === 'primary' ? 'md' : 'sm';
    var aside = (p.count || (layout === 'compact' && hasDelta))
      ? h('span', { className: 'nn-score-card__aside' },
        p.count ? h(Text, { textStyle: 'sans-sm', tone: 'secondary', numeric: true }, p.count) : null,
        layout === 'compact' && hasDelta ? deltaBadge(p.delta, 'sm') : null) : null;
    return h(Card, { className: 'nn-score-card', size: layout === 'compact' ? 'sm' : undefined, variant: p.variant, onClick: p.onClick, 'data-layout': layout, 'data-unrated': rated ? undefined : '' },
      p.title ? h(SectionHeader, { as: 'span',  title: p.title, icon: p.icon, variant: p.variant }) : null,
      h('span', { className: 'nn-score-card__head' }, h(ScoreValue, { score: p.score, verdict: p.verdict, size: valueSize }), aside),
      layout === 'hero' && hasDelta ? h('span', { className: 'nn-score-card__delta' }, deltaBadge(p.delta, 'md'),
        h(Text, null, p.deltaText, p.deltaReference ? h(React.Fragment, null, ' ', h(Text, { tone: 'tertiary' }, p.deltaReference)) : null)) : null,
      barNode || h(Bar, { value: rated ? p.score : null, size: p.variant === 'primary' ? 'lg' : 'md' }),
      p.caption ? h(Text, { textStyle: 'sans-sm', tone: 'secondary' }, p.caption) : null);
  }
  /** The one "section + meter + list of rows" block. `raters` is the meal shape; `rows` is the general one. */
  function RatingList(props) {
    var p = props;
    var rows = p.rows;
    if (!rows) {
      // One list, never split by state: everyone who can rate, alphabetical by the name shown.
      // A rated row ends in its change and score; an unrated row ends in its action (Ask, Remind, Rate).
      rows = (p.raters || []).slice().sort(function (a, b) { return String(a.name).localeCompare(String(b.name)); }).map(function (r) {
        var pending = r.score === undefined || r.score === null;
        var v = r.vsUsual;
        var act = pending ? r.action : null;
        return {
          label: h(Text, { as: 'span', className: 'nn-rating-row__name' }, r.name,
            r.you ? h(Badge, { variant: 'secondary', size: 'sm' }, 'You') : null,
            r.role ? h(Text, { textStyle: 'sans-sm', tone: 'tertiary' }, ' \u00b7 ' + r.role) : null),
          meta: pending ? r.meta : undefined,
          note: pending ? (act ? null : h(Text, { textStyle: 'sans-sm', tone: 'tertiary' }, 'Not rated yet'))
            : v === 'new' ? h(Badge, { variant: 'secondary', size: 'sm' }, 'New')
            : v === 0 ? h(Text, { textStyle: 'sans-sm', tone: 'tertiary' }, 'As usual')
            : typeof v === 'number' ? deltaBadge(v, 'sm') : null,
          value: pending ? (act ? h(AppButton, { size: 'sm', appearance: 'soft', variant: act.variant || 'secondary', onClick: act.onClick, disabled: act.disabled }, act.label) : null)
            : h(ScoreValue, { className: 'nn-rating-row__score', score: r.score, size: 'xs' })
        };
      });
    }
    var meter = p.bar !== undefined ? p.bar
      : (p.total ? h(Bar, { size: 'xs', value: p.rated || 0, max: p.total, label: (p.rated || 0) + ' of ' + p.total + ' rated' }) : null);
    return h(Section, { className: cx('nn-rating-list', p.className), title: p.title || 'Who rated', trailing: p.trailing !== undefined ? p.trailing : (p.total ? (p.rated || 0) + ' of ' + p.total : null), trailingVariant: 'primary' },
      meter ? h('div', { className: 'nn-rating-list__meter' }, meter) : null,
      h(Card, { layout: 'list' }, rows.map(function (r, i) {
        return h(ListRow, { key: i, className: 'nn-rating-row', chevron: false,
          title: r.label, meta: r.meta,
          trailing: r.note || r.value ? h(React.Fragment, null, r.note, r.value) : undefined });
      })));
  }
  /** Every time a dish was had, as a rail of dots over PhotoCards. size 'mini': xs square thumbnails, date only, no badge, no header unless `title` is given. */
  function Timeline(props) {
    var p = props;
    var items = p.occasions || [];
    var mini = p.size === 'mini';
    var track = h('div', { className: cx('nn-timeline', mini ? null : p.className), 'data-size': mini ? 'mini' : undefined }, h('div', { className: 'nn-timeline__track nn-scroller' }, items.map(function (o, i) {
      var tile = mini
        ? h(PhotoCard, { key: 't', src: o.photo, alt: o.alt, size: 'xs', format: 'square', selected: o.current })
        : h(PhotoCard, { key: 't', src: o.photo, alt: o.alt, size: 'sm', score: o.score, verdict: o.verdict, selected: o.current });
      var label = mini ? o.date : (o.current ? 'This meal' : o.date);
      var kids = [h('span', { key: 'd', className: 'nn-timeline__dot' }), tile,
        h(Text, { key: 'l', as: 'div', textStyle: mini ? 'sans-xs' : 'sans-sm', tone: mini && !o.current ? 'tertiary' : undefined, weight: o.current ? 'semibold' : undefined, numeric: mini }, label)];
      return o.current ? h('div', { key: i, className: 'nn-timeline__item', 'data-current': '', 'aria-current': 'true' }, kids) : (o.href ? h('a', { key: i, className: 'nn-timeline__item', href: o.href }, kids) : h('div', { key: i, className: 'nn-timeline__item' }, kids));
    })));
    if (mini && !p.title) return track;
    return h(Section, { className: mini ? p.className : undefined, title: p.title || 'This recipe over time', trailing: items.length + (items.length === 1 ? ' time' : ' times') }, track);
  }

  // ---------- Overlays
  /** A modal dialog: focus moves in on open, Tab wraps inside it, Escape closes it, and focus
   *  returns to whatever opened it. Without those four a sheet is a panel that merely looks modal. */
  function BottomSheet(props) {
    var p = props;
    var sheet = React.useRef(null);
    var opener = React.useRef(null);
    var titleId = useId('nn-sheet-title');
    // kind: read (close only) · commit (close + checkmark, asks "Discard changes?" once `dirty`) · next (close + "Next") · picker · media (dark chrome, no trailing).
    var kind = p.kind || (p.onConfirm ? 'commit' : 'read');
    var askState = useState(false);
    function requestClose() { if (p.saving) return; if (p.dirty) askState[1](true); else if (p.onClose) p.onClose(); }
    React.useEffect(function () {
      opener.current = typeof document !== 'undefined' ? document.activeElement : null;
      if (sheet.current) sheet.current.focus();
      return function () { if (opener.current && opener.current.focus) opener.current.focus(); };
    }, []);
    function onKeyDown(e) {
      if (e.key === 'Escape') { e.stopPropagation(); requestClose(); return; }
      if (e.key !== 'Tab' || !sheet.current) return;
      var f = sheet.current.querySelectorAll('a[href], button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])');
      if (!f.length) return;
      var first = f[0], last = f[f.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
    var trailing = null;
    if (kind === 'commit') trailing = p.saving ? h('span', { className: 'nn-bar-button' }, h('span', { className: 'nn-spinner', 'aria-label': 'Saving' }))
      : h(BarButton, { icon: 'check', label: p.confirmLabel || 'Save', onClick: p.onConfirm, disabled: p.canConfirm === false });
    else if (kind === 'next') trailing = h(BarAction, { label: p.confirmLabel || 'Next', onClick: p.onConfirm, disabled: p.canConfirm === false });
    else if (p.action) trailing = p.action;
    var heroInk = p.heroInk || 'reaction';
    return h('div', { className: 'nn-sheet-scrim', 'data-kind': kind, style: p.style },
      h('div', { className: 'nn-sheet', ref: sheet, tabIndex: -1, role: 'dialog', 'aria-modal': 'true',
        'aria-labelledby': titleId, onKeyDown: onKeyDown, style: { flex: 1 } },
        h('div', { className: 'nn-sheet__grabber' }),
        // The bar's controls are the platform's: a white glass circle with a text-primary glyph, never an AppButton.
        h('div', { className: 'nn-sheet__bar' },
          p.back ? h(BarButton, { icon: 'chevron-left', label: 'Back', onClick: p.back }) : h(BarButton, { icon: 'x', label: 'Close', onClick: requestClose }),
          h(Text, { as: p.titleAs || 'h2', id: titleId, textStyle: 'sans-lg', weight: 'semibold', align: 'center' }, p.title),
          h('span', { className: 'nn-sheet__bar-end' }, trailing)),
        p.score !== undefined ? h('div', { className: 'nn-sheet__hero' },
          h(ScoreValue, { score: p.score, verdict: p.verdict, size: 'lg', ink: heroInk }),
          h(Bar, { segments: [{ value: p.score, reaction: heroInk === 'reaction' ? reactionForScore(p.score) : undefined, color: heroInk === 'pro' ? 'var(--pro)' : undefined }], max: 100, size: 'md' }),
          p.lead ? h(Text, { as: 'p', tone: 'secondary', className: 'nn-sheet__lead' }, p.lead) : null) : null,
        p.children,
        askState[0] ? h('div', { className: 'nn-sheet__discard', role: 'alertdialog', 'aria-label': 'Discard changes?' },
          h(Card, { className: 'nn-sheet__discard-card' },
            h(Text, { as: 'h3', textStyle: 'serif-sm' }, 'Discard changes?'),
            h(AppButton, { variant: 'destructive', appearance: 'soft', fullWidth: true, onClick: function () { askState[1](false); if (p.onClose) p.onClose(); } }, 'Discard changes'),
            h(AppButton, { variant: 'secondary', appearance: 'ghost', fullWidth: true, onClick: function () { askState[1](false); } }, 'Keep editing'))) : null));
  }
  /** A Card for sheet content: serif title, provenance line, then children (Reasons). */
  function SheetCard(props) {
    return h(Card, { className: 'nn-sheet-card' },
      props.title ? h(Text, { as: props.titleAs || 'h3', textStyle: 'serif-sm' }, props.title) : null,
      props.sub ? h(Text, { as: 'div', textStyle: 'sans-xs', tone: 'tertiary' }, props.sub) : null,
      props.children);
  }
  function Reason(props) {
    return h('div', { className: 'nn-reason' }, h(Text, { as: 'div', textStyle: 'sans-lg', weight: 'semibold' }, props.title), h(Text, { as: 'p', textStyle: 'sans-sm', tone: 'secondary' }, props.children));
  }

  // ---------- ListRow: the one row — leading slot, title + meta, trailing slot
  /** leading · title · meta · value (key–value) · trailing · chevron · unread · tone destructive. Lives in Card layout="list". */
  /** React's own id, so server and client agree. */
  function useId(prefix) { return prefix + '-' + React.useId().replace(/:/g, ''); }
  /** A pressable row never wraps its trailing controls: when `trailing` or `children` hold something
   *  interactive, the row stays a <div> and only the title region becomes the button or link. */
  function ListRow(props) {
    var p = legacy(legacy(props, 'label', 'aria-label', 'ListRow'), 'tone', 'variant', 'ListRow');
    var pressable = !!(p.onClick || p.href);
    var splitRow = pressable && (p.trailing !== undefined && p.trailing !== null);
    var rest = omit(p, ['leading', 'title', 'meta', 'metaAccent', 'metaLines', 'titleLines', 'valueSemibold', 'inactive', 'value', 'trailing', 'chevron', 'unread', 'variant', 'size', 'className', 'children', 'href', 'onClick', 'label']);
    var chevron = p.chevron !== undefined ? p.chevron : pressable;
    // titleLines / metaLines: 1 clips (default); null lets the text wrap (an ingredient name, a full-sentence reason).
    var titleLines = p.titleLines === null ? undefined : (p.titleLines || 1);
    var metaLines = p.metaLines === null ? undefined : (p.metaLines || 1);
    var metaNode = p.meta || p.metaAccent
      ? (typeof p.meta === 'string' || (!p.meta && p.metaAccent)
        ? h(Text, { as: 'span', textStyle: 'sans-sm', tone: 'secondary', lines: metaLines },
            p.meta, p.metaAccent ? h(React.Fragment, null, p.meta ? ' · ' : '', h('span', { className: 'nn-row__accent' }, p.metaAccent)) : null)
        : p.meta) : null;
    var body = h('span', { className: 'nn-row__body' },
      p.unread ? h('span', { className: 'nn-sr-only' }, 'Unread') : null,
      typeof p.title === 'string' ? h(Text, { as: 'span', weight: pressable || p.unread ? 'semibold' : 'normal', lines: titleLines }, p.title) : p.title,
      metaNode,
      p.children);
    var lead = p.leading ? h('span', { className: 'nn-row__lead' }, p.leading) : null;
    var value = p.value !== undefined ? h(Text, { className: 'nn-row__value', as: 'span', textStyle: 'sans-sm', tone: 'secondary', weight: p.valueSemibold ? 'semibold' : undefined, numeric: true }, p.value) : null;
    var trail = p.trailing ? h('span', { className: 'nn-row__trail' }, p.trailing) : null;
    var chev = chevron ? h(Icon, { name: 'chevron-right', className: 'nn-row__chevron' }) : null;
    var attrs = {
      className: cx('nn-row', p.className),
      'data-size': p.size === 'sm' ? 'sm' : undefined,
      'data-variant': p.variant === 'destructive' ? 'destructive' : undefined,
      'data-unread': p.unread ? '' : undefined,
      'data-inactive': p.inactive ? '' : undefined,
      'data-pressable': pressable && !splitRow ? '' : undefined,
      'data-split': splitRow ? '' : undefined
    };
    if (!pressable) return h('div', Object.assign({}, attrs, rest), lead, body, value, trail);
    if (!splitRow) {
      var tag = p.href ? 'a' : 'button';
      return h(tag, Object.assign({}, attrs, { type: tag === 'button' ? 'button' : undefined, href: p.href, onClick: p.onClick }, rest),
        lead, body, value, chev);
    }
    // Split: the title region is the control, the trailing slot is its sibling.
    var inner = p.href ? 'a' : 'button';
    return h('div', Object.assign({}, attrs, rest),
      h(inner, { className: 'nn-row__main', type: inner === 'button' ? 'button' : undefined, href: p.href, onClick: p.onClick, 'aria-label': p['aria-label'] },
        lead, body, value, chev),
      trail);
  }

  // ---------- Toggle: the one switch (an AppButton in switch clothing)
  /** Built on AppButton so press, focus ring and disabled come from the same place as every other control. */
  function Toggle(props) {
    var p = legacy(props, 'label', 'aria-label', 'Toggle');
    var ctl = useControlled(p.checked, p.defaultChecked || false, p.onChange);
    return h(AppButton, {
      className: cx('nn-toggle', p.className),
      variant: 'secondary', appearance: 'ghost',
      role: 'switch', 'aria-checked': ctl[0] ? 'true' : 'false', 'aria-label': p['aria-label'],
      disabled: p.disabled,
      onClick: function () { ctl[1](!ctl[0]); },
      label: h('span', { className: 'nn-toggle__knob' })
    });
  }

  // ---------- EmptyState: nothing here yet
  var EMPTY_LAYOUTS = { screen: 'screen', card: 'card', plain: 'plain', row: 'row' };
  function emptyAction(a, i, layout) {
    if (!a) return null;
    var defaults = layout === 'screen'
      ? { variant: 'primary', appearance: i ? 'ghost' : 'solid', size: 'md' }
      : { variant: 'primary', appearance: i ? 'ghost' : 'soft', size: 'sm' };
    var label = a.label !== undefined ? a.label : a.children;
    return h(AppButton, Object.assign({ key: 'a' + i }, defaults, omit(a, ['label', 'children']), { label: label }));
  }
  /** layout screen | card | plain | row · title · message · icon · action + secondaryAction. All copy through Text, all actions through AppButton. */
  function EmptyState(props) {
    var p = props;
    var layout = EMPTY_LAYOUTS[p.layout] || 'card';
    if (layout === 'row') {
      return h('div', { className: cx('nn-empty', p.className), 'data-layout': 'row' },
        p.icon ? h(Icon, { name: p.icon, className: 'nn-empty__icon' }) : null,
        h(Text, { as: 'span', textStyle: 'sans-sm', tone: 'tertiary' }, p.title),
        emptyAction(p.action, 0, layout));
    }
    var titleStyle = layout === 'screen' ? 'serif-md' : 'serif-sm';
    var body = [
      p.icon ? h(Icon, { key: 'i', name: p.icon, className: 'nn-empty__icon' }) : null,
      h(Text, { key: 't', as: p.titleAs || 'h2', textStyle: titleStyle }, p.title),
      p.message ? h(Text, { key: 'm', as: 'p', textStyle: 'sans-sm', tone: 'secondary' }, p.message) : null,
      p.action || p.secondaryAction ? h('div', { key: 'b', className: 'nn-empty__actions' },
        emptyAction(p.action, 0, layout), emptyAction(p.secondaryAction, 1, layout)) : null
    ];
    var attrs = { className: cx('nn-empty', p.className), 'data-layout': layout };
    if (layout === 'card') return h(Card, Object.assign({ as: 'div' }, attrs), body);
    return h('div', attrs, body);
  }

  // ---------- Skeleton: the shape of content that is still on its way
  var SKELETON_LAYOUTS = { list: 'list', card: 'card', text: 'text', row: 'row', screen: 'screen' };
  /** One bone: a sunken pill that shimmers. */
  function bone(shape, width, key) {
    return h('span', { key: key, className: 'nn-skeleton', 'data-shape': shape, style: width ? { width: width } : undefined });
  }
  /** A ListRow-shaped placeholder: leading, a title and meta line, trailing. */
  function skeletonRow(p, key) {
    return h('div', { key: key, className: 'nn-skeleton-row' },
      p.leading === 'avatar' ? bone('avatar', null, 'l') : p.leading === 'photo' ? bone('photo', null, 'l') : null,
      h('span', { key: 'm', className: 'nn-skeleton-row__lines' },
        bone('title', (55 + (key * 17) % 30) + '%', 't'),
        p.meta === false ? null : bone('meta', (70 + (key * 11) % 25) + '%', 'm')),
      p.trailing ? bone('trailing', null, 'r') : null);
  }
  /** Lines of body copy; the last one is shorter, as a paragraph's is. */
  function skeletonLines(n) {
    var out = [];
    for (var i = 0; i < n; i++) out.push(bone('text', i === n - 1 && n > 1 ? '60%' : null, i));
    return out;
  }
  /** layout list | card | text | row · rows · lines · leading avatar|photo · trailing · meta · caption · label. */
  function Skeleton(props) {
    var p = props;
    var layout = SKELETON_LAYOUTS[p.layout] || 'list';
    var rows = Math.max(1, p.rows || 3);
    var body;
    if (layout === 'row') body = skeletonRow(p, 0);
    else if (layout === 'screen') {
      // A screen opened by id has no header data yet: header bones over a card and a list, one block gap apart.
      body = h('div', { className: 'nn-skeleton-screen' },
        h('div', { className: 'nn-skeleton-screen__head' }, bone('screen-avatar', null, 'a'), bone('screen-title', null, 't'), bone('meta', '30%', 'd')),
        h(Card, { as: 'div' }, h('div', { className: 'nn-skeleton-text' }, bone('heading', '45%', 'h'), skeletonLines(2))),
        h(Card, { as: 'div', layout: 'list' }, [0, 1, 2].map(function (i) { return skeletonRow({ leading: 'photo', trailing: true }, i); })));
    }
    else if (layout === 'text') body = h('div', { className: 'nn-skeleton-text' }, skeletonLines(p.lines || 3));
    else if (layout === 'card') body = h(Card, { as: 'div' },
      h('div', { className: 'nn-skeleton-text' }, bone('heading', '45%', 'h'), skeletonLines(p.lines || 3)));
    else {
      var list = [];
      for (var i = 0; i < rows; i++) list.push(skeletonRow(p, i));
      body = h(Card, { as: 'div', layout: 'list' }, list);
    }
    return h('div', { className: cx('nn-skeleton-region', p.className), role: 'status', 'aria-busy': true,
        'aria-live': 'polite', 'aria-label': p.label || p.caption || 'Loading', 'data-layout': layout },
      h('div', { 'aria-hidden': true }, body),
      p.caption ? h(Text, { as: 'p', textStyle: 'sans-sm', tone: 'tertiary', className: 'nn-skeleton-region__caption' }, p.caption) : null);
  }

  // ---------- SegmentedBar: a distribution — a Bar and its key
  /** A segment's key: a swatch in the segment's own colour and the label. Never a Badge — a legend key
   *  names a slice of the bar, it is not a status the row carries. */
  function SegmentKey(s, size) {
    return h('span', { className: 'nn-segbar__key-label' },
      h('span', { className: 'nn-segbar__swatch', style: { background: barFill(s) } }),
      h(Text, { as: 'span', textStyle: size === 'row' ? 'sans-md' : 'sans-sm', tone: size === 'row' ? 'primary' : 'secondary' }, s.label));
  }
  /** segments [{label, value, reaction | color}] · legend true | 'rows' (a RatingList) · format · size (a Bar size). */
  function SegmentedBar(props) {
    var p = legacy(props, 'label', 'aria-label', 'SegmentedBar');
    var segs = (p.segments || []).filter(function (s) { return s.value > 0 || p.legend; });
    var total = 0;
    for (var i = 0; i < segs.length; i++) total += segs[i].value || 0;
    function figure(s) { return p.format === 'percent' && total ? Math.round(s.value / total * 100) + '%' : s.value; }
    var bar = h(Bar, { segments: segs, size: p.size || 'lg', 'aria-label': p['aria-label'] || p.title });

    // The breakdown IS a RatingList: the Bar is its meter, each tier is one of its rows.
    if (p.legend === 'rows') {
      return h(RatingList, {
        className: cx('nn-segbar-list', p.className),
        title: p.title || 'Distribution',
        trailing: p.trailing,
        bar: bar,
        rows: segs.map(function (s) {
          return { label: SegmentKey(s, 'row'),
            value: h(Text, { as: 'span', textStyle: 'serif-xs', numeric: true, tone: s.value ? 'primary' : 'tertiary' }, figure(s)) };
        })
      });
    }

    var legend = p.legend ? h('ul', { className: 'nn-segbar__legend' }, segs.map(function (s, i) {
      return h('li', { key: i, className: 'nn-segbar__key' },
        SegmentKey(s),
        h(Text, { as: 'span', textStyle: 'sans-sm', numeric: true, tone: s.value ? 'primary' : 'tertiary' }, figure(s)));
    })) : null;
    var bars = h('div', { className: cx('nn-segbar', p.title ? null : p.className) }, bar, legend);
    if (p.title) return h(Section, { title: p.title, trailing: p.trailing, className: cx('nn-segbar-section', p.className) }, bars);
    return bars;
  }

  // ---------- ValueStepper: minus · numeral · plus
  /** The numeral alone. `unit` only when nothing beside it names the number. */
  function ValueStepper(props) {
    var p = legacy(props, 'label', 'aria-label', 'ValueStepper');
    var min = p.min === undefined ? 1 : p.min;
    var max = p.max === undefined ? 99 : p.max;
    var step = p.step || 1;
    var ctl = useControlled(p.value, p.defaultValue === undefined ? min : p.defaultValue, p.onChange);
    var v = ctl[0];
    var size = p.size === 'sm' ? 'sm' : 'md';
    function go(d) { var n = Math.min(max, Math.max(min, v + d * step)); if (n !== v) ctl[1](n); }
    function btn(d, icon, label, off) {
      return h(AppButton, { variant: 'secondary', appearance: 'soft', size: size, iconOnly: true, icon: icon, label: label, disabled: off, onClick: function () { go(d); } });
    }
    return h('div', { className: cx('nn-stepper', p.className), 'data-size': p.size === 'sm' ? 'sm' : undefined, role: 'group', 'aria-label': p['aria-label'] },
      btn(-1, 'minus', p['aria-label'] ? 'Decrease ' + p['aria-label'] : 'Decrease', v <= min),
      h(Text, { className: 'nn-stepper__value', as: 'span', textStyle: 'sans-lg', numeric: true, 'aria-live': 'polite' },
        p.formatValue ? p.formatValue(v) : (p.unit ? v + ' ' + p.unit : v)),
      btn(1, 'plus', p['aria-label'] ? 'Increase ' + p['aria-label'] : 'Increase', v >= max));
  }

  // ---------- ScreenHeader: the top of every screen and sheet
  /** Avatar · eyebrow (SectionHeader) · h1 (Text serif-lg) · date (Text sans-sm) · one sentence · actions (AppButton md).
   *  Centred when there is an avatar or `role` is 'tabRoot' or 'moment'; otherwise start. Actions hug their label, one row, never an icon. */
  function screenHeaderDate(d) {
    if (!d) return null;
    if (typeof d === 'string') return d;
    var opts = { weekday: 'long', day: 'numeric', month: 'long' };
    if (d.getFullYear() !== new Date().getFullYear()) opts.year = 'numeric';
    return d.toLocaleDateString('en-GB', opts).replace(',', '');
  }
  function ScreenHeader(props) {
    var p = props;
    // `centered` is the app's flag for a sheet that opens as a centred prompt; an avatar always centres.
    var centred = !!(p.avatar || p.centered || p.role === 'tabRoot' || p.role === 'moment');
    var acts = (p.actions || []).filter(Boolean).slice(0, 2);
    var date = screenHeaderDate(p.date);
    return h('header', { className: cx('nn-screen-header', p.className), 'data-align': centred ? 'center' : 'start' },
      p.avatar ? h(Avatar, Object.assign({ size: 'xl', decorative: true }, p.avatar, { size: 'xl' }, p.avatarEdit ? { onEdit: p.avatarEdit.onEdit || p.avatarEdit, decorative: false } : null)) : null,
      p.eyebrow ? h(SectionHeader, { as: 'span', title: p.eyebrow }) : null,
      h(Text, { as: 'h1', textStyle: 'serif-lg' }, p.title),
      date ? h(Text, { className: 'nn-screen-header__date', as: 'p', textStyle: 'sans-sm', tone: 'tertiary' }, date) : null,
      p.summary ? h(Text, { className: 'nn-screen-header__summary', as: 'p', tone: 'secondary' }, p.summary) : null,
      acts.length ? h('div', { className: 'nn-screen-header__actions' }, acts.map(function (a, i) {
        var label = a.label !== undefined ? a.label : a.children;
        return h(AppButton, Object.assign({ key: i, variant: 'primary', appearance: 'solid' },
          omit(a, ['label', 'children', 'icon', 'iconPosition', 'iconOnly', 'fullWidth', 'size']), { size: 'md', label: label }));
      })) : null);
  }

  // ---------- Facts: small read-only facts about the subject
  /** Label (SectionHeader) over value (Text sans-md, text-primary). `grid` = 3 columns, wraps, max 6; `strip` = one row, hairlines, scrolls.
   *  Draws no surface: a Card around it is the caller's. */
  function Facts(props) {
    var p = props;
    var layout = p.layout === 'strip' ? 'strip' : 'grid';
    var items = (p.items || []).filter(function (f) { return f && f.value; });
    if (layout === 'grid') items = items.slice(0, 6);
    return h('dl', { className: cx('nn-facts', layout === 'strip' ? 'nn-scroller' : null, p.className), 'data-layout': layout },
      items.map(function (f, i) {
        return h('div', { key: i, className: 'nn-facts__item' },
          h('dt', null, h(SectionHeader, { as: 'span', title: f.label })),
          // onSelect: a silent button (the recipe's Cuisine opens that cuisine). It keeps its look: no chevron, no pressed state.
          h('dd', null, f.onSelect
            ? h('button', { type: 'button', className: 'nn-facts__select', onClick: f.onSelect }, h(Text, { textStyle: 'sans-md' }, f.value))
            : h(Text, { textStyle: 'sans-md' }, f.value)));
      }));
  }

  // ---------- LabeledPhotoCard: a photo tile with a label over a scrim
  /** PhotoCard + a scrim and a label. Category tiles, cuisine pickers, a party cover. Selected = PhotoCard's ring + a check. */
  function LabeledPhotoCard(props) {
    var p = props;
    var pressable = !!(p.onClick || p.href);
    var Tag = p.href ? 'a' : p.onClick ? 'button' : 'div';
    return h(Tag, {
      className: cx('nn-labeled-photo', p.className), type: Tag === 'button' ? 'button' : undefined,
      href: p.href, onClick: p.onClick, 'data-pressable': pressable ? '' : undefined,
      'aria-pressed': Tag === 'button' && p.selected !== undefined ? (p.selected ? 'true' : 'false') : undefined,
      'aria-current': Tag === 'a' && p.selected ? 'true' : undefined
    },
      h(PhotoCard, { src: p.photo, size: p.size || 'md', format: p.format || 'square', selected: p.selected }),
      h('span', { className: 'nn-labeled-photo__scrim' }),
      h('span', { className: 'nn-labeled-photo__label' },
        h(Text, { as: 'span', textStyle: p.size === 'lg' ? 'serif-sm' : 'sans-md', weight: p.size === 'lg' ? undefined : 'semibold', lines: 2 }, p.label),
        p.meta ? h(Text, { as: 'span', textStyle: 'sans-xs' }, p.meta) : null),
      p.selected ? h('span', { className: 'nn-labeled-photo__check' }, h(Icon, { name: 'check' })) : null);
  }

  // ---------- RecipeShelf: a section header over a row of RecipeCards
  /** Section + a .nn-scroller of RecipeCards. The one horizontal recipe carousel. */
  function RecipeShelf(props) {
    var p = props;
    var recipes = p.recipes || [];
    if (!recipes.length && p.empty !== false) {
      return h(Section, { className: cx('nn-shelf', p.className), title: p.title, trailing: p.trailing },
        h(EmptyState, Object.assign({ title: 'No recipes yet' }, p.emptyState)));
    }
    return h(Section, { className: cx('nn-shelf', p.className), title: p.title, trailing: p.trailing },
      h('div', { className: 'nn-shelf__track nn-scroller' }, recipes.map(function (r, i) {
        return h('div', { key: i, className: 'nn-shelf__item' },
          r.href || r.onClick
            ? h('a', { className: 'nn-shelf__link', href: r.href, onClick: r.onClick }, h(RecipeCard, r))
            : h(RecipeCard, r));
      })));
  }

  // ---------- PartyCard: a dinner party at a glance
  /** mode 'mine' — the party you are in, with its score and recent meals · 'discover' — one you could join. */
  function PartyCard(props) {
    var p = props;
    var discover = p.mode === 'discover';
    var meals = p.recentMeals || [];
    var pressable = !!(p.onClick || p.href);
    // Split like ListRow: the card holds the join button, so the card itself is never the control.
    var Main = p.href ? 'a' : 'button';
    var head = h('div', { className: 'nn-party-card__head' },
        h(Avatar, Object.assign({ size: 'lg', decorative: true }, p.avatar || { name: p.name })),
        h('div', { className: 'nn-party-card__id' },
          h(Text, { as: p.titleAs || 'h3', textStyle: 'serif-sm', lines: 2 }, p.name),
          h(Text, { as: 'div', textStyle: 'sans-sm', tone: 'tertiary' },
            [p.memberCount ? p.memberCount + (p.memberCount === 1 ? ' member' : ' members') : null, p.meta].filter(Boolean).join(' \u00b7 '))),
        discover ? null : h(ScoreValue, { score: p.score, size: 'sm' }));
    var summary = p.summary ? h(Text, { as: 'p', textStyle: 'sans-sm', tone: 'secondary', lines: 2 }, p.summary) : null;
    return h(Card, { className: cx('nn-party-card', p.className), chevron: false, 'data-mode': discover ? 'discover' : 'mine' },
      pressable
        ? h(Main, { className: 'nn-party-card__main', type: p.href ? undefined : 'button', href: p.href, onClick: p.onClick, 'aria-label': p['aria-label'] }, head, summary)
        : h(React.Fragment, null, head, summary),
      meals.length ? h(Timeline, { size: 'mini', className: 'nn-party-card__meals', occasions: meals.map(function (m) {
        return { photo: m.src, alt: m.alt, date: m.date, current: m.current, href: m.href };
      }) }) : null,
      // The app follows public parties; it does not ask to join them.
      discover && p.onJoin ? h(AppButton, { variant: 'primary', appearance: 'soft', size: 'sm', fullWidth: true, onClick: p.onJoin }, p.followLabel || 'Follow') : null);
  }

  // ---------- Pro: one language for everything that needs Nom Nom Pro
  /** The Pro mark: sparkles + "PRO" in pro-text. The one way to say "this is Pro". */
  function ProMark(props) {
    return h('span', { className: cx('nn-pro-mark', props.className) }, h(Icon, { name: 'sparkles' }), props.label || 'Pro');
  }
  /** A Pro block inside a free view. Unlocked: the content. Locked: a teaser, a blurred preview of the content, Unlock with Pro. */
  function ProCard(props) {
    var p = props;
    var locked = !!p.locked;
    // `action`: unlocked, the whole card is one button with a pro-text chevron (preview and way in at once). Locked: ignored.
    var pressable = !locked && !!p.action;
    return h('section', { className: cx('nn-pro-card', p.className), 'data-locked': locked ? '' : undefined, 'data-pressable': pressable ? '' : undefined, 'aria-label': p['aria-label'] || ('Pro: ' + (p.title || 'feature')) },
      pressable ? h('button', { type: 'button', className: 'nn-card__hit', onClick: p.action, 'aria-label': p.title || 'Open' }) : null,
      pressable ? h(Icon, { name: 'chevron-right', className: 'nn-pro-card__chevron' }) : null,
      p.mark === false ? null : h(ProMark, null),
      p.title || p.sub ? h('div', { className: 'nn-pro-card__head' },
        p.title ? h(Text, { as: p.titleAs || 'h3', textStyle: 'serif-sm' }, p.title) : null,
        p.sub ? h(Text, { as: 'div', textStyle: 'sans-xs', tone: 'tertiary' }, p.sub) : null) : null,
      locked ? h(React.Fragment, null,
        p.teaser ? h(Text, { as: 'p', tone: 'secondary' }, p.teaser) : null,
        p.children ? h('div', { className: 'nn-pro-card__preview', 'aria-hidden': true }, p.children) : null,
        h(AppButton, { variant: 'pro', size: 'lg', icon: 'sparkles', fullWidth: true, onClick: p.onUnlock }, p.unlockLabel || 'Unlock with Pro'))
        : h('div', { className: 'nn-pro-card__body' }, p.children));
  }
  /** A whole Pro-only view (a screen or sheet). Sets the pro-soft ground; cards on it stay panel. Put ProMark above the title. */
  function ProView(props) {
    var p = props;
    return h(p.as || 'div', { className: cx('nn-pro-view', p.className), style: p.style }, p.children);
  }
  /** A Pro-only view for someone without Pro: the real layout blurred behind a panel that says what it is and how to get it. */
  function ProGate(props) {
    var p = props;
    var benefits = p.benefits || [];
    return h('div', { className: cx('nn-pro-gate', p.className) },
      h('div', { className: 'nn-pro-gate__preview', 'aria-hidden': true }, p.children),
      h('div', { className: 'nn-pro-gate__panel', role: 'region', 'aria-label': p.title },
        h(ProMark, null),
        h(Text, { as: p.titleAs || 'h2', textStyle: 'serif-md' }, p.title),
        p.message ? h(Text, { as: 'p', tone: 'secondary' }, p.message) : null,
        benefits.length ? h('ul', { className: 'nn-pro-gate__benefits' }, benefits.map(function (b, i) {
          return h('li', { key: i }, h(Icon, { name: 'check' }), h(Text, null, b));
        })) : null,
        h('div', { className: 'nn-pro-gate__actions' },
          h(AppButton, { variant: 'pro', size: 'lg', icon: 'sparkles', fullWidth: true, onClick: p.onUnlock }, p.unlockLabel || 'Unlock with Pro'),
          p.onDismiss ? h(AppButton, { variant: 'secondary', appearance: 'ghost', size: 'md', fullWidth: true, onClick: p.onDismiss }, p.dismissLabel || 'Not now') : null)));
  }

  // =====================================================================
  // Adopted from the app, and the patterns it had that the system did not yet draw.
  // =====================================================================

  // ---------- BarButton / BarAction: the platform's top-bar controls (sheet and screen bars)
  /** A system toolbar button: a white glass circle (spacing-11) with a text-primary glyph. Never an AppButton, never the primary tint.
   *  `active` swaps to the filled glyph (`<icon>-fill`) and sets aria-pressed (the filter button); `unread` adds ListRow's dot. */
  function BarButton(props) {
    var p = props;
    var name = p.active && !p.activeIcon ? p.icon + '-fill' : (p.active ? p.activeIcon : p.icon);
    return h('button', { type: 'button', className: cx('nn-bar-button', p.className), 'aria-label': p.label, disabled: p.disabled, onClick: p.onClick,
      'aria-pressed': p.active === undefined ? undefined : (p.active ? 'true' : 'false'), 'data-unread': p.unread ? '' : undefined },
      h(Icon, { name: name }), p.unread ? h('span', { className: 'nn-bar-button__dot', 'aria-hidden': true }) : null,
      p.unread ? h('span', { className: 'nn-sr-only' }, 'Unread') : null);
  }
  /** A text action in a bar ("Next", "Mark all read"): sans-sm semibold primary-text, 44 tall. */
  function BarAction(props) {
    var p = props;
    return h('button', { type: 'button', className: cx('nn-bar-action', p.className), disabled: p.disabled, onClick: p.onClick }, p.loading ? h('span', { className: 'nn-spinner', 'aria-label': 'Working' }) : p.label);
  }

  // ---------- TagToggle: a selectable pill for multi-select tags
  /** The sm capsule with a selected state: panel at rest, primary-soft + primary-text semibold when on. Lay them out wrapping. */
  function TagToggle(props) {
    var p = props;
    return h('button', { type: 'button', className: cx('nn-tag', p.className), 'aria-pressed': p.selected ? 'true' : 'false', disabled: p.disabled, onClick: p.onClick }, p.label);
  }

  // ---------- ChoiceTile: one large choice in a single-choice grid
  /** Card's surface; chosen = its tint at opacity-20 with the copy inked. `reaction` tints a taste step, else primary. */
  function ChoiceTile(props) {
    var p = props;
    return h('button', { type: 'button', className: cx('nn-choice', p.className), 'aria-pressed': p.selected ? 'true' : 'false',
      'data-square': p.square === false ? 'false' : undefined, 'data-reaction': p.reaction || undefined, onClick: p.onClick },
      h(Text, { textStyle: p.numeral ? 'serif-md' : 'serif-xs', numeric: !!p.numeral }, p.title),
      p.sub ? h(Text, { textStyle: 'sans-sm', weight: p.selected ? 'semibold' : undefined }, p.sub) : null);
  }

  // ---------- NoteField / NoteEditor: every multi-line note in a form
  /** A row that shows the note as the cook's note (serif-xs italic) or a placeholder; tapping opens the editor. No chevron. */
  function NoteField(props) {
    var p = props;
    return h('button', { type: 'button', className: cx('nn-note', p.className), onClick: p.onOpen, 'aria-label': p.label || 'Edit note' },
      p.value
        ? h(Text, { as: 'span', textStyle: 'serif-xs', italic: true, lines: p.bulleted ? undefined : 3 }, p.value)
        : h(Text, { as: 'span', textStyle: 'sans-md', tone: 'tertiary' }, p.placeholder || 'Add a note'));
  }
  /** The note editor sheet: inline title, close (discards) and checkmark, one panel Card with a plain TextArea, Delete note. Bulleted notes get the format bar. */
  function NoteEditor(props) {
    var p = props;
    var st = useState(p.value || '');
    var dirty = st[0] !== (p.value || '');
    function toggleList() {
      var lines = st[0].split('\n');
      var all = lines.every(function (l) { return /^• /.test(l); });
      st[1](lines.map(function (l) { return all ? l.replace(/^• /, '') : (/^• /.test(l) ? l : '• ' + l); }).join('\n'));
    }
    return h(BottomSheet, { title: p.title || 'Note', kind: 'commit', dirty: dirty, onClose: p.onClose, onConfirm: function () { if (p.onSave) p.onSave(st[0]); }, style: p.style },
      h(Card, { className: 'nn-note-editor__card' },
        h(TextArea, { appearance: 'plain', rows: 8, value: st[0], onChange: st[1], placeholder: p.placeholder || 'Write a note', 'aria-label': p.title || 'Note' })),
      p.bulleted || p.formatBar ? h('div', { className: 'nn-format-bar' },
        p.onDelete && p.value ? h(AppButton, { variant: 'destructive', appearance: 'ghost', iconOnly: true, icon: 'trash', label: 'Delete note', onClick: p.onDelete }) : null,
        h(AppButton, { variant: 'secondary', appearance: 'ghost', iconOnly: true, icon: 'list', label: 'Bulleted list', onClick: toggleList })) : null,
      !(p.bulleted || p.formatBar) && p.onDelete && p.value ? h(AppButton, { variant: 'destructive', appearance: 'soft', size: 'lg', fullWidth: true, onClick: p.onDelete }, 'Delete note') : null);
  }

  // ---------- PersonHeaderRow: the person at the top of a rater or member sheet
  function PersonHeaderRow(props) {
    var p = props;
    var Tag = p.onClick ? 'button' : 'div';
    return h(Tag, { type: Tag === 'button' ? 'button' : undefined, className: cx('nn-person-row', p.className), onClick: p.onClick },
      h(Avatar, { name: p.name, photo: p.photo, size: 'lg', decorative: true }),
      h('span', { className: 'nn-person-row__body' },
        h(Text, { as: 'span', textStyle: p.large ? 'serif-md' : 'serif-sm' }, p.name),
        p.meta ? h(Text, { as: 'span', textStyle: 'sans-sm', tone: 'tertiary' }, p.meta) : null),
      p.onClick ? h(Icon, { name: 'chevron-right', className: 'nn-person-row__chevron' }) : null);
  }

  // ---------- DismissibleNotice: an inline message the person can close
  /** A recoverable problem, in the warning role. Controlled with `onDismiss`, or uncontrolled: it hides itself. */
  function DismissibleNotice(props) {
    var p = props;
    var st = useState(true);
    if (!st[0]) return null;
    return h('div', { className: cx('nn-notice', p.className), role: 'status' },
      h(Text, { as: 'span', textStyle: 'sans-sm', className: 'nn-notice__text' }, p.children),
      h(AppButton, { variant: 'secondary', appearance: 'ghost', iconOnly: true, icon: 'x', label: p.dismissLabel || 'Dismiss',
        onClick: function () { if (p.onDismiss) p.onDismiss(); else st[1](false); } }));
  }

  // ---------- ProLinkCard: a pressable card into a Pro screen
  function ProLinkCard(props) {
    var p = props;
    var Tag = p.href ? 'a' : 'button';
    return h(Tag, { type: p.href ? undefined : 'button', href: p.href, className: cx('nn-pro-link', p.className), onClick: p.onClick },
      h('span', { className: 'nn-pro-link__body' }, h(ProMark, null),
        h(Text, { as: 'span', textStyle: 'serif-sm' }, p.title),
        p.subtitle ? h(Text, { as: 'span', textStyle: 'sans-sm', tone: 'secondary' }, p.subtitle) : null),
      h(Icon, { name: 'chevron-right', className: 'nn-pro-card__chevron' }));
  }

  // ---------- PageMenu: the "…" menu on every root and detail screen
  /** groups: [{ items: [{ label, onClick, checked, destructive }] }], in order: context actions, dinner party, inbox / profile / settings, Pro / help.
   *  `open` draws the menu (a popover) under its trigger; `unread` puts ListRow's dot on the trigger. */
  function PageMenu(props) {
    var p = props;
    var st = useState(!!p.defaultOpen);
    var open = p.open !== undefined ? p.open : st[0];
    function set(v) { if (p.open === undefined) st[1](v); if (p.onOpenChange) p.onOpenChange(v); }
    return h('div', { className: cx('nn-page-menu', p.className) },
      h(BarButton, { icon: 'ellipsis', label: 'More', unread: p.unread, onClick: function () { set(!open); } }),
      open ? h('div', { className: 'nn-page-menu__panel', role: 'menu' }, (p.groups || []).map(function (g, i) {
        return h('div', { key: i, className: 'nn-page-menu__group', role: 'group' },
          g.label ? h(SectionHeader, { as: 'span', title: g.label }) : null,
          g.items.map(function (it, j) {
            return h('button', { key: j, type: 'button', role: it.checked !== undefined ? 'menuitemradio' : 'menuitem', 'aria-checked': it.checked === undefined ? undefined : (it.checked ? 'true' : 'false'),
              className: 'nn-page-menu__item', 'data-destructive': it.destructive ? '' : undefined, onClick: function () { set(false); if (it.onClick) it.onClick(); } },
              h(Text, { as: 'span', weight: it.checked ? 'semibold' : undefined }, it.label), it.checked ? h(Icon, { name: 'check' }) : null);
          }));
      })) : null);
  }

  // ---------- TrendChart: scores over time
  /** total: number[] (primary, border-thick) · members: [{ name, values }] (dashed, chart-series by stable index) · labels: x labels.
   *  framed false = bleeds edge to edge · showsPoints = a primary dot on every total value. Drag or hover to scrub; the tooltip clears on release. */
  function TrendChart(props) {
    var p = props;
    var total = p.total || [];
    var members = p.members || [];
    var W = 320, H = 180, padX = 8, padY = 12;
    var scrub = useState(null);
    var n = Math.max(total.length, 2);
    function x(i) { return padX + (W - 2 * padX) * (i / (n - 1)); }
    function y(v) { return padY + (H - 2 * padY) * (1 - v / 100); }
    function path(vals) { return vals.map(function (v, i) { return (i ? 'L' : 'M') + x(i).toFixed(1) + ' ' + y(v).toFixed(1); }).join(' '); }
    function at(e) {
      var r = e.currentTarget.getBoundingClientRect();
      var i = Math.round(((e.clientX - r.left) / r.width * W - padX) / (W - 2 * padX) * (n - 1));
      scrub[1](Math.max(0, Math.min(total.length - 1, i)));
    }
    var i = scrub[0];
    var chart = h('div', { className: 'nn-trend', 'data-framed': p.framed === false ? 'false' : undefined },
      h('svg', { viewBox: '0 0 ' + W + ' ' + H, className: 'nn-trend__svg', role: 'img', 'aria-label': p['aria-label'] || 'Score trend',
        onPointerDown: at, onPointerMove: function (e) { if (e.buttons || e.pointerType === 'mouse') at(e); }, onPointerLeave: function () { scrub[1](null); }, onPointerUp: function () { scrub[1](null); } },
        [0, 25, 50, 75, 100].map(function (g) { return h('line', { key: g, className: 'nn-trend__grid', x1: padX, x2: W - padX, y1: y(g), y2: y(g) }); }),
        !members.length && total.length ? h('path', { className: 'nn-trend__area', d: path(total) + ' L' + x(total.length - 1) + ' ' + y(0) + ' L' + x(0) + ' ' + y(0) + ' Z' }) : null,
        members.map(function (m, k) { return h('path', { key: k, className: 'nn-trend__member', d: path(m.values), style: { stroke: 'var(--chart-series' + (k % 7 + 1) + ')' } }); }),
        total.length ? h('path', { className: 'nn-trend__total', d: path(total) }) : null,
        p.showsPoints ? total.map(function (v, k) { return h('circle', { key: k, className: 'nn-trend__dot', cx: x(k), cy: y(v) }); }) : null,
        i !== null && total[i] !== undefined ? h('line', { className: 'nn-trend__cursor', x1: x(i), x2: x(i), y1: padY, y2: H - padY }) : null),
      i !== null && total[i] !== undefined ? h(Card, { size: 'sm', className: 'nn-trend__tip', style: { left: (x(i) / W * 100) + '%' } },
        h(Text, { textStyle: 'sans-xs', tone: 'tertiary' }, (p.labels || [])[i] || ''),
        h(Text, { textStyle: 'sans-sm', weight: 'semibold', numeric: true }, 'Household ' + total[i]),
        members.map(function (m, k) { return h(Text, { key: k, textStyle: 'sans-xs', numeric: true, tone: 'secondary' }, m.name + ' ' + m.values[i]); })) : null);
    return p.framed === false ? chart : h(Card, null, chart);
  }

  // ---------- MediaViewer: the one full-screen photo viewer (dark chrome)
  function MediaViewer(props) {
    var p = props;
    var photos = p.photos || [];
    var st = useState(p.index || 0);
    var i = st[0];
    return h(BottomSheet, { kind: 'media', title: 'Photo ' + (i + 1) + ' of ' + photos.length, onClose: p.onClose, style: p.style,
      action: photos.length > 1 ? h('span', { className: 'nn-viewer__pager' },
        h(BarButton, { icon: 'chevron-left', label: 'Previous photo', disabled: i === 0, onClick: function () { st[1](i - 1); } }),
        h(BarButton, { icon: 'chevron-right', label: 'Next photo', disabled: i === photos.length - 1, onClick: function () { st[1](i + 1); } })) : null },
      h('img', { className: 'nn-viewer__img', src: photos[i] && (photos[i].src || photos[i]), alt: (photos[i] && photos[i].alt) || '' }));
  }

  // ---------- Form blocks
  /** A Card list of plain fields: fields: [{ label, ...InputProps }]. Plain, because the row already draws the ground. */
  function FieldGroup(props) {
    var p = props;
    return h(Section, { title: p.title, trailing: p.trailing, className: p.className },
      h(Card, { layout: 'list' }, (p.fields || []).map(function (f, i) {
        return h('div', { key: i, className: 'nn-field-group__row' }, h(Input, Object.assign({ appearance: 'plain' }, f)));
      })), p.hint ? h(Text, { as: 'p', textStyle: 'sans-xs', tone: 'secondary', className: 'nn-field-group__hint' }, p.hint) : null);
  }
  /** A visibility (or any single on/off) setting: a Card with one Toggle row and a sentence saying what it does. */
  function ToggleCard(props) {
    var p = props;
    return h(Section, { title: p.heading, className: p.className },
      h(Card, null,
        h(ListRow, { title: p.title, meta: p.meta, chevron: false, trailing: h(Toggle, { checked: p.checked, defaultChecked: p.defaultChecked, onChange: p.onChange, 'aria-label': p.title }) }),
        p.footnote ? h(Text, { as: 'p', textStyle: 'sans-sm', tone: 'secondary' }, p.footnote) : null));
  }
  /** Sign out and delete account: the last block on a screen. Destructive rows carry no icon; the word is enough. */
  function AccountActions(props) {
    var p = props;
    return h(Card, { layout: 'list', className: p.className },
      h(ListRow, { title: 'Sign out', variant: 'destructive', chevron: false, onClick: p.onSignOut }),
      h(ListRow, { title: 'Delete account', variant: 'destructive', chevron: false, onClick: p.onDelete }));
  }

  // ---------- CodeField: a one-time code
  /** `length` cells (spacing-14 tall, sunken, radius-xl) over one real input. The active cell shows a primary caret (border-thick, blinks over duration-layout). */
  function CodeField(props) {
    var p = props;
    var length = p.length || 6;
    var ctl = useControlled(p.value, p.defaultValue || '', p.onChange);
    var v = ctl[0] || '';
    var id = useId('nn-code');
    return h('div', { className: cx('nn-code', p.className), 'data-error': p.error ? '' : undefined },
      p.label ? h(Text, { as: 'label', htmlFor: id, textStyle: 'sans-xs', tone: 'secondary' }, p.label) : null,
      h('div', { className: 'nn-code__cells' },
        h('input', { id: id, className: 'nn-code__input', inputMode: 'numeric', autoComplete: 'one-time-code', maxLength: length, value: v, 'aria-invalid': p.error ? 'true' : undefined,
          onChange: function (e) { ctl[1](e.target.value.replace(/\D/g, '').slice(0, length)); } }),
        Array.apply(null, { length: length }).map(function (_, i) {
          return h('span', { key: i, className: 'nn-code__cell', 'data-active': i === v.length ? '' : undefined },
            h(Text, { textStyle: 'serif-md', numeric: true }, v[i] || ''));
        })),
      typeof p.error === 'string' ? h(Text, { as: 'span', textStyle: 'sans-xs', role: 'alert' }, p.error) : null);
  }

  // ---------- PackageCard: one plan on the paywall
  /** Pressable, role=radio: pro-soft ground when chosen (no ring), a check, the price in pro-text. Put them in a role=radiogroup. */
  function PackageCard(props) {
    var p = props;
    return h('button', { type: 'button', role: 'radio', 'aria-checked': p.selected ? 'true' : 'false', className: cx('nn-package', p.className), onClick: p.onSelect },
      h('span', { className: 'nn-package__body' },
        h(Text, { as: 'span', textStyle: 'serif-sm' }, p.title),
        p.note ? h(Text, { as: 'span', textStyle: 'sans-sm', tone: 'secondary' }, p.note) : null),
      p.badge ? h(Badge, { variant: 'pro', size: 'sm' }, p.badge) : null,
      h('span', { className: 'nn-package__price' },
        h(Text, { as: 'span', textStyle: 'serif-xs', numeric: true, style: { color: 'var(--pro-text)' } }, p.price),
        p.period ? h(Text, { as: 'span', textStyle: 'sans-xs', tone: 'tertiary' }, p.period) : null),
      h('span', { className: 'nn-package__check', 'aria-hidden': true }, p.selected ? h(Icon, { name: 'check' }) : null));
  }

  // ---------- Recipe content: numbered steps and the checkable ingredient list
  /** Steps on a rail: a primary-soft disc with the number, a rail between discs, the step in sans-md. `current` highlights one. */
  function StepList(props) {
    var p = props;
    return h('ol', { className: cx('nn-steps', p.className) }, (p.steps || []).map(function (s, i) {
      var step = typeof s === 'string' ? { text: s } : s;
      return h('li', { key: i, className: 'nn-steps__item', 'aria-current': p.current === i ? 'step' : undefined },
        h('span', { className: 'nn-steps__disc', 'aria-hidden': true }, h(Text, { textStyle: 'sans-sm', weight: 'semibold', numeric: true, style: { color: 'var(--primary-text)' } }, i + 1)),
        h('span', { className: 'nn-steps__body' }, step.title ? h(Text, { as: 'span', textStyle: 'sans-lg', weight: 'semibold' }, step.title) : null, h(Text, { as: 'span' }, step.text)));
    }));
  }
  /** One ingredient row: a check, the name (wraps), the amount (semibold, right). The whole row is the switch. */
  function CheckRow(props) {
    var p = props;
    var ctl = useControlled(p.checked, p.defaultChecked || false, p.onChange);
    return h('button', { type: 'button', role: 'checkbox', 'aria-checked': ctl[0] ? 'true' : 'false', className: cx('nn-check-row', p.className), onClick: function () { ctl[1](!ctl[0]); } },
      h('span', { className: 'nn-check-row__box', 'aria-hidden': true }, ctl[0] ? h(Icon, { name: 'check' }) : null),
      h(Text, { as: 'span', className: 'nn-check-row__name' }, p.name),
      p.amount ? h(Text, { as: 'span', textStyle: 'sans-sm', weight: 'semibold', numeric: true, tone: 'secondary' }, p.amount) : null);
  }
  function IngredientList(props) {
    var p = props;
    return h(Card, { layout: 'list', className: p.className }, (p.items || []).map(function (it, i) { return h(CheckRow, Object.assign({ key: i }, it)); }));
  }

  // ---------- SelectRow: a row that picks one of a few options (the platform picker)
  function SelectRow(props) {
    var p = props;
    var id = useId('nn-select');
    var sel = (p.options || []).filter(function (o) { return (o.value !== undefined ? o.value : o) === p.value; })[0];
    return h('div', { className: cx('nn-row', 'nn-select-row', p.className), 'data-pressable': '' },
      h('span', { className: 'nn-row__body' }, h(Text, { as: 'label', htmlFor: id, weight: 'semibold' }, p.title), p.meta ? h(Text, { as: 'span', textStyle: 'sans-sm', tone: 'secondary' }, p.meta) : null),
      h(Text, { as: 'span', textStyle: 'sans-sm', tone: 'secondary' }, sel ? (sel.label || sel) : p.placeholder || ''),
      h(Icon, { name: 'chevron-up-down', className: 'nn-row__chevron' }),
      h('select', { id: id, className: 'nn-select-row__native', value: p.value, onChange: function (e) { if (p.onChange) p.onChange(e.target.value); } },
        (p.options || []).map(function (o, i) { var v = o.value !== undefined ? o.value : o; return h('option', { key: i, value: v }, o.label || v); })));
  }

  // ---------- BrandMark: the app icon
  /** The app icon is a photograph: show it as given (src), at Avatar xl size with radius-2xl and a hairline. Never redraw it. */
  function BrandMark(props) {
    var p = props;
    return h('span', { className: cx('nn-brand-mark', p.className), 'data-size': p.size === 'lg' ? 'lg' : undefined }, h('img', { src: p.src, alt: p.alt || 'Nom Nom' }));
  }

  // ---------- SwipeRow: a ListRow with actions behind it
  /** actions: [{ label, variant: 'destructive' | 'secondary' | 'primary', onClick }]. Swipe left to reveal; `revealed` / `onRevealedChange` drive it.
   *  The same actions are always reachable without a gesture through `aria-label`led buttons (focusing one reveals the set). */
  function SwipeRow(props) {
    var p = props;
    var st = useState(!!p.defaultRevealed);
    var open = p.revealed !== undefined ? p.revealed : st[0];
    function set(v) { if (p.revealed === undefined) st[1](v); if (p.onRevealedChange) p.onRevealedChange(v); }
    var start = React.useRef(null);
    return h('div', { className: cx('nn-swipe', p.className), 'data-open': open ? '' : undefined,
      onPointerDown: function (e) { start.current = e.clientX; },
      onPointerUp: function (e) { if (start.current === null) return; var dx = e.clientX - start.current; start.current = null; if (dx < -spacingPx(24)) set(true); else if (dx > spacingPx(24)) set(false); } },
      h('div', { className: 'nn-swipe__actions' }, (p.actions || []).map(function (a, i) {
        return h(AppButton, { key: i, variant: a.variant || 'destructive', appearance: 'solid', onClick: a.onClick, onFocus: function () { set(true); }, tabIndex: open ? 0 : -1 }, a.label);
      })),
      h('div', { className: 'nn-swipe__front' }, p.children));
  }
  function spacingPx(n) { return n; }

  // ---------- Reorder: drag to reorder any set (list rows, strip tiles), either axis
  /** No wrapper of its own: each child becomes a draggable `.nn-reorder__item`, a direct child of the consumer's
   *  Card list or strip, so its hairlines and gaps hold. Sets with the same `group` take each other's items.
   *  onMove(moved, target) puts `moved` where `target` is; the set moves live as the item passes over others. */
  var reorderDrag = { id: null, group: null };
  var reorderListeners = [];
  function reorderSet(id, group) {
    reorderDrag.id = id; reorderDrag.group = group;
    reorderListeners.forEach(function (f) { f(); });
  }
  if (typeof document !== 'undefined') {
    // The held item may have moved to another set (and remounted) by the time the drag ends.
    document.addEventListener('dragend', function () { if (reorderDrag.id !== null) reorderSet(null, null); }, true);
    document.addEventListener('drop', function () { if (reorderDrag.id !== null) reorderSet(null, null); }, true);
  }
  function useReorderDrag() {
    var tick = useState(0);
    React.useEffect(function () {
      function f() { tick[1](function (n) { return n + 1; }); }
      reorderListeners.push(f);
      return function () { reorderListeners = reorderListeners.filter(function (x) { return x !== f; }); };
    }, []);
  }
  function reorderAccepts(e, group) {
    if (reorderDrag.id === null || reorderDrag.group !== group) return false;
    e.preventDefault();
    return true;
  }
  function Reorder(props) {
    var p = props;
    useReorderDrag();
    var ids = p.items || [];
    var horizontal = p.axis === 'horizontal';
    function move(moved, target) { if (moved !== target && p.onMove) p.onMove(moved, target); }
    return h(React.Fragment, null, React.Children.toArray(p.children).map(function (child, i) {
      var id = ids[i];
      return h('div', {
        key: id, className: cx('nn-reorder__item', p.itemClassName), tabIndex: 0, draggable: true,
        'data-axis': horizontal ? 'horizontal' : 'vertical',
        'data-dragging': reorderDrag.id === id ? '' : undefined,
        'aria-roledescription': 'reorderable',
        'aria-keyshortcuts': horizontal ? 'Alt+ArrowLeft Alt+ArrowRight' : 'Alt+ArrowUp Alt+ArrowDown',
        onDragStart: function (e) { e.dataTransfer.effectAllowed = 'move'; e.dataTransfer.setData('text/plain', String(id)); reorderSet(id, p.group); },
        onDragOver: function (e) { reorderAccepts(e, p.group); },
        onDragEnter: function (e) { if (reorderAccepts(e, p.group)) move(reorderDrag.id, id); },
        onDrop: function (e) { e.preventDefault(); },
        onKeyDown: function (e) {
          if (!e.altKey) return;
          var back = horizontal ? 'ArrowLeft' : 'ArrowUp', fwd = horizontal ? 'ArrowRight' : 'ArrowDown';
          if (e.key === back && i > 0) { e.preventDefault(); move(id, ids[i - 1]); }
          if (e.key === fwd && i < ids.length - 1) { e.preventDefault(); move(id, ids[i + 1]); }
        }
      }, child);
    }));
  }
  /** A drop target with no item of its own: a set's footer or empty state. onEnter(moved) runs as an item of the same group comes over it. */
  function ReorderTarget(props) {
    var p = props;
    return h('div', { className: cx('nn-reorder-target', p.className),
      onDragOver: function (e) { reorderAccepts(e, p.group); },
      onDragEnter: function (e) { if (reorderAccepts(e, p.group) && p.onEnter) p.onEnter(reorderDrag.id); },
      onDrop: function (e) { e.preventDefault(); } }, p.children);
  }

  // ---------- EditorialText: positive and negative fragments inside a sentence
  /** parts: ['plain text', { text, tone: 'positive' | 'negative' }]. positive = primary-text, negative = warning-text, serif-xs. Colour is never the only signal: pair with the words. */
  function EditorialText(props) {
    var p = props;
    return h(Text, { as: 'p', textStyle: 'serif-xs', className: cx('nn-editorial', p.className) }, (p.parts || []).map(function (part, i) {
      if (typeof part === 'string') return h(React.Fragment, { key: i }, part);
      return h('span', { key: i, className: 'nn-editorial__' + (part.tone === 'negative' ? 'neg' : 'pos') }, part.text);
    }));
  }

  // ---------- ScannerOverlay: the card over the camera while a recipe is read
  function ScannerOverlay(props) {
    var p = props;
    return h('div', { className: cx('nn-scanner', p.className), style: p.style },
      h(Card, { className: 'nn-scanner__card', role: 'status' },
        h(Text, { as: 'h3', textStyle: 'serif-sm' }, p.title || 'Reading the recipe'),
        p.message ? h(Text, { as: 'p', textStyle: 'sans-sm', tone: 'secondary' }, p.message) : null,
        p.onCancel ? h(AppButton, { variant: 'secondary', appearance: 'soft', fullWidth: true, onClick: p.onCancel }, 'Cancel') : null));
  }

  // ---------- Units: a recipe's metric / imperial choice
  var UNIT_TABLE = {
    g: { to: 'imperial', f: function (q) { return q >= 454 ? [q / 453.592, 'lb'] : [q / 28.3495, 'oz']; } },
    kg: { to: 'imperial', f: function (q) { return [q * 2.20462, 'lb']; } },
    ml: { to: 'imperial', f: function (q) { return q >= 240 ? [q / 236.588, 'cups'] : [q / 29.5735, 'fl oz']; } },
    l: { to: 'imperial', f: function (q) { return [q * 4.22675, 'cups']; } },
    oz: { to: 'metric', f: function (q) { return [q * 28.3495, 'g']; } },
    lb: { to: 'metric', f: function (q) { return q * 453.592 >= 1000 ? [q * 0.453592, 'kg'] : [q * 453.592, 'g']; } },
    cups: { to: 'metric', f: function (q) { return [q * 236.588, 'ml']; } },
    cup: { to: 'metric', f: function (q) { return [q * 236.588, 'ml']; } },
    'fl oz': { to: 'metric', f: function (q) { return [q * 29.5735, 'ml']; } }
  };
  /** convertAmount('500', 'g', 'imperial') → { quantity: '1.1', unit: 'lb' }. tsp and tbsp, counts and unknown units never convert. */
  function convertAmount(quantity, unit, to) {
    var rule = UNIT_TABLE[String(unit || '').toLowerCase()];
    var q = parseFloat(String(quantity).replace(',', '.'));
    if (!rule || rule.to !== to || isNaN(q)) return { quantity: String(quantity), unit: unit };
    var r = rule.f(q), v = r[0];
    var s = v >= 100 ? String(Math.round(v)) : v >= 10 ? String(Math.round(v * 10) / 10) : String(Math.round(v * 100) / 100);
    return { quantity: s.replace(/\.0+$/, ''), unit: r[1] };
  }
  /** The "Imperial units" row above a recipe's ingredients (next to the Servings stepper). One switch; tsp and tbsp do not convert. */
  function UnitToggle(props) {
    var p = props;
    return h(ListRow, { className: p.className, title: p.title || 'Imperial units', meta: p.meta || 'Show amounts in oz, lb and cups', chevron: false,
      trailing: h(Toggle, { checked: p.imperial, defaultChecked: p.defaultImperial, onChange: p.onChange, 'aria-label': p.title || 'Imperial units' }) });
  }

  // ---------- AddRow: a full-width add target inside a list card
  /** The first (or last) row of a Card layout="list": a plus in a primary-soft disc and the verb in primary-text semibold. */
  function AddRow(props) {
    var p = props;
    return h('button', { type: 'button', className: cx('nn-add-row', p.className), onClick: p.onClick },
      h('span', { className: 'nn-add-row__glyph', 'aria-hidden': true }, h(Icon, { name: 'plus' })), p.label);
  }

  // ---------- CollectionSection: a section of things the viewer may add to
  /** The rule for every section that holds a collection, in one component. `count` (default: the children) decides the state:
   *  has items + canAdd → the header carries the one verb · empty + canAdd → the EmptyState carries it (header action not drawn) ·
   *  empty, cannot add → EmptyState with no button · has items, cannot add → label and count only.
   *  verb is the short header word ("New party"), addLabel the longer form for VoiceOver and the empty state ("Add a recipe"). */
  function CollectionSection(props) {
    var p = props;
    var n = p.count !== undefined && p.count !== null ? p.count : React.Children.count(p.children);
    var isEmpty = Number(n) === 0;
    var can = p.canAdd !== false && !!p.onAdd;
    var empty = p.empty || {};
    var header = can && !isEmpty ? { label: p.verb || 'Add', 'aria-label': p.addLabel || p.verb, onClick: p.onAdd } : undefined;
    // The number is not shown by default: "Meal history 31" says nothing the list does not. `showCount` is for a count the person acts on.
    return h(Section, { title: p.title, count: p.showCount ? n : undefined, action: header, className: cx('nn-collection', p.className) },
      isEmpty
        ? h(EmptyState, { title: empty.title || 'Nothing here yet', message: empty.message, icon: empty.icon,
            action: can ? { label: p.addLabel || p.verb || 'Add', onClick: p.onAdd } : undefined })
        : p.children);
  }

  var NomNom = {
    DismissibleNotice: DismissibleNotice, CollectionSection: CollectionSection, AddRow: AddRow, BarButton: BarButton, BarAction: BarAction, TagToggle: TagToggle, ChoiceTile: ChoiceTile, NoteField: NoteField, NoteEditor: NoteEditor,
    PersonHeaderRow: PersonHeaderRow, ProLinkCard: ProLinkCard, PageMenu: PageMenu, TrendChart: TrendChart, MediaViewer: MediaViewer,
    FieldGroup: FieldGroup, ToggleCard: ToggleCard, AccountActions: AccountActions, CodeField: CodeField, PackageCard: PackageCard,
    StepList: StepList, CheckRow: CheckRow, IngredientList: IngredientList, SelectRow: SelectRow, BrandMark: BrandMark, SwipeRow: SwipeRow, Reorder: Reorder, ReorderTarget: ReorderTarget,
    EditorialText: EditorialText, ScannerOverlay: ScannerOverlay, UnitToggle: UnitToggle, convertAmount: convertAmount,
    Text: Text, Card: Card, AppButton: AppButton, Badge: Badge, Input: Input, TextArea: TextArea,
    TasteScoreSelector: TasteScoreSelector,
    SectionHeader: SectionHeader, Section: Section, SectionCard: SectionCard, Avatar: Avatar, ScoreValue: ScoreValue,
    PhotoCard: PhotoCard, RecipeCard: RecipeCard, PhotoStrip: PhotoStrip, RecipeLinkCard: RecipeLinkCard,
    Bar: Bar, ScoreCard: ScoreCard, RatingList: RatingList, Timeline: Timeline, BottomSheet: BottomSheet,
    ListRow: ListRow, Toggle: Toggle, EmptyState: EmptyState, Skeleton: Skeleton,
    LabeledPhotoCard: LabeledPhotoCard, RecipeShelf: RecipeShelf, PartyCard: PartyCard,
    SegmentedBar: SegmentedBar, ValueStepper: ValueStepper, ScreenHeader: ScreenHeader, Facts: Facts,
    // parts and helpers
    ProMark: ProMark, ProCard: ProCard, ProView: ProView, ProGate: ProGate,
    Icon: Icon, SheetCard: SheetCard, Reason: Reason,
    REACTIONS: REACTIONS, reactionForScore: reactionForScore, verdictForScore: verdictForScore
  };
  window.NomNom = Object.assign(window.NomNom || {}, NomNom);
})();
