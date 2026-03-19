from __future__ import annotations

from dataclasses import dataclass, field

from sqlalchemy.orm import Session

from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models.restaurant import MenuItem, Restaurant, Tag


SEED_VERSION = "patch2-regional-50-v1"


@dataclass
class MenuSeed:
    name: str
    category: str
    price: float | None
    description: str
    is_signature: bool = False
    meal_period: str | None = None
    recommendation_hint: str | None = None
    is_dish_highlight: bool = False
    tags: list[tuple[str, str]] = field(default_factory=list)


@dataclass
class RestaurantSeed:
    name: str
    description: str
    town: str
    category: str
    source_url: str
    price_tier: str = "$$"
    city: str | None = None
    region: str | None = "Annapolis Valley"
    address: str | None = None
    subcategory: str | None = None
    atmosphere: str | None = None
    pace: str | None = None
    social_style: str | None = None
    serves_alcohol: bool = False
    offers_dine_in: bool | None = None
    offers_takeout: bool | None = None
    offers_delivery: bool | None = None
    accepts_reservations: bool | None = None
    supports_brunch: bool | None = None
    supports_lunch: bool | None = None
    supports_dinner: bool | None = None
    supports_dessert: bool | None = None
    supports_coffee: bool | None = None
    is_fast_food: bool | None = None
    is_family_friendly: bool | None = None
    is_date_night: bool | None = None
    is_student_friendly: bool | None = None
    is_quick_bite: bool | None = None
    has_live_music: bool | None = None
    has_trivia_night: bool | None = None
    event_notes: str | None = None
    source_notes: str | None = None
    tags: list[tuple[str, str]] = field(default_factory=list)
    menu_items: list[MenuSeed] = field(default_factory=list)


PLACEHOLDER_NAMES = {
    "Luna Trattoria",
    "North End Social",
    "Campus Quick Bowl",
}


