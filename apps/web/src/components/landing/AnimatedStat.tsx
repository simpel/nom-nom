'use client';

import NumberFlow from '@number-flow/react';
import { useEffect, useRef, useState } from 'react';

interface AnimatedStatProps {
  value: number;
  /** Milliseconds to wait after scrolling into view, to stack the rolls one after another. */
  delay?: number;
}

/** A count that rolls up from zero the first time it scrolls into view. */
export function AnimatedStat({ value, delay = 0 }: AnimatedStatProps) {
  const ref = useRef<HTMLSpanElement>(null);
  const [shown, setShown] = useState(0);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    let timer: ReturnType<typeof setTimeout> | undefined;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) return;
        timer = setTimeout(() => setShown(value), delay);
        observer.disconnect();
      },
      { threshold: 0.6 },
    );
    observer.observe(element);
    return () => {
      observer.disconnect();
      clearTimeout(timer);
    };
  }, [value, delay]);

  return (
    <span ref={ref} className="lp-stat-value">
      <NumberFlow
        value={shown}
        format={{ useGrouping: true }}
        transformTiming={{ duration: 1200, easing: 'cubic-bezier(0.22, 1, 0.36, 1)' }}
        spinTiming={{ duration: 1200, easing: 'cubic-bezier(0.22, 1, 0.36, 1)' }}
        aria-label={new Intl.NumberFormat('en').format(value)}
      />
    </span>
  );
}
