import { DownloadButton } from './DownloadButton';
import { SiteHeaderBar } from './SiteHeaderBar';

/** The one header every public page uses: fixed logo, download button, blurred backdrop. */
export function SiteHeader({ variant = 'page' }: { variant?: 'home' | 'page' }) {
  return (
    <SiteHeaderBar variant={variant}>
      <DownloadButton size="sm" location="header" />
    </SiteHeaderBar>
  );
}
