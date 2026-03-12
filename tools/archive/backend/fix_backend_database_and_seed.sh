#!/bin/bash
set -euo pipefail

echo "starting backend repair + database bootstrap..."

if [ ! -d "app" ]; then
  echo "error: run this from inside the backend folder"
  exit 1
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
backend_dir="$(pwd)"
project_root="$(cd .. && pwd)"
root_env="${project_root}/.env"
backend_env="${backend_dir}/.env"
db_file="${backend_dir}/app.db"
backup_dir="${backend_dir}/backups/${timestamp}"

mkdir -p "${backup_dir}"

echo "checking critical backend files..."

critical_files=(
  "app/main.py"
  "app/core/config.py"
  "app/core/security.py"
  "app/db/base.py"
  "app/db/init_db.py"
  "app/db/session.py"
  "app/models/__init__.py"
  "app/models/user.py"
  "app/models/restaurant.py"
  "app/models/experience.py"
  "app/repositories/user_repository.py"
  "app/repositories/restaurant_repository.py"
  "app/repositories/experience_repository.py"
  "app/services/auth_service.py"
  "app/services/onboarding_service.py"
  "app/services/experience_service.py"
  "app/services/recommendation_service.py"
  "app/api/router.py"
)

for file in "${critical_files[@]}"; do
  if [ ! -f "${file}" ]; then
    echo "error: missing critical file ${file}"
    exit 1
  fi

  if [ ! -s "${file}" ]; then
    echo "error: critical file exists but is empty: ${file}"
    exit 1
  fi
done

echo "critical files look present and non-empty"

if [ -f "${db_file}" ]; then
  db_size="$(wc -c < "${db_file}" | tr -d ' ')"
  echo "current app.db size: ${db_size} bytes"

  if [ "${db_size}" -eq 0 ]; then
    echo "app.db is zero bytes, removing broken file"
    rm -f "${db_file}"
  else
    cp "${db_file}" "${backup_dir}/app.db.bak"
    echo "database backup created at ${backup_dir}/app.db.bak"
  fi
fi

if [ ! -f "${root_env}" ]; then
  echo "root .env missing, creating one"

  if [ -f "${backend_env}" ] && [ -s "${backend_env}" ]; then
    cp "${backend_env}" "${root_env}"
    echo "copied backend .env to repo root"
  else
    cat > "${root_env}" <<'EOF'
DATABASE_URL=sqlite:///./app.db
JWT_SECRET_KEY=dev-secret-key-change-me
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=120
BACKEND_CORS_ORIGINS=["http://localhost:5173","http://127.0.0.1:5173"]
EOF
    echo "created default repo-root .env"
  fi
else
  echo "root .env already exists"
fi

if [ ! -f "${backend_env}" ]; then
  cp "${root_env}" "${backend_env}"
  echo "created backend .env mirror for convenience"
fi

if ! grep -q "from app.db.init_db import init_db" app/main.py; then
  cp app/main.py "${backup_dir}/main.py.bak"
  python - <<'PY'
from pathlib import Path

path = Path("app/main.py")
content = path.read_text()

if "from app.db.init_db import init_db" not in content:
    content = content.replace(
        "from app.core.config import settings\n",
        "from app.core.config import settings\nfrom app.db.init_db import init_db\n",
    )

if "@app.on_event(\"startup\")" not in content:
    marker = "app.add_middleware(\n"
    startup_block = '''
@app.on_event("startup")
def on_startup() -> None:
    init_db()

'''
    content = content.replace(marker, startup_block + marker, 1)

path.write_text(content)
PY
  echo "patched app/main.py to auto-create tables on startup"
else
  echo "app/main.py already initializes database on startup"
fi

cp app/db/seed.py "${backup_dir}/seed.py.bak" 2>/dev/null || true

cat > app/db/seed.py <<'PY'
from app.db.seed_real_wolfville import seed_db

if __name__ == "__main__":
    seed_db()
PY

cat > app/db/seed_real_wolfville.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass, field

from sqlalchemy.orm import Session

from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models.restaurant import MenuItem, Restaurant, Tag


@dataclass
class MenuSeed:
    name: str
    category: str
    price: float | None
    description: str
    is_signature: bool = False
    tags: list[tuple[str, str]] = field(default_factory=list)


