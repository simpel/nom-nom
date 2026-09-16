import type { Metadata } from 'next';
import { Header } from '@/components/Header';
import { Footer } from '@/components/Footer';

export const metadata: Metadata = {
  title: 'Privacy Policy — Nom Nom',
  description:
    'Privacy Policy for Nom Nom iOS application covering email authentication, photo storage, party sharing, and account deletion.',
};

export default function PrivacyPage() {
  return (
    <>
      <Header showBack />
      <main id="main-content" className="policy-page">
        <div className="container">
          <div className="policy-content">
            <header className="policy-header">
              <span className="policy-badge">Legal &amp; Transparency</span>
              <h1 className="policy-title">Privacy Policy</h1>
              <p className="policy-updated">Last updated: September 5, 2026</p>
            </header>

            <section className="policy-section">
              <h2>1. Introduction</h2>
              <p>
                Nom Nom is designed to help families and friends log what they
                cook, gather honest verdicts, and decide what to eat next. We
                believe your household dining records belong to you. Nom Nom does
                not sell your data, does not serve advertisements, and does not
                track your behavior across third-party apps or websites.
              </p>
              <div className="policy-callout">
                <p>
                  Our commitment: We collect only the minimum information
                  necessary to authenticate you, sync your meals, and enable
                  shared dinner party collaboration.
                </p>
              </div>
            </section>

            <section className="policy-section">
              <h2>2. Information We Collect</h2>
              <p>When you use Nom Nom, we process the following categories of data:</p>
              <ul>
                <li>
                  <strong>Email Address (Account Authentication):</strong> Used
                  solely to generate and deliver single-use six-digit verification
                  codes for sign-in, and to route invitations between dinner party
                  members. We do not require or store passwords.
                </li>
                <li>
                  <strong>User Content &amp; Meal Photos:</strong> Photos you choose
                  to take with your device camera or select from your photo library
                  to document a meal, along with meal titles, preparation dates,
                  and cooking notes. Photos are stored securely in private cloud
                  storage buckets.
                </li>
                <li>
                  <strong>Verdicts &amp; Taste Ratings:</strong> The rating verdicts
                  you submit for a meal (such as Loved, OK, or Not a fan). These
                  verdicts help generate recommendation rankings for you and your
                  shared parties.
                </li>
                <li>
                  <strong>Party Memberships:</strong> Records of dinner parties you
                  create or join, including member email associations.
                </li>
              </ul>
            </section>

            <section className="policy-section">
              <h2>3. How Information is Used and Shared</h2>
              <p>We use your information exclusively to provide the core functionality of Nom Nom:</p>
              <ul>
                <li>To authenticate your session and sync your meals across your devices.</li>
                <li>To calculate &ldquo;What to eat&rdquo; recommendation scores based on your household&apos;s historical preferences and recency.</li>
                <li>To share meal entries and verdicts among members of the specific Dinner Party to which a meal was served.</li>
              </ul>
              <p>
                <strong>Sharing within Parties:</strong> A meal logged in your
                private context (&ldquo;Just me&rdquo;) is visible only to you.
                When you serve a meal to a Dinner Party, all active members of
                that party can view the meal&apos;s photo, notes, and member
                verdicts. Ratings carry no party tag independently; they count
                toward a party solely when the rater is an active member and the
                meal was served to that party.
              </p>
              <p>
                We do not share, monetize, or disclose your personal data to
                advertisers, data brokers, or marketing partners.
              </p>
            </section>

            <section className="policy-section">
              <h2>4. Storage, Infrastructure, and Security</h2>
              <p>
                Nom Nom&apos;s backend services and databases are hosted on
                Supabase. Your data is stored in PostgreSQL databases protected by
                strict Row-Level Security (RLS) policies, and meal photos are
                hosted in private object storage buckets. All data transmitted
                between the Nom Nom iOS app and our servers is encrypted in
                transit using industry-standard Transport Layer Security (TLS/HTTPS).
              </p>
            </section>

            <section className="policy-section">
              <h2>5. Account Deletion and Data Erasure</h2>
              <p>
                In accordance with App Store Review Guideline 5.1.1(v) and global
                privacy standards, you have the absolute right to delete your
                account and all associated data at any time directly from within
                the application:
              </p>
              <ol className="policy-steps">
                <li>
                  Open the <strong>Nom Nom</strong> app on your iOS device.
                </li>
                <li>
                  Navigate to the <strong>Settings</strong> tab.
                </li>
                <li>
                  Select <strong>Delete Account</strong> and confirm the action.
                </li>
              </ol>
              <div className="policy-callout">
                <p>
                  What happens when you delete your account: Our server
                  immediately purges all database rows linked to your user identity
                  (profile, meal logs, verdicts, and party associations) and
                  permanently deletes all photo files stored in our cloud buckets
                  associated with your meals. Other dinner party members retain
                  their own separate logs.
                </p>
              </div>
              <p>
                If you no longer have access to your iOS device or require manual
                assistance with data erasure, you may submit a deletion request
                directly by emailing{' '}
                <a href="mailto:me@joelsanden.se">me@joelsanden.se</a>.
              </p>
            </section>

            <section className="policy-section">
              <h2>6. Children&apos;s Privacy</h2>
              <p>
                Nom Nom is designed for general audiences and household meal
                planning. Every user account requires an email address. We do not
                knowingly collect personal data from children under the age of 13
                without appropriate parental consent.
              </p>
            </section>

            <section className="policy-section">
              <h2>7. Changes to This Policy</h2>
              <p>
                We may update this Privacy Policy from time to time as features
                evolve. When changes occur, the updated policy will be published
                at this URL with a revised &ldquo;Last updated&rdquo; date.
              </p>
            </section>

            <section className="policy-section">
              <h2>8. Contact &amp; Inquiries</h2>
              <p>
                If you have questions regarding this Privacy Policy, your
                personal data, or wish to exercise data rights under GDPR or CCPA,
                you can reach out via:
              </p>
              <ul>
                <li>
                  Email:{' '}
                  <a href="mailto:me@joelsanden.se">me@joelsanden.se</a>
                </li>
                <li>
                  GitHub Issues:{' '}
                  <a
                    href="https://github.com/simpel/nom-nom/issues"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    github.com/simpel/nom-nom/issues
                  </a>
                </li>
                <li>Maintainer: Joel Sandén</li>
              </ul>
            </section>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
