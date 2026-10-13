import type { Metadata } from 'next';
import { SiteHeader } from '@/components/SiteHeader';
import { Footer } from '@/components/Footer';

export const metadata: Metadata = {
  title: 'Support — Nom Nom',
  description:
    'Contact Nom Nom support, get help with your sign-in code, or delete your account.',
};

const SUPPORT_EMAIL = 'app@nomnom.casa';

export default function SupportPage() {
  return (
    <>
      <SiteHeader />
      <main id="main-content" className="policy-page">
        <div className="container">
          <div className="policy-content">
            <header className="policy-header">
              <h1 className="policy-title">Support</h1>
            </header>

            <section className="policy-section">
              <h2>Contact</h2>
              <p>
                Email{' '}
                <a href={`mailto:${SUPPORT_EMAIL}?subject=Nom%20Nom%20Support`}>
                  {SUPPORT_EMAIL}
                </a>{' '}
                with your device model, iOS version and what happened.
                Screenshots help.
              </p>
            </section>

            <section className="policy-section">
              <h2>No sign-in code?</h2>
              <p>
                Check your spam folder, make sure the address is spelled
                correctly, then request a new code. School and work mail servers
                can take a few minutes.
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
                Can&apos;t open the app? Email{' '}
                <a href={`mailto:${SUPPORT_EMAIL}?subject=Account%20deletion%20request`}>
                  {SUPPORT_EMAIL}
                </a>{' '}
                from the address you signed up with. What gets deleted is
                listed in the <a href="/privacy">Privacy Policy</a>.
              </p>
            </section>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
