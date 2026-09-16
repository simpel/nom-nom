const url = "http://127.0.0.1:54321/rest/v1/meals?select=*,dishes(id,name,cuisine),meal_ratings(reaction,profiles(first_name,last_name,handle)),meal_parties(parties(id,name))&id=eq.ba000000-0000-0000-0000-000000000026";
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
fetch(url, {
  headers: {
    apikey: key,
    Authorization: "Bearer " + key
  }
}).then(r => r.json()).then(console.log).catch(console.error);
