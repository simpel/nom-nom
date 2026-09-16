import { Metadata } from "next";

type SearchParams = { [key: string]: string | string[] | undefined };

function copyFor(searchParams: SearchParams) {
  const isMeal = !!searchParams.meal_id && !searchParams.party_id;

  if (isMeal) {
    return {
      title: "You're invited to rate a meal on Nom Nom",
      description: "Someone shared a meal with you on Nom Nom. Download the app to rate it.",
      heading: "You're Invited to Rate a Meal!",
      body: "You've been invited to rate a meal on Nom Nom. If you have the app installed, this link should open automatically.",
    };
  }

  return {
    title: "Join this dinner party on Nom Nom",
    description: "Anyone with this link can view and join the dinner party. Download Nom Nom to get started.",
    heading: "You're Invited!",
    body: "You've been invited to a dinner party on Nom Nom. If you have the app installed, this link should open automatically.",
  };
}

export async function generateMetadata({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}): Promise<Metadata> {
  const { title, description } = copyFor(await searchParams);
  return {
    title,
    description,
    openGraph: {
      title,
      description,
      images: ["/icon.png"],
    },
  };
}

export default async function InvitePage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const { heading, body } = copyFor(await searchParams);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '100vh', fontFamily: 'system-ui, sans-serif', padding: '20px' }}>
      <img src="/icon.png" alt="Nom Nom Logo" style={{ width: '120px', height: '120px', borderRadius: '24px', marginBottom: '24px' }} />
      <h1 style={{ fontSize: '28px', marginBottom: '12px', textAlign: 'center' }}>{heading}</h1>
      <p style={{ maxWidth: '400px', textAlign: 'center', marginBottom: '32px', color: '#666', lineHeight: '1.5' }}>
        {body}
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
