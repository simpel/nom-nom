import type { Metadata } from 'next';
import { SiteHeader } from '@/components/SiteHeader';
import { Footer } from '@/components/Footer';

export const metadata: Metadata = {
  title: 'Privacy Policy — Nom Nom',
  description:
    'What Nom Nom collects, who processes it, who can see it, and how to delete it.',
};

const CONTACT_EMAIL = 'app@nomnom.casa';

export default function PrivacyPage() {
  return (
    <>
      <SiteHeader />
      <main id="main-content" className="policy-page">
        <div className="container">
          <div className="policy-content">
            <header className="policy-header">
              <h1 className="policy-title">Privacy Policy</h1>
              <p className="policy-updated">Last updated: October 13, 2026</p>
            </header>

            <section className="policy-section">
              <p>
                Nom Nom is a dinner diary for groups. We don&apos;t sell your
                data, show ads, or track you across other apps and websites.
                The app has no analytics or advertising SDKs.
              </p>
            </section>

            <section className="policy-section">
              <h2>What we collect</h2>
              <ul>
                <li>
                  <strong>Account:</strong> your email address (or the address
                  Apple gives us if you use Sign in with Apple, which can be a
                  private relay address), your name if you share it, and the
                  display name you choose. There are no passwords: you sign in
                  with Apple or a one-time code sent by email.
                </li>
                <li>
                  <strong>What you log:</strong> meals and recipes, notes, dates,
                  your ratings, and the photos you take or pick. The camera and
                  photo library are only used when you choose to add a photo.
                </li>
                <li>
                  <strong>Dinner parties:</strong> the parties you create or
                  join, their members, and the email addresses you invite.
                </li>
                <li>
                  <strong>Notifications:</strong> a device token, only if you
                  allow notifications.
                </li>
                <li>
                  <strong>Subscription:</strong> whether you have Nom Nom Pro.
                  Payment itself is handled by Apple.
                </li>
              </ul>
            </section>

            <section className="policy-section">
              <h2>How we use it</h2>
              <ul>
                <li>To sign you in and sync your diary across your devices.</li>
                <li>To share meals and ratings with the parties you serve them to.</li>
                <li>
                  To suggest what to cook, read recipes from photos, score
                  recipes for health, write taste insights and generate meal
                  photos (see providers below).
                </li>
                <li>To send invites and, if you allow it, push notifications.</li>
              </ul>
            </section>

            <section className="policy-section">
              <h2>Who sees it</h2>
              <p>
                A meal you log as &ldquo;Just me&rdquo; is visible only to you.
                When you serve a meal to a dinner party, every active member of
                that party can see its photo, notes and ratings.
              </p>
            </section>

            <section className="policy-section">
              <h2>Providers that process your data</h2>
              <p>We use these services to run Nom Nom, and only for that:</p>
              <ul>
                <li>
                  <strong>Supabase:</strong> database, sign-in and private photo
                  storage.
                </li>
                <li>
                  <strong>AI providers, through Vercel AI Gateway:</strong>{' '}
                  photos you scan of a recipe, and recipe, meal and rating
                  information, to produce the features above.
                </li>
                <li>
                  <strong>Resend:</strong> delivers invite emails. It receives
                  the invited email address, the inviter&apos;s name and the name
                  of the party or meal.
                </li>
                <li>
                  <strong>Apple:</strong> Sign in with Apple, push notifications
                  and payments.
                </li>
                <li>
                  <strong>RevenueCat:</strong> manages Nom Nom Pro subscriptions.
                </li>
              </ul>
              <p>
                Data is encrypted in transit (HTTPS). Access to rows is
                restricted by database access rules, and photos live in private
                storage.
              </p>
            </section>

            <section className="policy-section">
              <h2>Delete your account</h2>
              <ol className="policy-steps">
                <li>
                  In <strong>Nom Nom</strong>, open the <strong>⋯</strong> menu and
                  choose <strong>My profile</strong>.
                </li>
                <li>
                  Scroll to the bottom, choose <strong>Delete account</strong> and
                  confirm.
                </li>
              </ol>
              <p>
                This permanently deletes your account, profile, meals, ratings,
                party memberships and the photos stored with your meals. Other
                dinner party members keep their own food logs. Can&apos;t open
                the app? Email{' '}
                <a href={`mailto:${CONTACT_EMAIL}?subject=Account%20deletion%20request`}>
                  {CONTACT_EMAIL}
                </a>{' '}
                from your account address.
              </p>
            </section>

            <section className="policy-section">
              <h2>Children</h2>
              <p>
                Nom Nom is not directed at children under 13, and we don&apos;t
                knowingly collect their data. Every account needs an email
                address or an Apple ID.
              </p>
            </section>

            <section className="policy-section">
              <h2>Changes and contact</h2>
              <p>
                If this policy changes, the new version goes on this page with a
                new date. Questions or data requests:{' '}
                <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
              </p>
            </section>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
