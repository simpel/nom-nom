export function MealCardPreview() {
  return (
    <div className="showcase-wrapper">
      <div className="preview-card" role="region" aria-label="Nom Nom Meal Card Preview">
        <div className="preview-header">
          <span className="preview-status">MEAL LOG &bull; DINNER</span>
          <span className="preview-context">Dinner Party (4 members)</span>
        </div>

        <div className="preview-body">
          <div className="preview-meta-row">
            <span className="preview-date">Friday, September 4</span>
          </div>
          <h2 className="preview-dish-title">Crispy Fish Tacos with Lime Crema</h2>
          <p className="preview-dish-notes">
            Quick cabbage slaw, fresh cilantro, warm corn tortillas, and pickled onions. Cooked in 25 minutes.
          </p>

          <div className="preview-verdicts-section">
            <div className="verdict-header-row">
              <span className="verdict-section-title">Table Verdicts</span>
              <span className="verdict-count">3 ratings recorded</span>
            </div>

            <div className="verdict-grid">
              <div className="verdict-pill loved">
                <span className="verdict-person">Joel</span>
                <span className="verdict-label">Loved</span>
              </div>
              <div className="verdict-pill loved">
                <span className="verdict-person">Sofia</span>
                <span className="verdict-label">Loved</span>
              </div>
              <div className="verdict-pill ok">
                <span className="verdict-person">Leo</span>
                <span className="verdict-label">OK</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