@dataclass
class RestaurantSeed:
    name: str
    description: str
    city: str
    price_tier: str
    atmosphere: str
    pace: str
    social_style: str
    serves_alcohol: bool
    tags: list[tuple[str, str]]
    menu_items: list[MenuSeed]


PLACEHOLDER_NAMES = {
    "Luna Trattoria",
    "North End Social",
    "Campus Quick Bowl",
}


RESTAURANTS: list[RestaurantSeed] = [
    RestaurantSeed(
        name="Troy Restaurant & Grill",
        description="Mediterranean and Turkish spot suitable for shared plates, dinner, and date-night meals.",
        city="Wolfville",
        price_tier="$$$",
        atmosphere="warm lively mediterranean",
        pace="leisurely",
        social_style="group",
        serves_alcohol=True,
        tags=[
            ("mediterranean", "cuisine"),
            ("turkish", "cuisine"),
            ("shared-plates", "style"),
            ("date-night", "occasion"),
            ("lively", "atmosphere"),
        ],
        menu_items=[
            MenuSeed("mixed meze platter", "dish", 18.0, "representative shared starter for groups", True, [("shared-plates", "style")]),
            MenuSeed("chicken shawarma plate", "dish", 24.0, "representative savory main", True, [("mediterranean", "cuisine")]),
            MenuSeed("house wine", "drink", 11.0, "representative glass-pour wine", False, [("wine", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Paddy's Brewpub & Rosie's Family Restaurant",
        description="Irish-style brewpub and family restaurant with pub food, beer, and a social atmosphere.",
        city="Wolfville",
        price_tier="$$",
        atmosphere="casual lively pub",
        pace="moderate",
        social_style="group",
        serves_alcohol=True,
        tags=[
            ("irish-pub", "cuisine"),
            ("brewpub", "venue"),
            ("beer", "drinks"),
            ("group-friendly", "social"),
            ("comfort-food", "style"),
        ],
        menu_items=[
            MenuSeed("fish and chips", "dish", 21.0, "representative pub classic", True, [("comfort-food", "style")]),
            MenuSeed("pub burger", "dish", 19.0, "representative casual main", False, [("group-friendly", "social")]),
            MenuSeed("house lager", "drink", 8.0, "representative draft beer", True, [("beer", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Juniper Food + Wine",
        description="Elevated seasonal dining with strong wine focus and polished dinner service.",
        city="Wolfville",
        price_tier="$$$",
        atmosphere="refined intimate upscale",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        tags=[
            ("seasonal", "cuisine"),
            ("wine", "drinks"),
            ("upscale", "atmosphere"),
            ("date-night", "occasion"),
            ("fine-dining", "venue"),
        ],
        menu_items=[
            MenuSeed("seasonal pasta", "dish", 28.0, "representative seasonal entrée", True, [("seasonal", "cuisine")]),
            MenuSeed("local fish feature", "dish", 34.0, "representative chef-driven seafood main", True, [("fine-dining", "venue")]),
            MenuSeed("nova scotia white wine", "drink", 13.0, "representative local wine pairing", True, [("wine", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="The Library Pub",
        description="Long-running pub on Main Street with approachable food, drinks, and student-friendly energy.",
        city="Wolfville",
        price_tier="$$",
        atmosphere="cozy lively pub",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        tags=[
            ("pub", "venue"),
            ("beer", "drinks"),
            ("student-friendly", "social"),
            ("casual", "atmosphere"),
        ],
        menu_items=[
            MenuSeed("chicken wings", "dish", 17.0, "representative shareable pub plate", True, [("pub", "venue")]),
            MenuSeed("club sandwich", "dish", 16.0, "representative casual lunch option", False, [("casual", "atmosphere")]),
            MenuSeed("local draft pint", "drink", 8.5, "representative local beer", True, [("beer", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Joe's Food Emporium",
        description="Casual downtown food spot with sandwiches, comfort-leaning mains, and broad appeal.",
        city="Wolfville",
        price_tier="$$",
        atmosphere="casual relaxed downtown",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        tags=[
            ("sandwiches", "cuisine"),
            ("comfort-food", "style"),
            ("casual", "atmosphere"),
            ("downtown", "venue"),
        ],
        menu_items=[
            MenuSeed("turkey club", "dish", 16.0, "representative deli-style sandwich", True, [("sandwiches", "cuisine")]),
            MenuSeed("soup and sandwich combo", "dish", 15.0, "representative lunch combination", False, [("comfort-food", "style")]),
            MenuSeed("craft cider", "drink", 8.5, "representative canned local cider", False, [("cider", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="The Church Brewing Company",
        description="Brewery venue with social energy, beer program, and casual food pairing well with groups.",
        city="Wolfville",
        price_tier="$$",
        atmosphere="lively brewery social",
        pace="moderate",
        social_style="group",
        serves_alcohol=True,
        tags=[
            ("brewery", "venue"),
            ("beer", "drinks"),
            ("group-friendly", "social"),
            ("night-out", "occasion"),
        ],
        menu_items=[
            MenuSeed("brewery burger", "dish", 20.0, "representative brewery main", True, [("group-friendly", "social")]),
            MenuSeed("soft pretzel board", "dish", 14.0, "representative share plate", False, [("brewery", "venue")]),
            MenuSeed("house ipa", "drink", 8.5, "representative brewery pour", True, [("beer", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Lightfoot & Wolfville",
        description="Winery dining destination suited to scenic outings, wine-first experiences, and slower meals.",
        city="Wolfville",
        price_tier="$$$",
        atmosphere="scenic refined winery",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        tags=[
            ("winery", "venue"),
            ("wine", "drinks"),
            ("scenic", "atmosphere"),
            ("date-night", "occasion"),
            ("special-occasion", "occasion"),
        ],
        menu_items=[
            MenuSeed("charcuterie board", "dish", 26.0, "representative wine-pairing board", True, [("winery", "venue")]),
            MenuSeed("seasonal flatbread", "dish", 22.0, "representative winery kitchen offering", False, [("scenic", "atmosphere")]),
            MenuSeed("estate tasting flight", "drink", 18.0, "representative wine flight", True, [("wine", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Blomidon Inn",
        description="Historic inn dining destination suited to quieter dinners and polished service.",
        city="Wolfville",
        price_tier="$$$",
        atmosphere="historic quiet refined",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        tags=[
            ("inn-dining", "venue"),
            ("quiet", "atmosphere"),
            ("historic", "atmosphere"),
            ("special-occasion", "occasion"),
        ],
        menu_items=[
            MenuSeed("seafood entrée", "dish", 33.0, "representative inn dinner feature", True, [("special-occasion", "occasion")]),
            MenuSeed("garden salad", "dish", 14.0, "representative lighter starter", False, [("quiet", "atmosphere")]),
            MenuSeed("wine pairing", "drink", 14.0, "representative dinner wine option", False, [("wine", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="JEJU Restaurant",
        description="Asian-inspired dining option suited to dinner outings and flavor-driven meals.",
        city="Wolfville",
        price_tier="$$",
        atmosphere="modern cozy asian",
        pace="moderate",
        social_style="friends",
        serves_alcohol=False,
        tags=[
            ("asian", "cuisine"),
            ("dinner", "occasion"),
            ("cozy", "atmosphere"),
        ],
        menu_items=[
            MenuSeed("rice bowl", "dish", 18.0, "representative flavor-forward bowl", True, [("asian", "cuisine")]),
            MenuSeed("dumpling plate", "dish", 12.0, "representative shared appetizer", False, [("friends", "social")]),
            MenuSeed("sparkling yuzu soda", "drink", 5.5, "representative non-alcoholic house drink", False, [("non-alcoholic", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Li's Wok & Grill",
        description="Quick Asian takeout and casual dine-in option for affordable, convenient meals.",
        city="Wolfville",
        price_tier="$",
        atmosphere="casual quick takeout",
        pace="fast",
        social_style="solo",
        serves_alcohol=False,
        tags=[
            ("asian", "cuisine"),
            ("takeout", "venue"),
            ("quick-bite", "style"),
            ("budget-friendly", "style"),
        ],
        menu_items=[
            MenuSeed("fried rice combo", "dish", 13.0, "representative quick combo meal", True, [("quick-bite", "style")]),
            MenuSeed("wok noodles", "dish", 14.0, "representative fast noodle option", False, [("asian", "cuisine")]),
            MenuSeed("iced tea", "drink", 3.0, "representative takeout beverage", False, [("non-alcoholic", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Charts Cafe",
        description="Small café and bakery-style stop for coffee, lunch, and low-pressure meetups.",
        city="Wolfville",
        price_tier="$",
        atmosphere="cozy cafe relaxed",
        pace="slow",
        social_style="solo",
        serves_alcohol=False,
        tags=[
            ("cafe", "venue"),
            ("bakery", "cuisine"),
            ("coffee", "drinks"),
            ("study-friendly", "social"),
        ],
        menu_items=[
            MenuSeed("quiche slice", "dish", 9.5, "representative lunch counter option", True, [("cafe", "venue")]),
            MenuSeed("muffin", "dish", 4.0, "representative baked item", False, [("bakery", "cuisine")]),
            MenuSeed("latte", "drink", 5.0, "representative espresso beverage", True, [("coffee", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Just Us! Coffee Roasters Coffeehouse",
        description="Coffeehouse stop for coffee, casual conversation, and slower daytime visits.",
        city="Wolfville",
        price_tier="$",
        atmosphere="community coffeehouse relaxed",
        pace="slow",
        social_style="friends",
        serves_alcohol=False,
        tags=[
            ("coffeehouse", "venue"),
            ("coffee", "drinks"),
            ("casual", "atmosphere"),
            ("community", "social"),
        ],
        menu_items=[
            MenuSeed("breakfast sandwich", "dish", 8.5, "representative quick breakfast item", False, [("coffeehouse", "venue")]),
            MenuSeed("cookie", "dish", 3.5, "representative snack item", False, [("casual", "atmosphere")]),
            MenuSeed("drip coffee", "drink", 3.0, "representative brewed coffee", True, [("coffee", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="T.A.N. Coffee",
        description="Specialty coffee venue suited to quieter solo visits, studying, and short meetups.",
        city="Wolfville",
        price_tier="$",
        atmosphere="minimal quiet specialty-coffee",
        pace="slow",
        social_style="solo",
        serves_alcohol=False,
        tags=[
            ("specialty-coffee", "venue"),
            ("coffee", "drinks"),
            ("quiet", "atmosphere"),
            ("study-friendly", "social"),
        ],
        menu_items=[
            MenuSeed("croissant", "dish", 4.5, "representative pastry", False, [("bakery", "cuisine")]),
            MenuSeed("avocado toast", "dish", 10.0, "representative light café meal", False, [("quiet", "atmosphere")]),
            MenuSeed("flat white", "drink", 5.0, "representative specialty coffee", True, [("coffee", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="The Real Scoop Ice Cream & Espresso Shop",
        description="Dessert and espresso stop suited to quick sweet outings and casual walks downtown.",
        city="Wolfville",
        price_tier="$",
        atmosphere="fun casual dessert",
        pace="fast",
        social_style="friends",
        serves_alcohol=False,
        tags=[
            ("dessert", "cuisine"),
            ("ice-cream", "cuisine"),
            ("espresso", "drinks"),
            ("quick-bite", "style"),
        ],
        menu_items=[
            MenuSeed("waffle cone", "dish", 6.0, "representative ice cream order", True, [("dessert", "cuisine")]),
            MenuSeed("ice cream sandwich", "dish", 7.5, "representative sweet treat", False, [("ice-cream", "cuisine")]),
            MenuSeed("espresso", "drink", 3.5, "representative espresso shot", False, [("espresso", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Perkin's Cafe",
        description="Simple local café for breakfast, coffee, and low-key daytime dining.",
        city="Wolfville",
        price_tier="$",
        atmosphere="small local casual",
        pace="slow",
        social_style="solo",
        serves_alcohol=False,
        tags=[
            ("cafe", "venue"),
            ("breakfast", "occasion"),
            ("coffee", "drinks"),
            ("local-favorite", "social"),
        ],
        menu_items=[
            MenuSeed("breakfast plate", "dish", 11.0, "representative breakfast meal", True, [("breakfast", "occasion")]),
            MenuSeed("bagel with cream cheese", "dish", 5.0, "representative quick breakfast", False, [("cafe", "venue")]),
            MenuSeed("americano", "drink", 4.0, "representative coffee order", True, [("coffee", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Pronto Pizza",
        description="Convenient pizza option for quick meals, takeout, and late casual cravings.",
        city="Wolfville",
        price_tier="$",
        atmosphere="casual quick pizza",
        pace="fast",
        social_style="group",
        serves_alcohol=False,
        tags=[
            ("pizza", "cuisine"),
            ("takeout", "venue"),
            ("late-night", "occasion"),
            ("group-friendly", "social"),
        ],
        menu_items=[
            MenuSeed("pepperoni pizza", "dish", 18.0, "representative whole pie", True, [("pizza", "cuisine")]),
            MenuSeed("garlic fingers", "dish", 12.0, "representative shared side", False, [("group-friendly", "social")]),
            MenuSeed("bottled soda", "drink", 3.5, "representative takeout beverage", False, [("non-alcoholic", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Pizza Lupa",
        description="Pizza-focused venue suited to social dinners and more elevated casual pizza outings.",
        city="Wolfville",
        price_tier="$$",
        atmosphere="stylish casual pizza",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        tags=[
            ("pizza", "cuisine"),
            ("date-night", "occasion"),
            ("casual", "atmosphere"),
            ("wine", "drinks"),
        ],
        menu_items=[
            MenuSeed("margherita pizza", "dish", 19.0, "representative house pizza", True, [("pizza", "cuisine")]),
            MenuSeed("seasonal salad", "dish", 13.0, "representative lighter side", False, [("casual", "atmosphere")]),
            MenuSeed("house red", "drink", 10.0, "representative by-the-glass option", False, [("wine", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Annapolis Cider Company",
        description="Cider-focused tasting venue suitable for flights, casual drinks, and local beverage experiences.",
        city="Wolfville",
        price_tier="$$",
        atmosphere="casual tasting-room social",
        pace="slow",
        social_style="friends",
        serves_alcohol=True,
        tags=[
            ("cidery", "venue"),
            ("cider", "drinks"),
            ("tasting-flight", "style"),
            ("local", "social"),
        ],
        menu_items=[
            MenuSeed("snack board", "dish", 14.0, "representative tasting-room snack board", False, [("tasting-flight", "style")]),
            MenuSeed("pretzel bites", "dish", 9.0, "representative shareable snack", False, [("friends", "social")]),
            MenuSeed("cider flight", "drink", 15.0, "representative premium flight", True, [("cider", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Horton Ridge Malt & Grain Company",
        description="Beer-focused venue near Wolfville suited to relaxed tastings and small-group outings.",
        city="Wolfville",
        price_tier="$$",
        atmosphere="craft-beer relaxed rustic",
        pace="slow",
        social_style="friends",
        serves_alcohol=True,
        tags=[
            ("brewery", "venue"),
            ("beer", "drinks"),
            ("rustic", "atmosphere"),
            ("tasting-flight", "style"),
        ],
        menu_items=[
            MenuSeed("share board", "dish", 16.0, "representative beer-pairing snack board", False, [("brewery", "venue")]),
            MenuSeed("soft pretzel", "dish", 9.0, "representative beer snack", False, [("beer", "drinks")]),
            MenuSeed("beer flight", "drink", 14.0, "representative tasting flight", True, [("beer", "drinks")]),
        ],
    ),
    RestaurantSeed(
        name="Front Street Community Oven Society",
        description="Community-oriented oven and café concept suited to bread, simple lunch, and local stop-ins.",
        city="Wolfville",
        price_tier="$",
        atmosphere="community cozy artisan",
        pace="slow",
        social_style="friends",
        serves_alcohol=False,
        tags=[
            ("community", "social"),
            ("artisan-bread", "cuisine"),
            ("cafe", "venue"),
            ("cozy", "atmosphere"),
        ],
        menu_items=[
            MenuSeed("wood-fired flatbread", "dish", 13.0, "representative oven-based offering", True, [("artisan-bread", "cuisine")]),
            MenuSeed("soup with bread", "dish", 10.0, "representative café lunch", False, [("community", "social")]),
            MenuSeed("tea", "drink", 3.0, "representative hot beverage", False, [("non-alcoholic", "drinks")]),
        ],
    ),
]


def get_or_create_tag(db: Session, name: str, category: str) -> Tag:
    existing = (
        db.query(Tag)
        .filter(Tag.name == name, Tag.category == category)
        .first()
    )
    if existing is not None:
        return existing

    tag = Tag(name=name, category=category)
    db.add(tag)
    db.flush()
    return tag


def replace_menu_items(db: Session, restaurant: Restaurant, menu_items: list[MenuSeed]) -> None:
    for existing in list(restaurant.menu_items):
        db.delete(existing)
    db.flush()

    for item in menu_items:
        menu_item = MenuItem(
            restaurant_id=restaurant.id,
            name=item.name,
            category=item.category,
            price=item.price,
            description=item.description,
            is_signature=item.is_signature,
        )
        menu_item.tags = [get_or_create_tag(db, tag_name, tag_category) for tag_name, tag_category in item.tags]
        db.add(menu_item)

    db.flush()


def upsert_restaurant(db: Session, item: RestaurantSeed) -> None:
    restaurant = db.query(Restaurant).filter(Restaurant.name == item.name).first()

    if restaurant is None:
        restaurant = Restaurant(name=item.name)
        db.add(restaurant)
        db.flush()

    restaurant.description = item.description
    restaurant.city = item.city
    restaurant.price_tier = item.price_tier
    restaurant.atmosphere = item.atmosphere
    restaurant.pace = item.pace
    restaurant.social_style = item.social_style
    restaurant.serves_alcohol = item.serves_alcohol

    restaurant.tags = [get_or_create_tag(db, tag_name, tag_category) for tag_name, tag_category in item.tags]
    db.flush()

    replace_menu_items(db, restaurant, item.menu_items)


def remove_placeholders(db: Session) -> None:
    placeholders = db.query(Restaurant).filter(Restaurant.name.in_(PLACEHOLDER_NAMES)).all()
    for restaurant in placeholders:
        db.delete(restaurant)
    db.flush()


def seed_db() -> None:
    init_db()
    db = SessionLocal()

    try:
        remove_placeholders(db)

        for restaurant in RESTAURANTS:
            upsert_restaurant(db, restaurant)

        db.commit()

        restaurant_count = db.query(Restaurant).count()
        menu_count = db.query(MenuItem).count()
        tag_count = db.query(Tag).count()

        print(f"seed complete: {restaurant_count} restaurants, {menu_count} menu items, {tag_count} tags")

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_db()
PY

echo "wrote real wolfville seed module"

echo "initializing database tables..."
python app/db/init_db.py

echo "running real venue seed..."
python app/db/seed.py

echo "running smoke tests..."
python - <<'PY'
import sqlite3
from pathlib import Path

db_path = Path("app.db")
if not db_path.exists():
    raise SystemExit("smoke test failed: app.db does not exist")

conn = sqlite3.connect("app.db")
cur = conn.cursor()

required_tables = {
    "users",
    "profiles",
    "preferences",
    "restaurants",
    "menu_items",
    "tags",
    "restaurant_tags",
    "menu_item_tags",
    "experiences",
    "ratings",
    "experience_menu_items",
}

cur.execute("select name from sqlite_master where type='table'")
found = {row[0] for row in cur.fetchall()}
missing = sorted(required_tables - found)
if missing:
    raise SystemExit(f"smoke test failed: missing tables: {missing}")

cur.execute("select count(*) from restaurants")
restaurant_count = cur.fetchone()[0]

cur.execute("select count(*) from menu_items")
menu_count = cur.fetchone()[0]

cur.execute("select count(*) from tags")
tag_count = cur.fetchone()[0]

if restaurant_count < 20:
    raise SystemExit(f"smoke test failed: expected at least 20 restaurants, found {restaurant_count}")

if menu_count < 40:
    raise SystemExit(f"smoke test failed: expected at least 40 menu items, found {menu_count}")

cur.execute("select name, price_tier, atmosphere from restaurants order by name limit 10")
sample_rows = cur.fetchall()

conn.close()

print("smoke test passed")
print(f"restaurants: {restaurant_count}")
print(f"menu items: {menu_count}")
print(f"tags: {tag_count}")
print("sample restaurants:")
for row in sample_rows:
    print(f"  - {row[0]} | {row[1]} | {row[2]}")
PY

echo "backend repair complete"
