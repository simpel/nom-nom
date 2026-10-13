'use client';

import Image from 'next/image';
import { useEffect, useState, type CSSProperties } from 'react';
import type { PileCard } from '@/lib/landing-photos';

type Landing = { x: number; y: number; r: number };

// Offsets are in card widths. Each card flies out from the centre along its
// own direction: the angles split the full circle evenly, with a random turn
// and a random order so no two loads fan out the same way. The pile is wider
// than tall, so the circle is squashed to an ellipse.
const REACH_X = 0.95;
const REACH_Y = 0.55;
const jitter = (range: number) => (Math.random() * 2 - 1) * range;

function shuffle<T>(items: T[]): T[] {
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
}

// Landings come in left/right mirrored pairs (an odd card out lands on the
// centre line), so the spread is always balanced around the middle of the pile.
function scatter(count: number): Landing[] {
  const pairs = Math.floor(count / 2);
  const slice = Math.PI / Math.max(pairs, 1);
  const lands: Landing[] = [];
  for (let i = 0; i < pairs; i++) {
    const angle = -Math.PI / 2 + slice * (i + 0.5) + jitter(slice * 0.3);
    const distance = 0.45 + Math.random() * 0.55;
    const x = Math.cos(angle) * distance * REACH_X;
    const y = Math.sin(angle) * distance * REACH_Y;
    const r = 4 + Math.random() * 8;
    lands.push({ x, y, r }, { x: -x, y, r: -r });
  }
  if (count % 2) lands.push({ x: 0, y: (Math.random() < 0.5 ? -1 : 1) * 0.3 * REACH_Y, r: jitter(6) });
  return shuffle(lands);
}

/**
 * A stack of dinner photos with their verdicts. Server-rendered squared up in
 * one spot; once mounted each card eases to a random landing. The photos are
 * signed storage links, so Next's optimiser is skipped for them.
 */
export function PhotoPile({ cards }: { cards: PileCard[] }) {
  const [landings, setLandings] = useState<Landing[] | null>(null);

  useEffect(() => {
    setLandings(scatter(cards.length));
  }, [cards.length]);

  return (
    <div
      className="lp-pile"
      role="group"
      aria-label="Recently cooked dinners"
      data-settled={landings ? '' : undefined}
    >
      {cards.map((card, index) => {
        const to = landings?.[index];
        const style = to
          ? ({ '--x': to.x, '--y': to.y, '--r': `${to.r}deg` } as CSSProperties)
          : undefined;
        return (
          <figure key={`${index}-${card.src}`} className="lp-pile-card" data-index={index} style={style}>
            <Image
              src={card.src}
              alt={card.alt}
              width={288}
              height={288}
              className="lp-pile-photo"
              unoptimized
              priority
            />
            {card.label && (
              <figcaption className="lp-badge" data-verdict={card.verdict}>
                {card.label}
              </figcaption>
            )}
          </figure>
        );
      })}
    </div>
  );
}
