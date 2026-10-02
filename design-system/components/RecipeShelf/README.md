A section header over a horizontal row of RecipeCards: the one recipe carousel.

**Built from:** Section · SectionHeader · RecipeCard · `.nn-scroller` · EmptyState.

Replaces the four hand-built shelf variants.

## Axes

| prop | values |
| --- | --- |
| `title` · `trailing` | the Section's header and its right-hand figure or link |
| `recipes` | `RecipeCardProps[]` — each card keeps its own `href` or `onClick` |
| `emptyState` | EmptyState props, shown instead of the row when there are no recipes |

## Rules
- The track is `.nn-scroller`: tiles snap, the bar fades in on hover, touch gets the platform's own.
- Cards are RecipeCard at its own size; the shelf sets no dimensions. A shelf of different-sized cards is not a shelf.
- A recipe with nowhere to go renders as a plain card, not a link to `#`.
- An empty shelf is an EmptyState, never an empty track. Pass `emptyState` to say what is missing and what to do.
- One shelf per section. Two shelves under one header is two sections.

## Use
```js
h(N.RecipeShelf, { title: 'Cooked recently', trailing: '12', recipes: recipes,
  emptyState: { title: 'No recipes yet', action: { label: 'Add one', onClick: add } } })
```
Markup: `section.nn-section.nn-shelf` > `.nn-section-header`, `.nn-shelf__track.nn-scroller` > `.nn-shelf__item` > `a.nn-shelf__link` > `.nn-recipe-card`.
