/** Reaction steps of the sample group score, in order, with their share. */
const SEGMENTS = [
  { verdict: 'meh', share: 1 },
  { verdict: 'good', share: 2 },
  { verdict: 'great', share: 3 },
  { verdict: 'amazing', share: 2 },
] as const;

function LogPreview() {
  return (
    <div className="lp-field">
      <span className="lp-field-label">What did you cook?</span>
      <span className="lp-field-value">Slow-cooked ragù</span>
    </div>
  );
}

function RatePreview() {
  return (
    <div className="lp-mini">
      <div className="lp-mini-row">
        <span className="lp-mini-score">
          <strong>88</strong> Great
        </span>
        <span className="lp-avatars" aria-hidden="true">
          {['AB', 'JS', 'ML'].map((initials) => (
            <span key={initials} className="lp-avatar">
              {initials}
            </span>
          ))}
        </span>
      </div>
      <div
        className="lp-bar"
        role="img"
        aria-label="How the group scored the dinner"
      >
        {SEGMENTS.map((segment) => (
          <span
            key={segment.verdict}
            data-verdict={segment.verdict}
            style={{ flexGrow: segment.share }}
          />
        ))}
      </div>
      <span className="lp-caption">3 of 3 rated</span>
    </div>
  );
}

function NextPreview() {
  const rows = [
    { name: 'Slow-cooked ragù', verdict: 'amazing', label: 'Amazing', fill: 96 },
    { name: 'Green curry', verdict: 'great', label: 'Great', fill: 82 },
  ] as const;
  return (
    <div className="lp-mini">
      {rows.map((row) => (
        <div key={row.name} className="lp-mini-stack">
          <div className="lp-mini-row">
            <span>{row.name}</span>
            <span className="lp-badge" data-verdict={row.verdict}>
              {row.label}
            </span>
          </div>
          <div className="lp-bar lp-bar-thin" role="presentation">
            <span style={{ width: `${row.fill}%` }} />
          </div>
        </div>
      ))}
    </div>
  );
}

const STEPS = [
  {
    title: '1. Log a meal',
    preview: <LogPreview />,
    text: 'Snap the plate and note what you made. It takes less than a minute.',
  },
  {
    title: '2. Rate it together',
    preview: <RatePreview />,
    text: "Everyone scores the dinner, from Can't eat to Amazing.",
  },
  {
    title: '3. Know what to cook next',
    preview: <NextPreview />,
    text: 'See which dinners your group asks for again.',
  },
];

export function HowItWorks() {
  return (
    <section id="how-it-works" className="lp-section" aria-labelledby="lp-how-title">
      <span className="lp-label">How it works</span>
      <h2 id="lp-how-title" className="lp-heading">
        From the plate to the next plan
      </h2>
      <div className="lp-steps">
        {STEPS.map((step) => (
          <div key={step.title} className="lp-card">
            <h3 className="lp-card-title">{step.title}</h3>
            <div className="lp-preview">{step.preview}</div>
            <p className="lp-step-text">{step.text}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
