import type { Metadata, Viewport } from 'next';
import { Inter, Newsreader, Geist, Instrument_Serif, Montserrat } from 'next/font/google';
import './globals.css';
import { cn } from "@/lib/utils";
import { Toaster } from 'sonner';

const montserratHeading = Montserrat({subsets:['latin'],variable:'--font-heading'});

const geist = Geist({subsets:['latin'],variable:'--font-sans'});

const instrumentSerif = Instrument_Serif({subsets:['latin'],weight:['400'],variable:'--font-serif'});

export const metadata: Metadata = {
  metadataBase: new URL(
    process.env.NEXT_PUBLIC_SITE_URL || 'https://www.nomnom.casa'
  ),
  title: 'Nom Nom — Dinner Diary & Recommendation Engine',
  description:
    'Nom Nom is an iOS app for tracking what you cooked, capturing honest verdicts from everyone at the table, and knowing what to cook next.',
  icons: {
    icon: '/icon.png',
    apple: '/icon.png',
  },
  openGraph: {
    title: 'Nom Nom — Dinner Diary & Recommendation Engine',
    description:
      'Keep track of what you cooked, capture honest verdicts from everyone at the table, and settle the daily question of what to make next.',
    url: 'https://www.nomnom.casa',
    siteName: 'Nom Nom',
    images: [
      {
        url: '/icon.png',
        width: 512,
        height: 512,
        alt: 'Nom Nom Icon',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#F5F7F9' },
    { media: '(prefers-color-scheme: dark)', color: '#06080C' },
  ],
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={cn( geist.variable, "font-serif", instrumentSerif.variable, montserratHeading.variable)}>
      <body>
        <a href="#main-content" className="skip-link">
          Skip to main content
        </a>
        {children}
        <Toaster />
      </body>
    </html>
  );
}