WOLFVILLE_RESTAURANTS: list[RestaurantSeed] = [
    RestaurantSeed(
        name="Troy Restaurant & Grill",
        description="Mediterranean and Turkish restaurant in downtown Wolfville suited to dine-in dinners and shared-table meals.",
        town="Wolfville",
        category="restaurant",
        subcategory="mediterranean",
        source_url="https://wolfville.ca/about-wolfville/eat-and-drink",
        price_tier="$$$",
        atmosphere="warm lively",
        pace="leisurely",
        social_style="group",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_dinner=True,
        is_date_night=True,
        tags=[
            ("mediterranean", "cuisine"),
            ("turkish", "cuisine"),
            ("downtown", "location"),
            ("shared plates", "style"),
            ("date night", "occasion"),
        ],
        source_notes="Included in the Town of Wolfville eat-and-drink directory.",
    ),
    RestaurantSeed(
        name="Juniper Food + Wine",
        description="Seasonal dining and wine-focused restaurant in Wolfville suited to polished dinners and slower meals.",
        town="Wolfville",
        category="restaurant",
        subcategory="seasonal",
        source_url="https://wolfville.ca/about-wolfville/eat-and-drink",
        price_tier="$$$",
        atmosphere="refined intimate",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_dinner=True,
        accepts_reservations=True,
        is_date_night=True,
        tags=[
            ("seasonal", "cuisine"),
            ("wine", "drinks"),
            ("upscale", "atmosphere"),
            ("date night", "occasion"),
        ],
        source_notes="Listed by the Town of Wolfville as an eat-and-drink venue.",
    ),
    RestaurantSeed(
        name="Paddy's Brewpub & Rosie's Family Restaurant",
        description="Pub-and-family-restaurant option listed in Wolfville's dining directory.",
        town="Wolfville",
        category="pub",
        subcategory="brewpub",
        source_url="https://wolfville.ca/about-wolfville/eat-and-drink",
        price_tier="$$",
        atmosphere="casual lively",
        pace="moderate",
        social_style="group",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("brewpub", "venue"),
            ("pub", "venue"),
            ("family restaurant", "venue"),
            ("casual", "atmosphere"),
        ],
        source_notes="Included in the Town of Wolfville eat-and-drink listings.",
    ),
    RestaurantSeed(
        name="The Library Pub",
        description="Pub in Wolfville's dining scene suited to social meals, drinks, and casual outings.",
        town="Wolfville",
        category="pub",
        subcategory="pub",
        source_url="https://wolfville.ca/about-wolfville/eat-and-drink",
        price_tier="$$",
        atmosphere="cozy lively",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        tags=[
            ("pub", "venue"),
            ("beer", "drinks"),
            ("casual", "atmosphere"),
            ("friends", "social"),
        ],
        source_notes="Included in the Town of Wolfville eat-and-drink listings.",
    ),
    RestaurantSeed(
        name="Joe's Food Emporium",
        description="Downtown Wolfville staple with dine-in and take-out, broad casual appeal, and a long-running local presence.",
        town="Wolfville",
        category="restaurant",
        subcategory="casual dining",
        source_url="https://wolfville.ca/about-wolfville/businesses/joes-food-emporium",
        price_tier="$$",
        address="434 Main Street, Wolfville, NS",
        atmosphere="casual relaxed",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        is_student_friendly=True,
        tags=[
            ("downtown", "location"),
            ("casual dining", "style"),
            ("takeout", "format"),
            ("local favorite", "social"),
        ],
        source_notes="Town of Wolfville listing notes downtown location, take-out, and broad menu appeal.",
    ),
    RestaurantSeed(
        name="The Church Brewing Company",
        description="Craft brewery and restaurant in Wolfville with social energy and food service inside a restored church.",
        town="Wolfville",
        category="brewery",
        subcategory="brewpub",
        source_url="https://churchbrewing.ca/",
        price_tier="$$",
        atmosphere="lively brewery",
        pace="moderate",
        social_style="group",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("brewery", "venue"),
            ("beer", "drinks"),
            ("group friendly", "social"),
            ("night out", "occasion"),
        ],
        source_notes="Official site confirms craft beer and food in Wolfville.",
    ),
    RestaurantSeed(
        name="Lightfoot & Wolfville",
        description="Winery restaurant destination suited to scenic outings, special occasions, and wine-led experiences.",
        town="Wolfville",
        category="restaurant",
        subcategory="winery dining",
        source_url="https://lightfootandwolfville.com/pages/restaurant",
        price_tier="$$$",
        atmosphere="scenic refined",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        offers_dine_in=True,
        accepts_reservations=True,
        supports_lunch=True,
        supports_dinner=True,
        is_date_night=True,
        tags=[
            ("winery", "venue"),
            ("wine", "drinks"),
            ("scenic", "atmosphere"),
            ("special occasion", "occasion"),
        ],
        source_notes="Official restaurant page describes it as a destination restaurant at the vineyard.",
    ),
    RestaurantSeed(
        name="Blomidon Inn",
        description="Historic inn dining destination in Wolfville suited to quieter dinners and special-occasion meals.",
        town="Wolfville",
        category="restaurant",
        subcategory="inn dining",
        source_url="https://www.blomidon.ns.ca/",
        price_tier="$$$",
        address="195 Main Street, Wolfville, NS",
        atmosphere="historic quiet refined",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_dinner=True,
        accepts_reservations=True,
        is_date_night=True,
        tags=[
            ("inn dining", "venue"),
            ("historic", "atmosphere"),
            ("quiet", "atmosphere"),
            ("special occasion", "occasion"),
        ],
        source_notes="Official site confirms Wolfville location at 195 Main Street.",
    ),
    RestaurantSeed(
        name="JEJU Restaurant",
        description="Wolfville restaurant specializing in sushi and Korean food.",
        town="Wolfville",
        category="restaurant",
        subcategory="korean sushi",
        source_url="https://wolfville.ca/about-wolfville/businesses/jeju-restaurant",
        price_tier="$$",
        atmosphere="modern cozy",
        pace="moderate",
        social_style="friends",
        serves_alcohol=False,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        tags=[
            ("korean", "cuisine"),
            ("sushi", "cuisine"),
            ("downtown", "location"),
        ],
        source_notes="Town of Wolfville page explicitly describes JEJU as sushi and Korean food.",
    ),
    RestaurantSeed(
        name="Charts Cafe",
        description="Wolfville café known for coffee, baked goods, and daytime eats.",
        town="Wolfville",
        category="cafe",
        subcategory="cafe",
        source_url="https://wolfville.ca/about-wolfville/businesses/charts-cafe",
        price_tier="$",
        address="16 Elm Avenue, Wolfville, NS",
        atmosphere="cozy cafe",
        pace="slow",
        social_style="friends",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_dessert=True,
        supports_coffee=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("cafe", "venue"),
            ("coffee", "drinks"),
            ("baked goods", "style"),
            ("daytime", "occasion"),
        ],
        source_notes="Town listing and public social pages support the café identity and Elm Avenue location.",
    ),
    RestaurantSeed(
        name="Just Us! Coffee Roasters Coffeehouse",
        description="Downtown Wolfville coffeehouse and take-out stop suited to coffee, baked goods, and casual daytime visits.",
        town="Wolfville",
        category="cafe",
        subcategory="coffeehouse",
        source_url="https://wolfville.ca/about-wolfville/businesses/just-us-coffee-roasters-coffeehouse",
        price_tier="$",
        atmosphere="community coffeehouse",
        pace="slow",
        social_style="friends",
        serves_alcohol=False,
        offers_takeout=True,
        supports_dessert=True,
        supports_coffee=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("coffeehouse", "venue"),
            ("coffee", "drinks"),
            ("bakery", "style"),
            ("downtown", "location"),
        ],
        source_notes="Town of Wolfville page identifies it as a coffeehouse, bakery, and take-out venue.",
    ),
    RestaurantSeed(
        name="The Real Scoop Ice Cream & Espresso Shop",
        description="Dessert and espresso stop in Wolfville suited to quick sweet outings and casual walk-in visits.",
        town="Wolfville",
        category="dessert",
        subcategory="ice cream and espresso",
        source_url="https://wolfville.ca/about-wolfville/businesses/real-scoop-ice-cream-espresso-shop",
        price_tier="$",
        atmosphere="fun casual",
        pace="fast",
        social_style="friends",
        serves_alcohol=False,
        offers_takeout=True,
        supports_dessert=True,
        supports_coffee=True,
        is_family_friendly=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("dessert", "cuisine"),
            ("ice cream", "cuisine"),
            ("espresso", "drinks"),
            ("downtown", "location"),
        ],
        source_notes="Town of Wolfville page identifies it as an ice cream and espresso shop with take-out.",
    ),
    RestaurantSeed(
        name="Pronto Pizza",
        description="Quick pizza and take-out option in Wolfville suited to casual dinners and budget-friendly group orders.",
        town="Wolfville",
        category="fast food",
        subcategory="pizza",
        source_url="https://wolfville.ca/about-wolfville/businesses/pronto-pizza",
        price_tier="$",
        address="467 Main Street, Wolfville, NS",
        atmosphere="casual quick",
        pace="fast",
        social_style="group",
        serves_alcohol=False,
        offers_takeout=True,
        offers_delivery=True,
        supports_dinner=True,
        is_fast_food=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("pizza", "cuisine"),
            ("takeout", "format"),
            ("delivery", "format"),
            ("budget friendly", "style"),
        ],
        menu_items=[
            MenuSeed(
                name="Garlic Fingers",
                category="dish",
                price=None,
                description="Verified as a featured order category on public menu delivery listings for the Wolfville location.",
                meal_period="dinner",
                recommendation_hint="Useful quick-bite side for casual sharing.",
                is_dish_highlight=True,
                tags=[("pizza shop", "venue"), ("shareable", "style")],
            ),
        ],
        source_notes="Town listing confirms venue; public ordering listings show pizza and garlic fingers.",
    ),
    RestaurantSeed(
        name="Pizza Lupa",
        description="Artisanal pizza restaurant in Wolfville with reservations, bar service, and Italian-style pies.",
        town="Wolfville",
        category="restaurant",
        subcategory="pizza",
        source_url="https://pizzalupa.ca/",
        price_tier="$$",
        address="117 Front Street, Wolfville, NS",
        atmosphere="stylish casual",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        offers_takeout=True,
        accepts_reservations=True,
        supports_dinner=True,
        is_date_night=True,
        tags=[
            ("pizza", "cuisine"),
            ("italian style", "cuisine"),
            ("cocktails", "drinks"),
            ("wine", "drinks"),
        ],
        source_notes="Official site confirms Front Street address, reservations, and bar offerings.",
    ),
    RestaurantSeed(
        name="Annapolis Cider Company",
        description="Downtown Wolfville cidery and tasting venue built around Annapolis Valley cider.",
        town="Wolfville",
        category="cidery",
        subcategory="tasting room",
        source_url="https://wolfville.ca/about-wolfville/businesses/annapolis-cider-company",
        price_tier="$$",
        atmosphere="casual tasting room",
        pace="slow",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_dinner=True,
        tags=[
            ("cidery", "venue"),
            ("cider", "drinks"),
            ("local", "social"),
            ("downtown", "location"),
        ],
        source_notes="Town of Wolfville listing and official company site confirm downtown cider focus.",
    ),
    RestaurantSeed(
        name="Front Street Community Oven Society",
        description="Community food and café-style gathering space in Wolfville built around shared cooking and wood-fired oven events.",
        town="Wolfville",
        category="cafe",
        subcategory="community food venue",
        source_url="https://wolfville.ca/about-wolfville/businesses/front-street-community-oven-society",
        price_tier="$",
        address="122 Front Street, Wolfville, NS",
        atmosphere="community cozy",
        pace="slow",
        social_style="group",
        serves_alcohol=False,
        offers_dine_in=True,
        supports_lunch=True,
        is_family_friendly=True,
        tags=[
            ("community", "social"),
            ("wood fired", "style"),
            ("cafe", "venue"),
            ("events", "format"),
        ],
        source_notes="Town of Wolfville and Front Street Community Oven pages confirm location and community-food format.",
    ),
]

