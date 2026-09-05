import Link from 'next/link';
import Image from 'next/image';

export function Header() {
  return (
    <header className="site-header">
      <div className="container header-inner">
        <Link href="/" className="brand-link" aria-label="Nom Nom Home">
          <Image
            src="/icon.png"
            alt=""
            width={32}
            height={32}
            className="brand-icon"
            priority
          />
          <span className="brand-name">Nom Nom</span>
        </Link>
      </div>
    </header>
  );
}
