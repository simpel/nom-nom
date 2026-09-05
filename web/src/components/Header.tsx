import Link from 'next/link';
import Image from 'next/image';

interface HeaderProps {
  currentPath?: string;
}

export function Header({ currentPath = '/' }: HeaderProps) {
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

        <nav aria-label="Primary Navigation">
          <ul className="nav-menu">
            <li>
              <Link
                href="/#features"
                className={`nav-link ${currentPath === '/#features' ? 'active' : ''}`}
              >
                Features
              </Link>
            </li>
            <li>
              <Link
                href="/#architecture"
                className={`nav-link ${currentPath === '/#architecture' ? 'active' : ''}`}
              >
                Architecture
              </Link>
            </li>
            <li>
              <Link
                href="/privacy"
                className={`nav-link ${currentPath === '/privacy' ? 'active' : ''}`}
                aria-current={currentPath === '/privacy' ? 'page' : undefined}
              >
                Privacy
              </Link>
            </li>
            <li>
              <a
                href="https://github.com/simpel/nom-nom"
                className="nav-link"
                target="_blank"
                rel="noopener noreferrer"
              >
                GitHub
              </a>
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}