GRAND_PRE_RESTAURANTS: list[RestaurantSeed] = [
    RestaurantSeed(
        name="Le Caveau",
        description="Grand-Pré winery restaurant serving seasonal local cuisine paired with wines.",
        town="Grand-Pré",
        category="restaurant",
        subcategory="winery dining",
        source_url="https://novascotia.com/listing/le-caveau-restaurant-at-grand-pre-winery/",
        price_tier="$$$",
        atmosphere="scenic refined",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        offers_dine_in=True,
        accepts_reservations=True,
        supports_dinner=True,
        is_date_night=True,
        tags=[
            ("winery", "venue"),
            ("seasonal", "cuisine"),
            ("wine", "drinks"),
            ("special occasion", "occasion"),
        ],
        source_notes="Grand Pré and Nova Scotia tourism pages confirm dinner service and reservation support.",
    ),
    RestaurantSeed(
        name="Longfellow Restaurant",
        description="Dining room associated with the Evangeline Inn in Grand-Pré.",
        town="Grand-Pré",
        category="restaurant",
        subcategory="inn dining",
        source_url="https://www.landscapeofgrandpre.ca/places-to-stay.html",
        price_tier="$$$",
        atmosphere="quiet classic",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_dinner=True,
        is_date_night=True,
        tags=[
            ("inn dining", "venue"),
            ("grand pre", "location"),
            ("special occasion", "occasion"),
        ],
        source_notes="Landscape of Grand Pré page identifies Longfellow Restaurant at the Evangeline property.",
    ),
]

