import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Join this dinner party on Nom Nom",
  description: "Anyone with this link can view and join the dinner party. Download Nom Nom to get started.",
  openGraph: {
    title: "Join this dinner party on Nom Nom",
    description: "Anyone with this link can view and join the dinner party. Download Nom Nom to get started.",
    images: ["/icon.png"],
  },
};

export default function InvitePage() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '100vh', fontFamily: 'system-ui, sans-serif', padding: '20px' }}>
      <img src="/icon.png" alt="Nom Nom Logo" style={{ width: '120px', height: '120px', borderRadius: '24px', marginBottom: '24px' }} />
      <h1 style={{ fontSize: '28px', marginBottom: '12px', textAlign: 'center' }}>You're Invited!</h1>
      <p style={{ maxWidth: '400px', textAlign: 'center', marginBottom: '32px', color: '#666', lineHeight: '1.5' }}>
        You've been invited to a dinner party on Nom Nom. If you have the app installed, this link should open automatically.
      </p>
      
      <a 
        href={`https://apps.apple.com/app/id${process.env.IOS_APP_ID || ''}`} 
        style={{ padding: '16px 32px', backgroundColor: '#000', color: '#fff', borderRadius: '12px', textDecoration: 'none', fontWeight: 'bold', fontSize: '18px' }}
      >
        Download Nom Nom
      </a>
    </div>
  );
}
