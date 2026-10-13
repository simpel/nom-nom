/** The App Store listing. Same env var the invite page uses. */
export function appStoreUrl(): string {
  return `https://apps.apple.com/app/id${process.env.IOS_APP_ID || ''}`;
}