NEW_MINAS_RESTAURANTS: list[RestaurantSeed] = [
    RestaurantSeed(
        name="Cumin Kitchen & Drink",
        description="Urban café and eatery in New Minas focused on locally sourced food and daytime meals.",
        town="New Minas",
        category="cafe",
        subcategory="cafe eatery",
        source_url="https://cuminkitchenanddrink.com/",
        price_tier="$$",
        atmosphere="modern casual",
        pace="moderate",
        social_style="friends",
        serves_alcohol=False,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        supports_brunch=True,
        tags=[
            ("cafe", "venue"),
            ("locally sourced", "style"),
            ("urban eatery", "style"),
        ],
        source_notes="Official site describes Cumin as an urban café and eatery with brunch service references.",
    ),
    RestaurantSeed(
        name="Boston Pizza New Minas",
        description="Casual family restaurant and sports bar in New Minas with dine-in, takeout, and delivery.",
        town="New Minas",
        category="restaurant",
        subcategory="sports bar",
        source_url="https://bostonpizza.com/en/locations/new-minas.html",
        price_tier="$$",
        address="9278 Commercial Street, New Minas, NS",
        atmosphere="casual social",
        pace="moderate",
        social_style="group",
        serves_alcohol=True,
        offers_dine_in=True,
        offers_takeout=True,
        offers_delivery=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("pizza", "cuisine"),
            ("sports bar", "venue"),
            ("delivery", "format"),
            ("group friendly", "social"),
        ],
        source_notes="Official location page confirms address, dine-in, takeout, and delivery.",
    ),
    RestaurantSeed(
        name="Swiss Chalet New Minas",
        description="Family-focused rotisserie chain restaurant in New Minas.",
        town="New Minas",
        category="restaurant",
        subcategory="rotisserie",
        source_url="https://www.swisschalet.com/en/locations/ns/new-minas/9269-commercial-st.",
        price_tier="$$",
        atmosphere="casual family",
        pace="moderate",
        social_style="family",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("rotisserie", "cuisine"),
            ("family dining", "social"),
            ("casual", "atmosphere"),
        ],
        source_notes="Official Swiss Chalet location page confirms the New Minas site.",
    ),
    RestaurantSeed(
        name="KAO Restaurant",
        description="Chinese and Canadian cuisine restaurant in New Minas with buffet and take-out service.",
        town="New Minas",
        category="restaurant",
        subcategory="chinese",
        source_url="https://kaorestaurant.wixsite.com/kaorestaurant",
        price_tier="$$",
        address="8986 Commercial Street, New Minas, NS",
        atmosphere="casual",
        pace="moderate",
        social_style="family",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("chinese", "cuisine"),
            ("canadian", "cuisine"),
            ("buffet", "style"),
            ("takeout", "format"),
        ],
        source_notes="Official site confirms Chinese and Canadian cuisine plus lunch and supper buffet/take-out.",
    ),
    RestaurantSeed(
        name="Chrismaria Family Restaurant",
        description="Indian restaurant in New Minas serving family-style meals with vegetarian-friendly options.",
        town="New Minas",
        category="restaurant",
        subcategory="indian",
        source_url="https://chrismariarestaurant.com/",
        price_tier="$$",
        address="8934 Commercial Street, New Minas, NS",
        atmosphere="casual family",
        pace="moderate",
        social_style="family",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        supports_brunch=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("indian", "cuisine"),
            ("vegetarian friendly", "dietary"),
            ("vegan options", "dietary"),
            ("family dining", "social"),
        ],
        menu_items=[
            MenuSeed(
                name="Biriyani",
                category="dish",
                price=None,
                description="Public menu and profile pages identify biriyani as one of the restaurant's signature Indian offerings.",
                meal_period="lunch",
                recommendation_hint="Useful when ranking spice-forward meals.",
                is_dish_highlight=True,
                tags=[("indian", "cuisine"), ("spice forward", "style")],
            ),
            MenuSeed(
                name="Samosa",
                category="dish",
                price=None,
                description="Listed in public descriptions of Chrismaria's authentic Indian menu.",
                meal_period="lunch",
                recommendation_hint="Good appetizer-style hint for snackable Indian recommendations.",
                tags=[("indian", "cuisine"), ("starter", "style")],
            ),
            MenuSeed(
                name="Naan",
                category="dish",
                price=None,
                description="Listed in public descriptions of the menu.",
                meal_period="dinner",
                recommendation_hint="Useful bread-side hint for Indian meal suggestions.",
                tags=[("indian", "cuisine"), ("bread", "style")],
            ),
        ],
        source_notes="Official site confirms New Minas location; public menu and profile pages mention biriyani, samosa, naan, and curries.",
    ),
    RestaurantSeed(
        name="Jessy's Pizza New Minas",
        description="Local pizza franchise location serving takeout and delivery in New Minas.",
        town="New Minas",
        category="fast food",
        subcategory="pizza",
        source_url="https://jessyspizza.ca/locations/",
        price_tier="$",
        address="8934 Commercial Street, New Minas, NS",
        atmosphere="casual quick",
        pace="fast",
        social_style="group",
        serves_alcohol=False,
        offers_takeout=True,
        offers_delivery=True,
        supports_lunch=True,
        supports_dinner=True,
        is_fast_food=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("pizza", "cuisine"),
            ("delivery", "format"),
            ("takeout", "format"),
            ("budget friendly", "style"),
        ],
        source_notes="Jessy's official locations page and public listing pages confirm the New Minas location.",
    ),
    RestaurantSeed(
        name="House of Dough",
        description="Pizzeria in New Minas known for quick pizza orders and takeout-oriented service.",
        town="New Minas",
        category="fast food",
        subcategory="pizza",
        source_url="https://www.tripadvisor.ca/Restaurant_Review-g984045-d3846598-Reviews-House_of_Dough-New_Minas_Southwest_Nova_Scotia_Nova_Scotia.html",
        price_tier="$",
        address="9005 Commercial Street, New Minas, NS",
        atmosphere="casual quick",
        pace="fast",
        social_style="group",
        serves_alcohol=False,
        offers_takeout=True,
        supports_lunch=True,
        supports_dinner=True,
        is_fast_food=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("pizza", "cuisine"),
            ("quick bite", "style"),
            ("takeout", "format"),
        ],
        source_notes="Public restaurant listings identify House of Dough as a quick-bite pizzeria in New Minas.",
    ),
    RestaurantSeed(
        name="Pita Pit New Minas",
        description="Quick-service pita restaurant in New Minas with takeout and delivery.",
        town="New Minas",
        category="fast food",
        subcategory="pitas and wraps",
        source_url="https://pitapit.ca/restaurants/new-minas/",
        price_tier="$",
        address="9293 Commercial Street, New Minas, NS",
        atmosphere="casual quick",
        pace="fast",
        social_style="solo",
        serves_alcohol=False,
        offers_takeout=True,
        offers_delivery=True,
        supports_lunch=True,
        supports_dinner=True,
        is_fast_food=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("fast food", "venue"),
            ("pitas", "cuisine"),
            ("delivery", "format"),
            ("vegetarian friendly", "dietary"),
            ("vegan options", "dietary"),
        ],
        source_notes="Official location page confirms New Minas address plus takeout and delivery.",
    ),
    RestaurantSeed(
        name="Big Stop Restaurant New Minas",
        description="Roadside family-friendly restaurant in New Minas serving breakfast, lunch, dinner, and brunch-style meals.",
        town="New Minas",
        category="restaurant",
        subcategory="roadside diner",
        source_url="https://www.irvingoil.com/en-CA/location/irving-oil-26266",
        price_tier="$$",
        atmosphere="casual family",
        pace="moderate",
        social_style="family",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        supports_brunch=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("roadside", "venue"),
            ("family dining", "social"),
            ("breakfast", "occasion"),
            ("takeout", "format"),
        ],
        source_notes="Irving and public restaurant listings describe it as a Big Stop Restaurant with dine-in and takeout.",
    ),
    RestaurantSeed(
        name="McDonald's New Minas",
        description="Fast-food chain location in New Minas suited to quick meals and budget-focused orders.",
        town="New Minas",
        category="fast food",
        subcategory="burgers",
        source_url="https://www.mcdonalds.com/ca/en-ca/location/new-minas/new-minas/9197-commercial-street/4389.html",
        price_tier="$",
        address="9197 Commercial Street, New Minas, NS",
        atmosphere="quick service",
        pace="fast",
        social_style="solo",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        offers_delivery=True,
        supports_breakfast if False else None,
        supports_lunch=True,
        supports_dinner=True,
        is_fast_food=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("burgers", "cuisine"),
            ("fast food", "venue"),
            ("delivery", "format"),
            ("budget friendly", "style"),
        ],
        source_notes="Official McDonald's Canada page confirms the New Minas location.",
    ),
]

