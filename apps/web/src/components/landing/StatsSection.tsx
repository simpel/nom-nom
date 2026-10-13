import type { LandingStats } from '@/lib/landing-stats';
import { AnimatedStat } from './AnimatedStat';

/** Gap between one number starting to roll and the next. */
const STAGGER_MS = 450;

/** Three stat boxes. Rendered only when the counts could be read. */
export function StatsSection({ stats }: { stats: LandingStats }) {
  const items = [
    { label: 'Meals logged', value: stats.meals },
    { label: 'Dinner parties', value: stats.parties },
    { label: 'Ratings given', value: stats.ratings },
  ];

  return (
    <section className="lp-stats" aria-label="Nom Nom in numbers">
      {items.map((item, index) => (
        <div key={item.label} className="lp-card lp-stat">
          <span className="lp-label">{item.label}</span>
          <AnimatedStat value={item.value} delay={index * STAGGER_MS} />
        </div>
      ))}
    </section>
  );
}
