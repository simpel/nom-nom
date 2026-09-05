import Link from 'next/link';

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="container footer-inner">
        <div className="footer-meta">
          <span>&copy; Nom Nom. Built for iOS.</span>
        </div>

        <ul className="footer-links">
          <li>
            <Link href="/" className="footer-link">
              Home
            </Link>
          </li>
          <li>
            <Link href="/privacy" className="footer-link">
              Privacy Policy
            </Link>
          </li>
          <li>
            <a
              href="https://github.com/simpel/nom-nom"
              className="footer-link"
              target="_blank"
              rel="noopener noreferrer"
            >
              Source Code
            </a>
          </li>
        </ul>
      </div>
    </footer>
  );
}
