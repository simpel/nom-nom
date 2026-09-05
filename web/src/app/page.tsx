import Link from 'next/link';
import { Header } from '@/components/Header';
import { Footer } from '@/components/Footer';
import { MealCardPreview } from '@/components/MealCardPreview';

const FEATURES = [
  {
    num: '01',
    title: 'The Diary (Meal Log)',
    text: 'Log dishes with camera or library photography, notes, and the date cooked. The dish catalogue stays consistent across occasions without duplicating recipes or ingredients.',
  },
  {
    num: '02',
    title: 'Flat Dinner Parties',
    text: 'Eat with different groups? Parties are flat and equal. Invite family members, housemates, or dinner clubs by email. Everyone has an equal voice, with no host or admin privileges.',
  },
  {
    num: '03',
    title: 'The Calendar View',
    text: 'A comprehensive month grid showing daily food photos and color-coded status indicators. Easily review your cooking rhythm, notice gaps, or add a meal straight onto any date.',
  },
  {
    num: '04',
    title: 'What to Eat Next',
    text: "An intelligent recommendation engine that ranks your family's favorite dishes. It factors in taste history, recency of cooking, preparation effort, and current party preferences.",
  },
];

const PILLARS = [
  {
    title: 'Passwordless Auth',
    desc: 'Sign in with a single-use six-digit code emailed to your address. No passwords to leak, and no third-party social tracker SDKs embedded in the app.',
  },
  {
    title: 'Row-Level Security',
    desc: 'Meals logged to "Just me" are visible only to you. Meals served to a party are visible strictly to active members of that party via verified Postgres security policies.',
  },
  {
    title: 'Complete Data Deletion',
    desc: 'Delete your account anytime directly in Settings. Deletion immediately removes your account record, party memberships, verdicts, and deletes all photo files from cloud storage.',
  },
];

export default function HomePage() {
  return (
    <>
      <Header currentPath="/" />
      <main id="main-content">
        {/* Hero Section */}
        <section className="hero" id="overview">
          <div className="container">
            <div className="hero-pill">
              <span className="hero-pill-dot" aria-hidden="true" />
              <span>iOS Application &bull; Swift &amp; Supabase</span>
            </div>

            <h1 className="hero-title">
              A shared dinner diary and recommendation engine.
            </h1>

            <p className="hero-subtitle">
              Keep track of what you cooked, capture honest verdicts from everyone
              at the table, and settle the daily question of what to make next. No
              ads, no trackers, and no passwords.
            </p>

            <div className="hero-actions">
              <Link href="/privacy" className="btn btn-primary">
                Privacy Policy
              </Link>
              <a
                href="https://github.com/simpel/nom-nom"
                className="btn btn-secondary"
                target="_blank"
                rel="noopener noreferrer"
              >
                <span>View on GitHub</span>
              </a>
              <a href="#features" className="btn btn-link">
                Explore Features &darr;
              </a>
            </div>

            {/* UI Showcase Preview Card */}
            <MealCardPreview />
          </div>
        </section>

        {/* Features Section */}
        <section className="features-section" id="features">
          <div className="container">
            <div className="section-heading">
              <div className="section-tag">Core Capabilities</div>
              <h2 className="section-title">
                Built around how households actually eat.
              </h2>
              <p className="section-desc">
                Traditional recipe apps are bloated with blog posts and arbitrary
                ratings. Nom Nom focuses on real meals cooked at home and what the
                people who ate them thought.
              </p>
            </div>

            <div className="features-grid">
              {FEATURES.map((feature) => (
                <article key={feature.num} className="feature-card">
                  <span className="feature-num">{feature.num}</span>
                  <h3 className="feature-title">{feature.title}</h3>
                  <p className="feature-text">{feature.text}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* Architecture & Privacy Section */}
        <section className="architecture-section" id="architecture">
          <div className="architecture-inner">
            <div className="section-heading">
              <div className="section-tag">Privacy &amp; Foundation</div>
              <h2 className="section-title">
                Honest architecture. Your food data stays yours.
              </h2>
              <p className="section-desc">
                Nom Nom is engineered from the ground up to respect your time and
                data.
              </p>
            </div>

            <div className="pillars-list">
              {PILLARS.map((pillar) => (
                <div key={pillar.title} className="pillar-item">
                  <h3 className="pillar-title">{pillar.title}</h3>
                  <p className="pillar-desc">{pillar.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
