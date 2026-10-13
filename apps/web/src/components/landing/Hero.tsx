import type { PileCard } from '@/lib/landing-photos';
import { DownloadButton } from '@/components/DownloadButton';
import { PhotoPile } from './PhotoPile';

export function Hero({ cards }: { cards: PileCard[] }) {
  return (
    <section className="lp-hero" aria-labelledby="lp-hero-title">
      <div className="lp-hero-copy">
        <span className="lp-eyebrow">Dinner diary for any group</span>
        <h1 id="lp-hero-title" className="lp-display">
          What you cooked, and did everyone eat it?
        </h1>
        <p className="lp-lead">
          Log a dinner in a few taps, let everyone give it a score, and see
          what to cook next.
        </p>
        <div className="lp-actions">
          <DownloadButton location="hero" />
        </div>
      </div>
      <PhotoPile cards={cards} />
    </section>
  );
}
