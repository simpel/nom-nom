'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useEffect, useState, type ReactNode } from 'react';

interface SiteHeaderBarProps {
  /**
   * `home`: the download button folds down from above the top edge only once
   * the hero's own download button has scrolled out of view.
   * `page`: every other page, where the button is always visible.
   */
  variant: 'home' | 'page';
  /** The download button, passed in so the App Store URL is resolved on the server. */
  children: ReactNode;
}

export function SiteHeaderBar({ variant, children }: SiteHeaderBarProps) {
  const [pastHero, setPastHero] = useState(false);

  useEffect(() => {
    if (variant !== 'home') return;
    const heroAction = document.querySelector('.lp-hero .lp-button');
    if (!heroAction) return;

    const observer = new IntersectionObserver(([entry]) => {
      // Past it (above the viewport), not merely below the fold on load.
      setPastHero(!entry.isIntersecting && entry.boundingClientRect.top < 0);
    });
    observer.observe(heroAction);
    return () => observer.disconnect();
  }, [variant]);

  const showAction = variant === 'page' || pastHero;

  return (
    <header className="lp-nav" data-variant={variant}>
      <div className="lp-nav-inner">
        <Link href="/" className="lp-brand" aria-label="Nom Nom home">
          <Image
            src="/icon.png"
            alt=""
            width={32}
            height={32}
            className="lp-brand-icon"
            priority
          />
          <span className="lp-brand-name">Nom Nom</span>
        </Link>
        <div
          className="lp-nav-action"
          data-visible={showAction}
          inert={!showAction}
        >
          {children}
        </div>
      </div>
    </header>
  );
}
