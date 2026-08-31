import json, urllib.request, urllib.error, uuid, sys

API = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

fails, checks = [], []

def call(method, path, token, body=None, extra=None):
    url = API + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("apikey", ANON)
    req.add_header("Authorization", "Bearer " + token)
    req.add_header("Content-Type", "application/json")
    for k, v in (extra or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:    return e.code, json.loads(raw)
        except: return e.code, raw

def check(name, cond, detail=""):
    checks.append(name)
    if cond: print(f"  PASS  {name}")
    else:
        print(f"  FAIL  {name}   {detail}")
        fails.append(name)

def mkuser(email, pw="Passw0rd!123", meta=None):
    payload = {"email": email, "password": pw, "email_confirm": True}
    if meta: payload["user_metadata"] = meta
    st, r = call("POST", "/auth/v1/admin/users", SERVICE, payload)
    assert st in (200, 201), (st, r)
    st, tok = call("POST", "/auth/v1/token?grant_type=password", ANON,
                   {"email": email, "password": pw})
    assert st == 200, (st, tok)
    return r["id"], tok["access_token"]

tag = uuid.uuid4().hex[:8]
print("== creating users ==")
a_id, a_tok = mkuser(f"cook-{tag}@example.com", meta={"first_name": "Joel", "last_name": "Sanden"})
b_id, b_tok = mkuser(f"guest-{tag}@example.com", meta={"first_name": "Vidar", "last_name": "Nordic"})
outsider_email = f"outsider-{tag}@example.com"
o_id, o_tok = mkuser(outsider_email)
print(f"  cook={a_id[:8]} guest={b_id[:8]} outsider={o_id[:8]}")

REP = {"Prefer": "return=representation"}

print("\n== profiles auto-created by trigger with first & last name ==")
st, r = call("GET", f"/rest/v1/profiles?id=eq.{a_id}", a_tok)
check("trigger created a profile for a new auth user", st == 200 and len(r) == 1, f"{st} {r}")
check("profile has first_name and last_name populated",
      st == 200 and r[0].get("first_name") == "Joel" and r[0].get("last_name") == "Sanden", f"{r}")
check("profile has display_name derived from first and last name",
      st == 200 and r[0].get("display_name") == "Joel Sanden", f"{r}")

print("\n== cook creates dish + meal ==")
st, dish = call("POST", "/rest/v1/dishes", a_tok,
                {"owner_id": a_id, "name": "Tacos", "normalized_name": f"tacos {tag}", "tags": ["friday"]}, REP)
check("cook can insert own dish", st == 201, f"{st} {dish}")
dish_id = dish[0]["id"]

st, meal = call("POST", "/rest/v1/meals", a_tok,
                {"dish_id": dish_id, "created_by": a_id, "notes": "taco night"}, REP)
check("cook can insert meal for own dish", st == 201, f"{st} {meal}")
meal_id = meal[0]["id"]

print("\n== outsider is walled off ==")
st, r = call("GET", f"/rest/v1/meals?id=eq.{meal_id}", o_tok)
check("outsider cannot read someone else's meal", st == 200 and r == [], f"{st} {r}")
st, r = call("GET", f"/rest/v1/dishes?id=eq.{dish_id}", o_tok)
check("outsider cannot read someone else's dish", st == 200 and r == [], f"{st} {r}")
st, r = call("POST", "/rest/v1/meal_ratings", o_tok,
             {"meal_id": meal_id, "rater_id": o_id, "reaction": 0}, REP)
check("outsider cannot rate a meal they're not part of", st >= 400, f"{st} {r}")

print("\n== cook invites guest (known account) to meal ==")
st, inv = call("POST", "/rest/v1/meal_invites", a_tok,
               {"meal_id": meal_id, "inviter_id": a_id, "invitee_id": b_id}, REP)
check("cook can create meal invite", st == 201, f"{st} {inv}")

st, notes = call("GET", f"/rest/v1/notifications?select=kind,body", b_tok)
check("guest received a rating_request notification",
      st == 200 and any(n["kind"] == "rating_request" for n in notes), f"{st} {notes}")

print("\n== guest rates the meal ==")
st, r = call("POST", "/rest/v1/meal_ratings", b_tok,
             {"meal_id": meal_id, "rater_id": b_id, "reaction": 2}, REP)
check("guest can record own verdict", st == 201, f"{st} {r}")

print("\n== dinner party creation and auto-membership ==")
st, party = call("POST", "/rest/v1/parties", a_tok,
                 {"name": "Friday Dinner Club", "created_by": a_id}, REP)
check("cook can create a dinner party", st == 201, f"{st} {party}")
party_id = party[0]["id"]

st, members = call("GET", f"/rest/v1/party_members?party_id=eq.{party_id}", a_tok)
check("creator was automatically added as first party member",
      st == 200 and len(members) == 1 and members[0]["user_id"] == a_id, f"{st} {members}")

print("\n== invite guest to dinner party ==")
st, pinv = call("POST", "/rest/v1/party_invites", a_tok,
                {"party_id": party_id, "inviter_id": a_id, "invitee_email": f"guest-{tag}@example.com"}, REP)
check("party member can invite guest by email", st == 201, f"{st} {pinv}")
check("party invite resolved guest account on insert",
      st == 201 and pinv[0]["invitee_id"] == b_id, f"{st} {pinv}")

st, g_notes = call("GET", "/rest/v1/notifications?select=kind,title,body", b_tok)
check("guest received party_invite notification",
      st == 200 and any(n["kind"] == "party_invite" for n in g_notes), f"{st} {g_notes}")

print("\n== guest accepts party invite and joins ==")
st, joined = call("POST", "/rest/v1/party_members", b_tok,
                  {"party_id": party_id, "user_id": b_id}, REP)
check("guest can join party", st == 201, f"{st} {joined}")

print("\n== serve a meal to the dinner party ==")
st, dish2 = call("POST", "/rest/v1/dishes", a_tok,
                 {"owner_id": a_id, "name": "Pasta Carbonara", "normalized_name": f"carbonara {tag}", "tags": ["pasta"]}, REP)
dish2_id = dish2[0]["id"]
st, meal2 = call("POST", "/rest/v1/meals", a_tok,
                 {"dish_id": dish2_id, "created_by": a_id, "notes": "party dinner"}, REP)
meal2_id = meal2[0]["id"]

st, mp = call("POST", "/rest/v1/meal_parties", a_tok,
              {"meal_id": meal2_id, "party_id": party_id}, REP)
check("cook can serve meal to the party", st == 201, f"{st} {mp}")

st, g_meals = call("GET", f"/rest/v1/meals?id=eq.{meal2_id}", b_tok)
check("party member can read meal served to the party", st == 200 and len(g_meals) == 1, f"{st} {g_meals}")
st, g_dishes = call("GET", f"/rest/v1/dishes?id=eq.{dish2_id}", b_tok)
check("party member can read dish served to the party", st == 200 and len(g_dishes) == 1, f"{st} {g_dishes}")

st, o_meals = call("GET", f"/rest/v1/meals?id=eq.{meal2_id}", o_tok)
check("outsider cannot read meal served to the party", st == 200 and o_meals == [], f"{st} {o_meals}")

print("\n== invite unregistered email to party, then sign up ==")
future_party_email = f"futureparty-{tag}@example.com"
st, pinv_future = call("POST", "/rest/v1/party_invites", a_tok,
                       {"party_id": party_id, "inviter_id": a_id, "invitee_email": future_party_email}, REP)
check("party member can invite unregistered email", st == 201, f"{st} {pinv_future}")

fp_id, fp_tok = mkuser(future_party_email, meta={"first_name": "Future", "last_name": "Friend"})
st, fp_invs = call("GET", f"/rest/v1/party_invites?invitee_id=eq.{fp_id}", fp_tok)
check("signing up claims the pending party invite",
      st == 200 and len(fp_invs) == 1 and fp_invs[0]["party_id"] == party_id, f"{st} {fp_invs}")

print("\n== member removal and party auto-cleanup when empty ==")
# Guest removes Cook from party
st, del_cook = call("DELETE", f"/rest/v1/party_members?party_id=eq.{party_id}&user_id=eq.{a_id}", b_tok)
check("party member can remove another member", st in (200, 204), f"{st}")

# Guest leaves party
st, del_guest = call("DELETE", f"/rest/v1/party_members?party_id=eq.{party_id}&user_id=eq.{b_id}", b_tok)
check("party member can leave party", st in (200, 204), f"{st}")

# Party is now empty, verify it was deleted by cleanup trigger
st, check_party = call("GET", f"/rest/v1/parties?id=eq.{party_id}", a_tok)
check("party was automatically deleted when last member left",
      st == 200 and len(check_party) == 0, f"{st} {check_party}")

print(f"\n{len(checks)-len(fails)}/{len(checks)} passed")
if fails:
    print("FAILED: " + ", ".join(fails)); sys.exit(1)
