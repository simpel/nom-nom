import Image from 'next/image';
import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="minimal-screen">
      <main className="minimal-main">
        <div className="minimal-brand">
          <Image
            src="/icon.png"
            alt="Nom Nom"
            width={96}
            height={96}
            className="minimal-logo"
            priority
          />
          <h1 className="minimal-title">Nom Nom</h1>
        </div>
      </main>

      <footer className="minimal-footer">
        <Link href="/privacy" className="minimal-footer-link">
          Privacy Policy
        </Link>
      </footer>
    </div>
  );
}
