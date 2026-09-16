import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

// Constants
const START_DATE = new Date();
START_DATE.setFullYear(START_DATE.getFullYear() - 1); // 1 year ago
const END_DATE = new Date();

const CUISINES = [
    'Italian', 'Mexican', 'American', 'Thai', 'Indian', 
    'French', 'Japanese', 'Mediterranean', 'Nordic', 'Spanish'
];

const INGREDIENTS = [
    'chicken', 'beef', 'pork', 'fish', 'shrimp', 'tofu', 'beans',
    'rice', 'pasta', 'potatoes', 'tomatoes', 'onions', 'garlic',
    'cheese', 'cream', 'butter', 'olive oil', 'soy sauce', 'basil',
    'cilantro', 'broccoli', 'spinach', 'carrots', 'peppers'
];

const METHODS = ['baked', 'fried', 'grilled', 'roasted', 'boiled', 'sauteed', 'raw'];

// Utilities
function randomId() {
    return crypto.randomUUID();
}
function randomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}
function randomElement(arr) {
    return arr[randomInt(0, arr.length - 1)];
}
function randomElements(arr, count) {
    const shuffled = [...arr].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, count);
}
function randomDate(start, end) {
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

// Fixed UUIDs for standard users
const USERS = [
    { id: 'f917e487-1f8c-4d3c-b42a-d77f1c19bceb', email: 'cook@foodlog.test', name: 'Joel Sanden' },
    { id: 'e0000000-0000-0000-0000-000000000001', email: 'app@nomnom.casa', name: 'Test Account' },
    { id: 'a1111111-1111-1111-1111-111111111111', email: 'astrid.lind@foodlog.test', name: 'Astrid Lind' },
    { id: randomId(), email: 'member4@test.com', name: 'Member Four' },
    { id: randomId(), email: 'member5@test.com', name: 'Member Five' },
    { id: randomId(), email: 'member6@test.com', name: 'Member Six' },
    { id: randomId(), email: 'member7@test.com', name: 'Member Seven' },
    { id: randomId(), email: 'member8@test.com', name: 'Member Eight' },
];

const PARTIES = [
    { id: randomId(), name: 'The Friday Feast Club' },
    { id: randomId(), name: 'Sunday Supper Society' },
    { id: randomId(), name: 'Taco & Tapas Crew' },
    { id: randomId(), name: 'Pasta & Vino Society' },
    { id: randomId(), name: 'Nordic Hearth & Ferments' },
    { id: randomId(), name: 'Spicy Curry Fans' },
    { id: randomId(), name: 'Sushi Lovers' },
    { id: randomId(), name: 'Mediterranean Diet' },
    { id: randomId(), name: 'Burger Enthusiasts' },
    { id: randomId(), name: 'French Classics' },
];

const sql = [];

// 1. Vault Secrets (from original)
sql.push(`
do $$
begin
    if not exists (select 1 from vault.secrets where name = 'project_url') then
        perform vault.create_secret('http://kong:8000', 'project_url', 'Base URL');
    end if;
    if not exists (select 1 from vault.secrets where name = 'webhook_secret') then
        perform vault.create_secret('local-development-webhook-secret', 'webhook_secret', 'Secret');
    end if;
end $$;
`);

// 2. Users and Profiles
sql.push(`-- USERS AND PROFILES`);
for (const u of USERS) {
    const splitName = u.name.split(' ');
    const first = splitName[0];
    const last = splitName[1] || '';
    
    // We insert straight into auth.users without complicated conflicts to simplify the massive seed
    // Using simple password hash from original seed ($2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W -> nomnom-dev-password)
    sql.push(`
insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
) values (
    '00000000-0000-0000-0000-000000000000', '${u.id}', 'authenticated', 'authenticated', '${u.email}',
    '$2a$10$EJ5FcxGBJmp0rp5tMqNxTOuKOIbkcpf9NwsbYZzKOmMyhh5DnA5.W', now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"first_name": "${first}", "last_name": "${last}", "full_name": "${u.name}", "email_verified": true}'::jsonb,
    false, false
) on conflict (id) do update set email = excluded.email;
    `);

    sql.push(`
insert into public.profiles (id, first_name, last_name, display_name)
values ('${u.id}', '${first}', '${last}', '${u.name}')
on conflict (id) do nothing;
    `);
}

// 3. Recipes (10 cuisines * 10 recipes = 100)
sql.push(`-- RECIPES`);
const recipes = [];
for (const cuisine of CUISINES) {
    for (let i = 1; i <= 10; i++) {
        const rId = randomId();
        const mainIngred = randomElement(INGREDIENTS);
        const name = `${cuisine} ${METHODS[randomInt(0, METHODS.length - 1)]} ${mainIngred} ${i}`;
        const tags = [cuisine.toLowerCase(), mainIngred.toLowerCase(), 'dinner'];
        const recipeIngredients = randomElements(INGREDIENTS, randomInt(3, 7)).map(ing => ({ ingredient: ing, amount: "1" }));
        
        recipes.push({ id: rId, name, cuisine, ingredients: recipeIngredients });

        sql.push(`
insert into public.dishes (id, name, normalized_name, owner_id, is_public, cuisine, tags, ingredients, instructions)
values (
    '${rId}', 
    '${name.replace(/'/g, "''")}', 
    '${name.toLowerCase().replace(/[^a-z0-9]/g, '')}', 
    '${USERS[0].id}', 
    true, 
    '${cuisine.toLowerCase()}', 
    '{${tags.map(t => `"${t}"`).join(',')}}', 
    '${JSON.stringify(recipeIngredients)}'::jsonb,
    '{"Cook the ${mainIngred}", "Serve hot"}'
);
        `);
    }
}

// 4. Dinner Parties
sql.push(`-- PARTIES AND MEMBERS`);
const partyMembersMap = new Map(); // partyId -> array of userIds
for (const p of PARTIES) {
    sql.push(`
insert into public.parties (id, name, created_by, is_public, created_at, updated_at)
values ('${p.id}', '${p.name.replace(/'/g, "''")}', '${USERS[0].id}', true, now(), now());
    `);

    // Assign 3-6 random members to the party (including USERS[0] to guarantee the main user is in all of them)
    let membersCount = randomInt(2, 5);
    const otherUsers = USERS.slice(1);
    const members = [USERS[0].id, ...randomElements(otherUsers, membersCount).map(u => u.id)];
    partyMembersMap.set(p.id, members);

    for (const mId of members) {
        sql.push(`
insert into public.party_members (party_id, user_id)
values ('${p.id}', '${mId}') on conflict do nothing;
        `);
    }
}

// 5. Meals and Ratings
sql.push(`-- MEALS AND RATINGS`);
for (const p of PARTIES) {
    const numMeals = randomInt(20, 400);
    const members = partyMembersMap.get(p.id);

    // Give each party a "bias" towards 2-3 specific cuisines so the AI has something to pick up on
    const preferredCuisines = randomElements(CUISINES, randomInt(1, 3)).map(c => c.toLowerCase());
    
    for (let i = 0; i < numMeals; i++) {
        // Pick a recipe (bias towards preferred cuisines 70% of the time)
        let recipe;
        if (Math.random() < 0.70) {
            recipe = randomElement(recipes.filter(r => preferredCuisines.includes(r.cuisine.toLowerCase())));
        } 
        // Fallback or if filter is empty
        if (!recipe) {
            recipe = randomElement(recipes);
        }

        const mealId = randomId();
        const date = randomDate(START_DATE, END_DATE);
        
        sql.push(`
insert into public.meals (id, dish_id, created_by, eaten_on)
values ('${mealId}', '${recipe.id}', '${USERS[0].id}', '${date.toISOString()}');
        `);

        sql.push(`
insert into public.meal_parties (meal_id, party_id)
values ('${mealId}', '${p.id}');
        `);

        // Members rate the meal (0 to 5)
        for (const mId of members) {
            // If it's a preferred cuisine, they rate it higher on average
            let rating = randomInt(2, 5);
            if (preferredCuisines.includes(recipe.cuisine.toLowerCase())) {
                rating = randomInt(3, 5);
            } else {
                rating = randomInt(0, 4);
            }
            
            sql.push(`
insert into public.meal_ratings (meal_id, rater_id, reaction)
values ('${mealId}', '${mId}', ${rating});
            `);
        }
    }
}

fs.writeFileSync(path.join(process.cwd(), 'supabase', 'seed.sql'), sql.join('\n'));
console.log('Seed SQL generated successfully.');