KENTVILLE_RESTAURANTS: list[RestaurantSeed] = [
    RestaurantSeed(
        name="Paddys Brew Pub",
        description="Irish brewpub and cozy restaurant in Kentville with dine-in and take-out.",
        town="Kentville",
        category="pub",
        subcategory="irish brewpub",
        source_url="https://kentville.ca/eat/dine/paddys-brew-pub",
        price_tier="$$",
        address="42 Aberdeen Street, Kentville, NS",
        atmosphere="casual lively",
        pace="moderate",
        social_style="group",
        serves_alcohol=True,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("irish pub", "cuisine"),
            ("brewpub", "venue"),
            ("vegetarian", "dietary"),
            ("vegan", "dietary"),
            ("gluten free", "dietary"),
        ],
        source_notes="Kentville dining page confirms address and take-out with vegetarian, vegan, and gluten-free availability.",
    ),
    RestaurantSeed(
        name="TACOcentric",
        description="Mexican-inspired handheld food and drinks spot in Kentville with broad lunch and casual-dinner appeal.",
        town="Kentville",
        category="restaurant",
        subcategory="mexican inspired",
        source_url="https://kentville.ca/eat/dine/tacocentric",
        price_tier="$$",
        address="437 Main Street Unit 3, Kentville, NS",
        atmosphere="laid-back casual",
        pace="fast",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_dinner=True,
        is_quick_bite=True,
        is_student_friendly=True,
        tags=[
            ("mexican inspired", "cuisine"),
            ("handheld food", "style"),
            ("gluten free", "dietary"),
            ("vegetarian", "dietary"),
            ("vegan", "dietary"),
            ("dairy free", "dietary"),
        ],
        menu_items=[
            MenuSeed(
                name="Tacos",
                category="dish",
                price=None,
                description="Official Kentville listing explicitly identifies tacos as a core menu item.",
                meal_period="lunch",
                recommendation_hint="Strong match for handheld, casual, or quick-bite recommendations.",
                is_dish_highlight=True,
                tags=[("mexican inspired", "cuisine"), ("handheld", "style")],
            ),
            MenuSeed(
                name="Burritos",
                category="dish",
                price=None,
                description="Official Kentville listing explicitly identifies burritos as a core menu item.",
                meal_period="lunch",
                recommendation_hint="Useful for filling casual lunch matches.",
                tags=[("mexican inspired", "cuisine")],
            ),
            MenuSeed(
                name="Quesadillas",
                category="dish",
                price=None,
                description="Official Kentville listing explicitly identifies quesadillas as a core menu item.",
                meal_period="dinner",
                recommendation_hint="Good for flexible group-friendly casual recommendations.",
                tags=[("mexican inspired", "cuisine"), ("shareable", "style")],
            ),
        ],
        source_notes="Kentville listing explicitly mentions tacos, burritos, quesadillas, bowls, and nachos.",
    ),
    RestaurantSeed(
        name="T.A.N. Coffee",
        description="Kentville café serving coffee, sandwiches, desserts, and daytime dine-in/takeout orders.",
        town="Kentville",
        category="cafe",
        subcategory="coffee shop",
        source_url="https://kentville.ca/eat/dine/tan-coffee",
        price_tier="$",
        address="431 Main Street, Kentville, NS",
        atmosphere="minimal cafe",
        pace="slow",
        social_style="solo",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        offers_delivery=True,
        supports_lunch=True,
        supports_dessert=True,
        supports_coffee=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("coffee", "drinks"),
            ("sandwiches", "cuisine"),
            ("desserts", "cuisine"),
            ("cafe", "venue"),
        ],
        source_notes="Kentville listing confirms dine-in, takeout, delivery, sandwiches, desserts, and café service.",
    ),
    RestaurantSeed(
        name="Half Acre Cafe",
        description="Fresh-and-fast café in Kentville focused on local coffee and quick casual meals.",
        town="Kentville",
        category="cafe",
        subcategory="cafe",
        source_url="https://kentville.ca/eat/dine/half-acre-cafe",
        price_tier="$",
        address="395 Main Street, Kentville, NS",
        atmosphere="casual community",
        pace="fast",
        social_style="friends",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_coffee=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("cafe", "venue"),
            ("fresh and fast", "style"),
            ("local coffee", "drinks"),
            ("sandwiches", "cuisine"),
        ],
        source_notes="Kentville page describes Half Acre Cafe as celebrating fresh and fast food plus local coffee.",
    ),
    RestaurantSeed(
        name="Maritime Express Cider Co.",
        description="Kentville cidery and restaurant located at the former railway hotel patio site.",
        town="Kentville",
        category="cidery",
        subcategory="restaurant",
        source_url="https://www.maritimeexpress.ca/",
        price_tier="$$",
        atmosphere="casual tasting room",
        pace="slow",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        tags=[
            ("cidery", "venue"),
            ("cider", "drinks"),
            ("restaurant", "venue"),
            ("kentville", "location"),
        ],
        source_notes="Official site and Kentville listing identify it as both cidery and restaurant.",
    ),
    RestaurantSeed(
        name="Kings Arms Pub by Lew Murphy's",
        description="Traditional pub in Kentville with British fare and a long-standing local following.",
        town="Kentville",
        category="pub",
        subcategory="british pub",
        source_url="https://kentville.ca/eat/dine/kings-arms-pub-lew-murphys",
        price_tier="$$",
        address="390 Main Street, Kentville, NS",
        atmosphere="traditional comfortable",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        tags=[
            ("pub", "venue"),
            ("british", "cuisine"),
            ("global flair", "style"),
            ("local favorite", "social"),
        ],
        source_notes="Kentville listing describes it as a traditional and comfortable pub with British fare.",
    ),
    RestaurantSeed(
        name="S & J's Diner",
        description="Kentville diner offering dine-in and take-out with diner and sandwich categories.",
        town="Kentville",
        category="restaurant",
        subcategory="diner",
        source_url="https://kentville.ca/eat/dine/s-js-diner",
        price_tier="$",
        address="264 Cornwallis Street, Kentville, NS",
        atmosphere="casual diner",
        pace="fast",
        social_style="family",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_dinner=True,
        is_fast_food=True,
        is_family_friendly=True,
        is_quick_bite=True,
        tags=[
            ("diner", "venue"),
            ("sandwiches", "cuisine"),
            ("fast food", "venue"),
            ("takeout", "format"),
        ],
        source_notes="Kentville page explicitly lists dine-in, take-out, sandwiches and wraps, fast food, and diner categories.",
    ),
    RestaurantSeed(
        name="Natalino's Pizza",
        description="Kentville pizza restaurant serving dine-in, take-out, and delivery.",
        town="Kentville",
        category="fast food",
        subcategory="pizza",
        source_url="https://kentville.ca/eat/dine/natalinos-pizza",
        price_tier="$",
        address="252 Main Street, Kentville, NS",
        atmosphere="casual quick",
        pace="fast",
        social_style="group",
        serves_alcohol=False,
        offers_dine_in=True,
        offers_takeout=True,
        offers_delivery=True,
        supports_lunch=True,
        supports_dinner=True,
        is_fast_food=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("pizza", "cuisine"),
            ("delivery", "format"),
            ("takeout", "format"),
            ("budget friendly", "style"),
        ],
        source_notes="Kentville page confirms dine-in, take-out, delivery, and pizza categories.",
    ),
    RestaurantSeed(
        name="Tim Hortons Kentville",
        description="Kentville coffee-and-light-fare chain location suited to quick coffee and snack stops.",
        town="Kentville",
        category="fast food",
        subcategory="coffee and bakery",
        source_url="https://kentville.ca/taxonomy/term/34",
        price_tier="$",
        address="70 Aberdeen Street, Kentville, NS",
        atmosphere="quick service",
        pace="fast",
        social_style="solo",
        serves_alcohol=False,
        offers_takeout=True,
        supports_dessert=True,
        supports_coffee=True,
        is_fast_food=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("coffee", "drinks"),
            ("bakery", "cuisine"),
            ("fast food", "venue"),
            ("drive through", "format"),
        ],
        source_notes="Kentville fast-food taxonomy page identifies the Aberdeen Street Tim Hortons as a drive-through coffee chain location.",
    ),
]

