import type { Metadata } from 'next';
import { Header } from '@/components/Header';
import { Footer } from '@/components/Footer';

export const metadata: Metadata = {
  title: 'Support — Nom Nom',
  description:
    'Get help with Nom Nom: contact support, report a bug, manage your account, and find answers to common questions about sign-in, dinner parties, photos, and notifications.',
};

const SUPPORT_EMAIL = 'me@joelsanden.se';

export default function SupportPage() {
  return (
    <>
      <Header showBack />
      <main id="main-content" className="policy-page">
        <div className="container">
          <div className="policy-content">
            <header className="policy-header">
              <span className="policy-badge">Help &amp; Support</span>
              <h1 className="policy-title">Nom Nom Support</h1>
              <p className="policy-updated">
                We usually reply within 2 business days.
              </p>
            </header>

            <section className="policy-section">
              <h2>Contact us</h2>
              <p>
                Have a question, found a bug, or need help with your account?
                Email us and include your device model, iOS version, and a short
                description of what happened. Screenshots help.
              </p>
              <div className="policy-callout">
                <p>
                  Email:{' '}
                  <a href={`mailto:${SUPPORT_EMAIL}?subject=Nom%20Nom%20Support`}>
                    {SUPPORT_EMAIL}
                  </a>
                </p>
              </div>
              <p>
                You can also file bug reports and feature requests on GitHub:{' '}
                <a
                  href="https://github.com/simpel/nom-nom/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  github.com/simpel/nom-nom/issues
                </a>
                .
              </p>
            </section>

            <section className="policy-section">
              <h2>Common questions</h2>

              <h3>I didn&apos;t get my sign-in code</h3>
              <p>
                Nom Nom signs you in with a single-use six-digit code sent to
                your email. If it doesn&apos;t arrive within a minute, check your
                spam folder, make sure the address is spelled correctly, and
                request a new code. Corporate or school mail servers sometimes
                delay these messages.
              </p>

              <h3>How do I invite people to a dinner party?</h3>
              <p>
                Open a party, tap Share, and send the invite link. Anyone with
                the link can open it on their device; if they have Nom Nom
                installed it opens straight to the party, otherwise it points
                them to the App Store.
              </p>

              <h3>Where are my meal photos stored?</h3>
              <p>
                Photos you take or pick are uploaded to a private cloud storage
                bucket and are only visible to you and the members of the
                specific party a meal was served to. See our{' '}
                <a href="/privacy">Privacy Policy</a> for details.
              </p>

              <h3>I&apos;m not receiving notifications</h3>
              <p>
                Check Settings &rsaquo; Notifications &rsaquo; Nom Nom on your
                device and make sure notifications are allowed. If you recently
                signed out and back in, open the app once while connected to the
                internet so it can re-register your device.
              </p>
            </section>

            <section className="policy-section">
              <h2>Delete your account</h2>
              <p>
                You can permanently delete your account and all associated data
                from inside the app:
              </p>
              <ol className="policy-steps">
                <li>
                  Open the <strong>Nom Nom</strong> app.
                </li>
                <li>
                  Go to the <strong>Settings</strong> tab.
                </li>
                <li>
                  Select <strong>Delete Account</strong> and confirm.
                </li>
              </ol>
              <p>
                This purges your profile, meal logs, verdicts, party
                associations, and all photos from our storage. If you no longer
                have access to your device, email{' '}
                <a href={`mailto:${SUPPORT_EMAIL}?subject=Account%20deletion%20request`}>
                  {SUPPORT_EMAIL}
                </a>{' '}
                and we will erase your data manually.
              </p>
            </section>

            <section className="policy-section">
              <h2>More</h2>
              <ul>
                <li>
                  <a href="/privacy">Privacy Policy</a>
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
