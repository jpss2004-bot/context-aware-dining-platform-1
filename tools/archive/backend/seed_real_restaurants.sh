#!/bin/bash

echo "seeding wolfville restaurant database..."

python << 'PYTHON'

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.models.restaurant import Restaurant, MenuItem, Tag
from app.db.base import Base

DATABASE_URL = "sqlite:///./app.db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

session = SessionLocal()

def get_or_create_tag(name, category):
    tag = session.query(Tag).filter_by(name=name, category=category).first()
    if not tag:
        tag = Tag(name=name, category=category)
        session.add(tag)
        session.commit()
    return tag

restaurants = [

{
"name":"The Naked Crepe",
"description":"Popular brunch and crepe restaurant loved by students",
"price_tier":"$$",
"atmosphere":"casual brunch",
"pace":"medium",
"social_style":"friends",
"serves_alcohol":False,
"tags":[("brunch","cuisine"),("crepes","food"),("student-favorite","vibe")],
"menu":[
("Nutella Crepe","dessert",12.5,True),
("Ham & Cheese Crepe","main",14,False),
("Egg Breakfast Crepe","breakfast",13,False)
]
},

{
"name":"Paddy's Irish Brewpub",
"description":"Lively Irish pub with craft beer and comfort food",
"price_tier":"$$",
"atmosphere":"loud pub",
"pace":"fast",
"social_style":"groups",
"serves_alcohol":True,
"tags":[("pub","cuisine"),("beer","drink"),("nightlife","vibe")],
"menu":[
("Fish and Chips","main",19,True),
("Irish Nachos","starter",14,False),
("Burger","main",18,False)
]
},

{
"name":"Juniper Food + Wine",
"description":"Upscale farm-to-table dining experience",
"price_tier":"$$$",
"atmosphere":"romantic",
"pace":"slow",
"social_style":"date night",
"serves_alcohol":True,
"tags":[("fine dining","cuisine"),("wine","drink"),("romantic","vibe")],
"menu":[
("Local Scallops","main",32,True),
("Duck Breast","main",35,False),
("Seasonal Risotto","main",28,False)
]
},

{
"name":"Troy Restaurant",
"description":"Mediterranean tapas restaurant with vibrant atmosphere",
"price_tier":"$$",
"atmosphere":"energetic",
"pace":"medium",
"social_style":"friends",
"serves_alcohol":True,
"tags":[("mediterranean","cuisine"),("tapas","food"),("cocktails","drink")],
"menu":[
("Falafel Plate","main",16,False),
("Chicken Shawarma","main",18,True),
("Hummus","starter",9,False)
]
},

{
"name":"Tan Coffee",
"description":"Minimalist specialty coffee shop",
"price_tier":"$",
"atmosphere":"quiet cafe",
"pace":"slow",
"social_style":"solo",
"serves_alcohol":False,
"tags":[("coffee","drink"),("cafe","cuisine"),("study spot","vibe")],
"menu":[
("Flat White","drink",4.5,True),
("Espresso","drink",3,False),
("Croissant","bakery",4,False)
]
},

{
"name":"Joe's Food Emporium",
"description":"Local deli and sandwich shop",
"price_tier":"$",
"atmosphere":"casual",
"pace":"fast",
"social_style":"quick bite",
"serves_alcohol":False,
"tags":[("sandwiches","food"),("deli","cuisine"),("takeout","vibe")],
"menu":[
("Turkey Club","main",12,True),
("BLT Sandwich","main",10,False),
("Soup of the Day","starter",7,False)
]
},

{
"name":"Noodle Guy",
"description":"Asian noodle restaurant popular for ramen",
"price_tier":"$$",
"atmosphere":"casual",
"pace":"medium",
"social_style":"friends",
"serves_alcohol":False,
"tags":[("asian","cuisine"),("noodles","food"),("ramen","food")],
"menu":[
("Tonkotsu Ramen","main",16,True),
("Chicken Ramen","main",15,False),
("Gyoza","starter",8,False)
]
},

{
"name":"Library Pub",
"description":"Classic student pub near campus",
"price_tier":"$",
"atmosphere":"lively",
"pace":"fast",
"social_style":"students",
"serves_alcohol":True,
"tags":[("pub","cuisine"),("beer","drink"),("students","vibe")],
"menu":[
("Pub Burger","main",15,True),
("Chicken Wings","starter",13,False),
("Poutine","main",11,False)
]
},

{
"name":"Charts Cafe",
"description":"Cozy cafe with baked goods",
"price_tier":"$",
"atmosphere":"cozy",
"pace":"slow",
"social_style":"casual",
"serves_alcohol":False,
"tags":[("cafe","cuisine"),("bakery","food"),("coffee","drink")],
"menu":[
("Latte","drink",4.5,True),
("Blueberry Muffin","bakery",4,False),
("Quiche","main",10,False)
]
},

{
"name":"Lightfoot & Wolfville Vineyards Restaurant",
"description":"Winery restaurant with vineyard views",
"price_tier":"$$$",
"atmosphere":"scenic",
"pace":"slow",
"social_style":"romantic",
"serves_alcohol":True,
"tags":[("wine","drink"),("fine dining","cuisine"),("vineyard","vibe")],
"menu":[
("Local Cheese Board","starter",22,True),
("Steak Frites","main",34,False),
("Seafood Chowder","main",26,False)
]
}

]

for r in restaurants:

    restaurant = Restaurant(
        name=r["name"],
        description=r["description"],
        city="Wolfville",
        price_tier=r["price_tier"],
        atmosphere=r["atmosphere"],
        pace=r["pace"],
        social_style=r["social_style"],
        serves_alcohol=r["serves_alcohol"]
    )

    session.add(restaurant)
    session.commit()

    for tag_name,category in r["tags"]:
        tag=get_or_create_tag(tag_name,category)
        restaurant.tags.append(tag)

    for item in r["menu"]:
        name,category,price,signature=item
        menu=MenuItem(
            restaurant_id=restaurant.id,
            name=name,
            category=category,
            price=price,
            is_signature=signature
        )
        session.add(menu)

    session.commit()

print("database seeded with real wolfville restaurants")

PYTHON