CANNING_RESTAURANTS: list[RestaurantSeed] = [
    RestaurantSeed(
        name="Dickie-Baxter Taproom & Bistro",
        description="Canning bistro and taproom serving contemporary Canadian cuisine with reservations and takeout support.",
        town="Canning",
        category="restaurant",
        subcategory="bistro",
        source_url="https://www.dickiebaxter.com/",
        price_tier="$$$",
        address="9809 Main Street, Canning, NS",
        atmosphere="refined relaxed",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        offers_dine_in=True,
        offers_takeout=True,
        accepts_reservations=True,
        supports_lunch=True,
        supports_dinner=True,
        is_date_night=True,
        tags=[
            ("contemporary canadian", "cuisine"),
            ("bistro", "venue"),
            ("craft cocktails", "drinks"),
            ("reservations", "format"),
        ],
        source_notes="Official site confirms Main Street location, reservations, and takeout.",
    ),
    RestaurantSeed(
        name="Bessie North House",
        description="Reservation-style Canning dining destination with limited evening sittings.",
        town="Canning",
        category="restaurant",
        subcategory="destination dining",
        source_url="https://www.bessienorthhouse.com/",
        price_tier="$$$",
        address="23 Bessie North Road, Canning, NS",
        atmosphere="intimate",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        offers_dine_in=True,
        accepts_reservations=True,
        supports_dinner=True,
        is_date_night=True,
        tags=[
            ("destination dining", "venue"),
            ("reservations", "format"),
            ("intimate", "atmosphere"),
        ],
        source_notes="Official site confirms address and limited evening sitting format.",
    ),
    RestaurantSeed(
        name="Crystany's Brasserie",
        description="Family-owned gluten-free-friendly restaurant on Main Street in Canning.",
        town="Canning",
        category="restaurant",
        subcategory="brasserie",
        source_url="https://www.opentable.ca/r/crystanys-brasserie-canning",
        price_tier="$$",
        address="9848 Main Street, Canning, NS",
        atmosphere="casual",
        pace="moderate",
        social_style="family",
        serves_alcohol=False,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("gluten free friendly", "dietary"),
            ("main street", "location"),
            ("family owned", "social"),
        ],
        source_notes="OpenTable and public restaurant association pages confirm address and gluten-free-friendly positioning.",
    ),
    RestaurantSeed(
        name="Big Wigs Family Diner",
        description="Family-style diner in Canning serving affordable home-style meals.",
        town="Canning",
        category="restaurant",
        subcategory="diner",
        source_url="https://nslegislature.ca/legislative-business/hansard-debates/assembly-62-session-3/house_16nov09",
        price_tier="$",
        address="9819 Main Street, Canning, NS",
        atmosphere="retro casual",
        pace="fast",
        social_style="family",
        serves_alcohol=False,
        offers_dine_in=True,
        supports_breakfast if False else None,
        supports_lunch=True,
        is_family_friendly=True,
        is_quick_bite=True,
        tags=[
            ("family diner", "venue"),
            ("home style", "style"),
            ("budget friendly", "style"),
        ],
        source_notes="Legislature remarks and public local listings describe Big Wigs as a family-style diner in Canning.",
    ),
]

