import { Footer } from '@/components/Footer';
import { SiteHeader } from '@/components/SiteHeader';
import { Hero } from '@/components/landing/Hero';
import { HowItWorks } from '@/components/landing/HowItWorks';
import { ProCompare } from '@/components/landing/ProCompare';
import { StatsSection } from '@/components/landing/StatsSection';
import { getLandingStats } from '@/lib/landing-stats';
import { getLatestMealPhotos } from '@/lib/landing-photos';
import './landing.css';

// Stats are counts only; refresh them hourly instead of on every request.
export const revalidate = 3600;

export default async function HomePage() {
  const [stats, cards] = await Promise.all([getLandingStats(), getLatestMealPhotos()]);

  return (
    <div className="lp">
      <SiteHeader variant="home" />
      <div className="lp-page">
        <main id="main-content" className="lp-main">
          <Hero cards={cards} />
          {stats && <StatsSection stats={stats} />}
          <ProCompare />
          <HowItWorks />
        </main>
      </div>
      <Footer />
    </div>
  );
}
