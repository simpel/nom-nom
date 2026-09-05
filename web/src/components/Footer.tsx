import Link from 'next/link';

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="container footer-inner">
        <div className="footer-meta">
          <span>&copy; Nom Nom</span>
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
        </ul>
      </div>
    </footer>
  );
}