WINDSOR_RESTAURANTS: list[RestaurantSeed] = [
    RestaurantSeed(
        name="Walkers Restaurant",
        description="Long-running Windsor restaurant known for honest prices and broad casual menu coverage.",
        town="Windsor",
        category="restaurant",
        subcategory="family restaurant",
        source_url="https://www.walkersrestaurant.ca/",
        price_tier="$$",
        address="88 Gerrish Street, Windsor, NS",
        atmosphere="classic casual",
        pace="moderate",
        social_style="family",
        serves_alcohol=False,
        offers_dine_in=True,
        supports_breakfast if False else None,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("family restaurant", "venue"),
            ("casual", "atmosphere"),
            ("local institution", "social"),
        ],
        source_notes="Official site describes Walkers as Windsor's best-value eatery since 1958.",
    ),
    RestaurantSeed(
        name="Hole in the Wall",
        description="Quaint upscale Windsor restaurant featuring local ingredients and worldly fusion.",
        town="Windsor",
        category="restaurant",
        subcategory="fusion",
        source_url="https://www.holeinthewallwindsor.ca/",
        price_tier="$$$",
        address="23 Water Street, Windsor, NS",
        atmosphere="upscale intimate",
        pace="leisurely",
        social_style="date",
        serves_alcohol=True,
        offers_dine_in=True,
        accepts_reservations=True,
        supports_lunch=True,
        supports_dinner=True,
        is_date_night=True,
        tags=[
            ("fusion", "cuisine"),
            ("local ingredients", "style"),
            ("upscale", "atmosphere"),
        ],
        source_notes="Official site confirms local-ingredient and worldly-fusion positioning.",
    ),
    RestaurantSeed(
        name="Schoolhouse Brewery",
        description="Windsor craft brewery and kitchen with a dog-friendly patio and made-from-scratch food.",
        town="Windsor",
        category="brewery",
        subcategory="brewpub",
        source_url="https://www.schoolhousebrewery.ca/pages/taproom-menu",
        price_tier="$$",
        address="40 Water Street, Windsor, NS",
        atmosphere="craft brewery",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        offers_takeout=True,
        supports_lunch=True,
        supports_dinner=True,
        tags=[
            ("brewery", "venue"),
            ("craft beer", "drinks"),
            ("patio", "feature"),
            ("made from scratch", "style"),
        ],
        menu_items=[
            MenuSeed(
                name="Crispy Cauliflower",
                category="dish",
                price=12.0,
                description="Appears on the public taproom menu.",
                meal_period="dinner",
                recommendation_hint="Useful shareable small-plate hint for brewery recommendations.",
                is_dish_highlight=True,
                tags=[("shareable", "style"), ("brewery", "venue")],
            ),
        ],
        source_notes="Official site confirms Windsor taproom, kitchen, and published menu item Crispy Cauliflower.",
    ),
    RestaurantSeed(
        name="Spitfire Arms Alehouse",
        description="Large Windsor pub-and-family-restaurant combination with reservations, takeout, and public live-music listings.",
        town="Windsor",
        category="pub",
        subcategory="alehouse",
        source_url="https://spitfirearms.com/",
        price_tier="$$",
        address="29 Water Street, Windsor, NS",
        atmosphere="pub social",
        pace="moderate",
        social_style="group",
        serves_alcohol=True,
        offers_dine_in=True,
        offers_takeout=True,
        accepts_reservations=True,
        supports_lunch=True,
        supports_dinner=True,
        supports_brunch=True,
        is_family_friendly=True,
        has_live_music=True,
        tags=[
            ("pub", "venue"),
            ("british", "cuisine"),
            ("family restaurant", "venue"),
            ("live music", "experience"),
        ],
        source_notes="Official site confirms pub/family-restaurant identity; public listing pages indicate reservations and live music.",
    ),
    RestaurantSeed(
        name="Lisa's Family Restaurant",
        description="Old-fashioned Nova Scotia diner in Windsor serving home-style meals in a family-friendly atmosphere.",
        town="Windsor",
        category="restaurant",
        subcategory="diner",
        source_url="https://windsortownship.ca/business-directory/lisas-family-restaurant/",
        price_tier="$$",
        address="30 Water Street, Windsor, NS",
        atmosphere="old-fashioned diner",
        pace="moderate",
        social_style="family",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("family restaurant", "venue"),
            ("diner", "venue"),
            ("home style", "style"),
            ("seafood", "cuisine"),
            ("desserts", "cuisine"),
        ],
        source_notes="Windsor Township directory confirms family-friendly diner positioning, seafood, desserts, and Water Street address.",
    ),
    RestaurantSeed(
        name="Jessy's Pizza Windsor",
        description="Windsor pizza takeout and delivery location suited to quick and budget-conscious meals.",
        town="Windsor",
        category="fast food",
        subcategory="pizza",
        source_url="https://www.tripadvisor.ca/Restaurant_Review-g316029-d4852774-Reviews-Jessy_s_Pizza-Windsor_Southwest_Nova_Scotia_Nova_Scotia.html",
        price_tier="$",
        address="105 Wentworth Road, Windsor, NS",
        atmosphere="casual quick",
        pace="fast",
        social_style="group",
        serves_alcohol=False,
        offers_takeout=True,
        offers_delivery=True,
        supports_lunch=True,
        supports_dinner=True,
        is_fast_food=True,
        is_student_friendly=True,
        is_quick_bite=True,
        tags=[
            ("pizza", "cuisine"),
            ("delivery", "format"),
            ("takeout", "format"),
        ],
        source_notes="Public restaurant listing confirms Windsor location and operating category.",
    ),
]

PORT_WILLIAMS_AND_SURROUNDING_RESTAURANTS: list[RestaurantSeed] = [
    RestaurantSeed(
        name="The Port Pub & Bistro",
        description="Port Williams pub and dining venue with broad lunch and dinner service.",
        town="Port Williams",
        category="pub",
        subcategory="bistro",
        source_url="https://thesarsfieldgroup.com/",
        price_tier="$$",
        address="980 Terrys Creek Road, Port Williams, NS",
        atmosphere="relaxed pub",
        pace="moderate",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        is_family_friendly=True,
        tags=[
            ("pub", "venue"),
            ("bistro", "venue"),
            ("port williams", "location"),
        ],
        source_notes="Sarsfield Group site confirms Port Williams location and lunch/dinner hours.",
    ),
    RestaurantSeed(
        name="Bay of Fundy Brewing Co.",
        description="Port Williams brewery and food venue positioned around river views, taproom service, and hot food.",
        town="Port Williams",
        category="brewery",
        subcategory="brewpub",
        source_url="https://novascotia.com/listing/bay-of-fundy-brewing-co/",
        price_tier="$$",
        address="1116 Kars Street, Port Williams, NS",
        atmosphere="brewery waterfront",
        pace="slow",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        supports_dinner=True,
        tags=[
            ("brewery", "venue"),
            ("craft beer", "drinks"),
            ("riverfront", "atmosphere"),
            ("hot food", "style"),
        ],
        source_notes="Nova Scotia tourism page describes it as a brewery with hot food and river-view seating.",
    ),
    RestaurantSeed(
        name="Millstone Harvest Brewhouse",
        description="Sheffield Mills brewery stop included on public wine-country itineraries as a food-and-drink destination.",
        town="Sheffield Mills",
        category="brewery",
        subcategory="brewhouse",
        source_url="https://magicwinerybus.ca/nova-scotia-tours/routes-schedules/",
        price_tier="$$",
        address="9146 Highway 221, Sheffield Mills, NS",
        atmosphere="brewery casual",
        pace="slow",
        social_style="friends",
        serves_alcohol=True,
        offers_dine_in=True,
        supports_lunch=True,
        tags=[
            ("brewery", "venue"),
            ("wine country stop", "occasion"),
            ("day trip", "occasion"),
        ],
        source_notes="Magic Winery Bus itineraries identify Millstone Harvest Brewhouse as a lunch/appetizer stop in the Wolfville area.",
    ),
]

