#!/usr/bin/env bash
# ==============================================================================
# Nom Nom — Local Database Seed Script
# Seeds 3 dinner parties (4 members each), 40 recipes, and 58 meals with ratings.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SEED_FILE="$WORKSPACE_ROOT/supabase/seed.sql"

# Text styles
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}  Nom Nom — Seeding Local Supabase Database${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"

# 1. Check if seed file exists
if [[ ! -f "$SEED_FILE" ]]; then
    echo -e "${RED}Error: Seed file not found at ${SEED_FILE}${NC}"
    exit 1
fi

# 2. Check if Docker container for Supabase Postgres is running
CONTAINER_NAME=$(docker ps --filter "name=supabase_db" --format "{{.Names}}" | head -n 1)

if [[ -z "$CONTAINER_NAME" ]]; then
    echo -e "${RED}Error: Supabase database container is not running.${NC}"
    echo -e "${YELLOW}Please start your local Supabase stack with:${NC}"
    echo -e "  npx supabase start"
    exit 1
fi

echo -e "Found Supabase DB container: ${GREEN}${CONTAINER_NAME}${NC}"

# 3. Check for --reset flag
if [[ "${1:-}" == "--reset" ]]; then
    echo -e "${YELLOW}Reset flag passed. Resetting database with 'supabase db reset' (this will run migrations and seed)...${NC}"
    cd "$WORKSPACE_ROOT"
    if command -v /opt/homebrew/bin/supabase >/dev/null 2>&1; then
        /opt/homebrew/bin/supabase db reset --local
    elif command -v supabase >/dev/null 2>&1; then
        supabase db reset --local
    else
        npx supabase db reset --local
    fi
else
    echo -e "Checking and applying migrations..."
    for migration in "$WORKSPACE_ROOT"/supabase/migrations/*.sql; do
        migration_file=$(basename "$migration")
        migration_version=$(echo "$migration_file" | cut -d'_' -f1)
        applied=$(docker exec -i "$CONTAINER_NAME" psql -U postgres -d postgres -t -A -c "SELECT 1 FROM supabase_migrations.schema_migrations WHERE version = '$migration_version';" 2>/dev/null || echo "")
        if [[ "$applied" != "1" ]]; then
            echo -e "  Applying migration: ${CYAN}${migration_file}${NC}..."
            docker exec -i "$CONTAINER_NAME" psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "$migration"
            docker exec -i "$CONTAINER_NAME" psql -U postgres -d postgres -c "INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('$migration_version') ON CONFLICT DO NOTHING;" 2>/dev/null || true
        fi
    done

    echo -e "Executing ${BOLD}${CYAN}supabase/seed.sql${NC} into container..."
    docker exec -i "$CONTAINER_NAME" psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "$SEED_FILE"
fi

# 4. Run verification queries to summarize seeded data
echo -e "\n${BOLD}${GREEN}✔ Database seed successfully applied!${NC}\n"
echo -e "${BOLD}Current Database Summary:${NC}"

docker exec -i "$CONTAINER_NAME" psql -U postgres -d postgres -c "
SELECT 
    p.name AS \"Dinner Party\",
    p.is_public AS \"Public\",
    COUNT(DISTINCT pm.user_id) AS \"Members\",
    COUNT(DISTINCT pf.user_id) AS \"Followers\",
    COUNT(DISTINCT mp.meal_id) AS \"Meals Eaten\"
FROM parties p
LEFT JOIN party_members pm ON pm.party_id = p.id
LEFT JOIN party_followers pf ON pf.party_id = p.id
LEFT JOIN meal_parties mp ON mp.party_id = p.id
GROUP BY p.id, p.name, p.is_public
ORDER BY \"Meals Eaten\" DESC;
"

docker exec -i "$CONTAINER_NAME" psql -U postgres -d postgres -c "
SELECT 
    (SELECT COUNT(*) FROM dishes) AS \"Total Recipes\",
    (SELECT COUNT(*) FROM meals) AS \"Total Meals\",
    (SELECT COUNT(*) FROM meal_ratings) AS \"Total Taste Ratings\",
    (SELECT MIN(eaten_on) FROM meals) AS \"Earliest Meal\",
    (SELECT MAX(eaten_on) FROM meals) AS \"Latest Meal\";
"

echo -e "${CYAN}Peak week verification (July 13–17, 2026):${NC}"
docker exec -i "$CONTAINER_NAME" psql -U postgres -d postgres -c "
SELECT 
    m.eaten_on AS \"Date\",
    d.name AS \"Dish Served\",
    d.cuisine AS \"Cuisine\",
    m.notes AS \"Notes\"
FROM meals m
JOIN dishes d ON d.id = m.dish_id
WHERE m.eaten_on BETWEEN '2026-07-13' AND '2026-07-17'
ORDER BY m.eaten_on ASC;
"

echo -e "${BOLD}${GREEN}Seed complete. You can sign into the app as 'cook@foodlog.test' to inspect all 3 parties and 40 recipes.${NC}\n"
