from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.restaurant import Restaurant
from app.models.restaurant import MenuItem


restaurants = [

# -----------------------------
# CASUAL FOOD
# -----------------------------

{
"name":"The Noodle Guy",
"description":"Asian noodle bar specializing in ramen and stir fry.",
"city":"Wolfville",
"price_tier":"$$",
"atmosphere":"casual",
"pace":"fast",
"social_style":"friends",
"serves_alcohol":True,
"menu":[
("Tonkotsu Ramen","ramen",16,True),
("Spicy Miso Ramen","ramen",17,True),
("Pork Gyoza","appetizer",8,False),
]
},

{
"name":"Troy Restaurant",
"description":"Mediterranean wraps, shawarma and donair.",
"city":"Wolfville",
"price_tier":"$",
"atmosphere":"casual",
"pace":"fast",
"social_style":"friends",
"serves_alcohol":False,
"menu":[
("Chicken Shawarma","wrap",12,True),
("Donair Plate","wrap",15,True),
]
},

{
"name":"Garlic Breath Pizza",
"description":"Local pizza spot popular with students.",
"city":"Wolfville",
"price_tier":"$",
"atmosphere":"casual",
"pace":"fast",
"social_style":"friends",
"serves_alcohol":False,
"menu":[
("Pepperoni Pizza","pizza",14,True),
("Garlic Fingers","pizza",10,True),
]
},

# -----------------------------
# PUBS
# -----------------------------

{
"name":"Paddy's Pub",
"description":"Classic Irish pub with live music and beer.",
"city":"Wolfville",
"price_tier":"$$",
"atmosphere":"lively",
"pace":"medium",
"social_style":"friends",
"serves_alcohol":True,
"menu":[
("Fish and Chips","pub",18,True),
("Paddy Burger","pub",16,True),
]
},

{
"name":"The Library Pub",
"description":"Student pub inside Acadia University.",
"city":"Wolfville",
"price_tier":"$",
"atmosphere":"lively",
"pace":"fast",
"social_style":"friends",
"serves_alcohol":True,
"menu":[
("Nachos","pub",12,True),
("Classic Burger","pub",14,True),
]
},

{
"name":"The Port Pub",
"description":"Scenic pub overlooking the Minas Basin.",
"city":"Port Williams",
"price_tier":"$$",
"atmosphere":"relaxed",
"pace":"medium",
"social_style":"friends",
"serves_alcohol":True,
"menu":[
("Seafood Chowder","seafood",18,True),
("Lobster Roll","seafood",24,True),
]
},

# -----------------------------
# FINE DINING
# -----------------------------

{
"name":"Juniper Food + Wine",
"description":"Fine dining restaurant focusing on seasonal ingredients.",
"city":"Wolfville",
"price_tier":"$$$",
"atmosphere":"romantic",
"pace":"slow",
"social_style":"date",
"serves_alcohol":True,
"menu":[
("Seared Scallops","seafood",24,True),
("Duck Breast","entree",32,True),
]
},

{
"name":"Le Caveau",
"description":"Upscale winery restaurant overlooking vineyards.",
"city":"Grand Pre",
"price_tier":"$$$",
"atmosphere":"romantic",
"pace":"slow",
"social_style":"date",
"serves_alcohol":True,
"menu":[
("Braised Lamb","entree",34,True),
("Local Cheese Board","appetizer",18,True),
]
},

# -----------------------------
# BREWERIES / WINERIES
# -----------------------------

{
"name":"Church Brewing Co",
"description":"Craft brewery inside a historic church.",
"city":"Wolfville",
"price_tier":"$$",
"atmosphere":"lively",
"pace":"medium",
"social_style":"friends",
"serves_alcohol":True,
"menu":[
("Brisket Sandwich","bbq",18,True),
("Beer Flight","drinks",14,True),
]
},

{
"name":"Lightfoot & Wolfville Winery",
"description":"Organic winery with vineyard dining.",
"city":"Wolfville",
"price_tier":"$$$",
"atmosphere":"romantic",
"pace":"slow",
"social_style":"date",
"serves_alcohol":True,
"menu":[
("Charcuterie Board","appetizer",22,True),
("Estate Wine Tasting","drinks",18,True),
]
},

{
"name":"Benjamin Bridge Winery",
"description":"Sparkling wine vineyard experience.",
"city":"Gaspereau",
"price_tier":"$$$",
"atmosphere":"romantic",
"pace":"slow",
"social_style":"date",
"serves_alcohol":True,
"menu":[
("Wine Tasting","drinks",20,True),
]
},

# -----------------------------
# CAFES
# -----------------------------

{
"name":"Tan Coffee",
"description":"Popular student coffee shop.",
"city":"Wolfville",
"price_tier":"$",
"atmosphere":"quiet",
"pace":"slow",
"social_style":"solo",
"serves_alcohol":False,
"menu":[
("Latte","coffee",5,True),
("Avocado Toast","cafe",9,True),
]
},

{
"name":"Just Us Coffee",
"description":"Fair trade coffee roastery.",
"city":"Wolfville",
"price_tier":"$",
"atmosphere":"relaxed",
"pace":"slow",
"social_style":"solo",
"serves_alcohol":False,
"menu":[
("Espresso","coffee",4,True),
("Cappuccino","coffee",5,True),
]
},

{
"name":"Rolled Oat Cafe",
"description":"Organic vegetarian cafe.",
"city":"Wolfville",
"price_tier":"$$",
"atmosphere":"relaxed",
"pace":"slow",
"social_style":"friends",
"serves_alcohol":False,
"menu":[
("Buddha Bowl","vegan",16,True),
("Smoothie","vegan",7,True),
]
},

# -----------------------------
# BREAKFAST / CREPES
# -----------------------------

{
"name":"The Naked Crepe",
"description":"Breakfast creperie famous for sweet crepes.",
"city":"Wolfville",
"price_tier":"$$",
"atmosphere":"casual",
"pace":"medium",
"social_style":"friends",
"serves_alcohol":False,
"menu":[
("Nutella Crepe","dessert",12,True),
("Breakfast Crepe","breakfast",14,True),
]
},

]



def seed():

    db: Session = SessionLocal()

    if db.query(Restaurant).count() >= 20:
        print("restaurants already seeded")
        return

    for r in restaurants:

        restaurant = Restaurant(
            name=r["name"],
            description=r["description"],
            city=r["city"],
            price_tier=r["price_tier"],
            atmosphere=r["atmosphere"],
            pace=r["pace"],
            social_style=r["social_style"],
            serves_alcohol=r["serves_alcohol"],
        )

        db.add(restaurant)
        db.flush()

        for item in r["menu"]:

            menu_item = MenuItem(
                restaurant_id=restaurant.id,
                name=item[0],
                category=item[1],
                price=item[2],
                description=None,
                is_signature=item[3]
            )

            db.add(menu_item)

    db.commit()

    print("wolfville restaurant dataset seeded")


if __name__ == "__main__":
    seed()
