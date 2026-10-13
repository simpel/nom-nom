import { Leaf } from 'lucide-react';

interface Feature {
  title: string;
  description: string;
  /** Marks the one feature that carries the leaf, as the health score does in the app. */
  leaf?: boolean;
}

const FREE: Feature[] = [
  { title: 'Log meals with photos', description: 'Snap the plate and note what you made.' },
  { title: 'Everyone rates the dinner', description: "Scores from Can't eat to Amazing." },
  { title: 'Dinner parties for any group', description: 'Family, friends or housemates in one shared diary.' },
  { title: 'Your recipes and meal history', description: "Everything you've cooked, in one place." },
];

const PRO: Feature[] = [
  { title: 'Health score', leaf: true, description: 'A health score for every recipe, with the reasoning, macros and flavours behind it.' },
  { title: 'Why a score is what it is', description: 'The cuisines, ingredients and history behind every rating.' },
  { title: 'Taste match', description: "See how each member's taste lines up with the group." },
  { title: 'Ratings over time', description: 'Member by member, for the whole party.' },
  { title: 'AI recipe recommendations', description: 'Picked from what your group rates highest.' },
];

function FeatureList({ features }: { features: Feature[] }) {
  return (
    <ul className="lp-features">
      {features.map((feature) => (
        <li key={feature.title}>
          <strong>
            {feature.leaf && (
              <Leaf className="lp-leaf" size={16} strokeWidth={2} aria-hidden="true" />
            )}
            {feature.title}
          </strong>
          <span>{feature.description}</span>
        </li>
      ))}
    </ul>
  );
}

export function ProCompare() {
  return (
    <section className="lp-section" aria-labelledby="lp-pro-title">
      <span className="lp-label">Nom Nom Pro</span>
      <h2 id="lp-pro-title" className="lp-heading">
        Much better with Pro
      </h2>
      <p className="lp-lead">
        The free app keeps the diary. Pro tells you why your group eats the way
        it does.
      </p>
      <div className="lp-compare">
        <div className="lp-card">
          <span className="lp-label">Free</span>
          <h3 className="lp-card-title">Keep the diary</h3>
          <FeatureList features={FREE} />
        </div>
        <div className="lp-card" data-tone="pro">
          <span className="lp-pro-mark">Pro</span>
          <h3 className="lp-card-title">Everything in Free, plus</h3>
          <FeatureList features={PRO} />
          <p className="lp-pro-note">Unlock Pro inside the app.</p>
        </div>
      </div>
    </section>
  );
}