RESTAURANTS: list[RestaurantSeed] = (
    WOLFVILLE_RESTAURANTS
    + GRAND_PRE_RESTAURANTS
    + NEW_MINAS_RESTAURANTS
    + KENTVILLE_RESTAURANTS
    + CANNING_RESTAURANTS
    + WINDSOR_RESTAURANTS
    + PORT_WILLIAMS_AND_SURROUNDING_RESTAURANTS
)


def _bool_or_none(value: bool | None) -> bool | None:
    return value if value is not None else None


def get_or_create_tag(db: Session, name: str, category: str) -> Tag:
    existing = db.query(Tag).filter(Tag.name == name, Tag.category == category).first()
    if existing is not None:
        return existing

    tag = Tag(name=name, category=category)
    db.add(tag)
    db.flush()
    return tag


def _default_tags(item: RestaurantSeed) -> list[tuple[str, str]]:
    tags = list(item.tags)

    tags.append((item.town.lower(), "town"))

    if item.category:
        tags.append((item.category.lower(), "category"))
    if item.subcategory:
        tags.append((item.subcategory.lower(), "subcategory"))

    if item.offers_dine_in:
        tags.append(("dine-in", "format"))
    if item.offers_takeout:
        tags.append(("takeout", "format"))
    if item.offers_delivery:
        tags.append(("delivery", "format"))
    if item.accepts_reservations:
        tags.append(("reservations", "format"))
    if item.supports_brunch:
        tags.append(("brunch", "meal"))
    if item.supports_lunch:
        tags.append(("lunch", "meal"))
    if item.supports_dinner:
        tags.append(("dinner", "meal"))
    if item.supports_dessert:
        tags.append(("dessert", "meal"))
    if item.supports_coffee:
        tags.append(("coffee", "drinks"))
    if item.is_fast_food:
        tags.append(("fast food", "category"))
    if item.is_family_friendly:
        tags.append(("family friendly", "social"))
    if item.is_date_night:
        tags.append(("date night", "occasion"))
    if item.is_student_friendly:
        tags.append(("student friendly", "social"))
    if item.is_quick_bite:
        tags.append(("quick bite", "style"))
    if item.has_live_music:
        tags.append(("live music", "experience"))
    if item.has_trivia_night:
        tags.append(("trivia", "experience"))
    if item.serves_alcohol:
        tags.append(("alcohol", "drinks"))

    deduped: list[tuple[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for tag in tags:
        normalized = (tag[0].strip().lower(), tag[1].strip().lower())
        if normalized in seen:
            continue
        deduped.append(normalized)
        seen.add(normalized)
    return deduped


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
            meal_period=item.meal_period,
            recommendation_hint=item.recommendation_hint,
            is_dish_highlight=item.is_dish_highlight,
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
    restaurant.city = item.city or item.town
    restaurant.town = item.town
    restaurant.region = item.region
    restaurant.address = item.address
    restaurant.category = item.category
    restaurant.subcategory = item.subcategory
    restaurant.price_tier = item.price_tier
    restaurant.price_min_per_person = None
    restaurant.price_max_per_person = None
    restaurant.atmosphere = item.atmosphere
    restaurant.pace = item.pace
    restaurant.social_style = item.social_style
    restaurant.serves_alcohol = item.serves_alcohol
    restaurant.offers_dine_in = _bool_or_none(item.offers_dine_in)
    restaurant.offers_takeout = _bool_or_none(item.offers_takeout)
    restaurant.offers_delivery = _bool_or_none(item.offers_delivery)
    restaurant.accepts_reservations = _bool_or_none(item.accepts_reservations)
    restaurant.supports_brunch = _bool_or_none(item.supports_brunch)
    restaurant.supports_lunch = _bool_or_none(item.supports_lunch)
    restaurant.supports_dinner = _bool_or_none(item.supports_dinner)
    restaurant.supports_dessert = _bool_or_none(item.supports_dessert)
    restaurant.supports_coffee = _bool_or_none(item.supports_coffee)
    restaurant.is_fast_food = _bool_or_none(item.is_fast_food)
    restaurant.is_family_friendly = _bool_or_none(item.is_family_friendly)
    restaurant.is_date_night = _bool_or_none(item.is_date_night)
    restaurant.is_student_friendly = _bool_or_none(item.is_student_friendly)
    restaurant.is_quick_bite = _bool_or_none(item.is_quick_bite)
    restaurant.has_live_music = _bool_or_none(item.has_live_music)
    restaurant.has_trivia_night = _bool_or_none(item.has_trivia_night)
    restaurant.event_notes = item.event_notes
    restaurant.source_url = item.source_url
    restaurant.source_notes = item.source_notes or f"Seeded from {SEED_VERSION}"

    restaurant.tags = [get_or_create_tag(db, tag_name, tag_category) for tag_name, tag_category in _default_tags(item)]
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

        print(f"seed version: {SEED_VERSION}")
        print(f"seed complete: {restaurant_count} restaurants, {menu_count} menu items, {tag_count} tags")

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_db()
