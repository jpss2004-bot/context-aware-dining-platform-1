from app.schemas.onboarding import (
    OnboardingFieldDefinition,
    OnboardingOptionValue,
    OnboardingOptionsResponse,
)


ONBOARDING_OPTIONS = OnboardingOptionsResponse(
    version="v2-foundation",
    fields=[
        OnboardingFieldDefinition(
            key="cuisine_preferences",
            label="Cuisine preferences",
            description="Choose cuisines you usually enjoy so recommendations can start from familiar options.",
            select_mode="multi",
            optional=False,
            step_order=1,
            options=[
                OnboardingOptionValue(value="italian", label="Italian"),
                OnboardingOptionValue(value="japanese", label="Japanese"),
                OnboardingOptionValue(value="canadian", label="Canadian"),
                OnboardingOptionValue(value="seafood", label="Seafood"),
                OnboardingOptionValue(value="mexican", label="Mexican"),
                OnboardingOptionValue(value="cafe", label="Cafe / Bakery"),
                OnboardingOptionValue(value="pub fare", label="Pub fare"),
                OnboardingOptionValue(value="fast food", label="Fast food"),
            ],
        ),
        OnboardingFieldDefinition(
            key="atmosphere_preferences",
            label="Atmosphere preferences",
            description="Pick the kinds of dining environments you naturally gravitate toward.",
            select_mode="multi",
            optional=True,
            step_order=2,
            options=[
                OnboardingOptionValue(value="cozy", label="Cozy"),
                OnboardingOptionValue(value="romantic", label="Date night"),
                OnboardingOptionValue(value="casual", label="Casual"),
                OnboardingOptionValue(value="upscale", label="Upscale"),
                OnboardingOptionValue(value="family friendly", label="Family friendly"),
                OnboardingOptionValue(
                    value="live music",
                    label="Live music",
                    description="Select this when live performances matter to the experience.",
                ),
                OnboardingOptionValue(
                    value="trivia",
                    label="Trivia night",
                    description="Select this when recurring trivia events matter to the experience.",
                ),
            ],
        ),
        OnboardingFieldDefinition(
            key="dining_pace_preferences",
            label="Dining pace",
            description="Choose whether you usually want a quick stop, a balanced meal, or a slower experience.",
            select_mode="multi",
            optional=True,
            step_order=3,
            options=[
                OnboardingOptionValue(value="quick", label="Quick bite"),
                OnboardingOptionValue(value="steady", label="Balanced pace"),
                OnboardingOptionValue(value="slow", label="Slow experience"),
            ],
        ),
        OnboardingFieldDefinition(
            key="social_preferences",
            label="Who you usually dine with",
            description="This helps rank places better for solo meals, dates, families, and group outings.",
            select_mode="multi",
            optional=True,
            step_order=4,
            options=[
                OnboardingOptionValue(value="solo", label="Solo"),
                OnboardingOptionValue(value="date", label="Date night"),
                OnboardingOptionValue(value="friends", label="Friends / group outing"),
                OnboardingOptionValue(value="family", label="Family"),
                OnboardingOptionValue(value="students", label="Students / budget-conscious"),
            ],
        ),
        OnboardingFieldDefinition(
            key="drink_preferences",
            label="Drink preferences",
            description="Choose drink categories that matter during recommendations.",
            select_mode="multi",
            optional=True,
            step_order=5,
            options=[
                OnboardingOptionValue(value="coffee", label="Coffee"),
                OnboardingOptionValue(value="mocktails", label="Mocktails"),
                OnboardingOptionValue(value="cocktails", label="Cocktails"),
                OnboardingOptionValue(value="wine", label="Wine"),
                OnboardingOptionValue(value="beer", label="Beer"),
            ],
        ),
        OnboardingFieldDefinition(
            key="dietary_restrictions",
            label="Dietary restrictions",
            description="Only choose restrictions that should actively filter recommendations. This step is optional.",
            select_mode="multi",
            optional=True,
            step_order=6,
            options=[
                OnboardingOptionValue(value="vegetarian", label="Vegetarian"),
                OnboardingOptionValue(value="vegan", label="Vegan"),
                OnboardingOptionValue(value="gluten free", label="Gluten free"),
                OnboardingOptionValue(value="dairy free", label="Dairy free"),
                OnboardingOptionValue(value="halal", label="Halal"),
                OnboardingOptionValue(value="nut aware", label="Nut aware"),
            ],
        ),
        OnboardingFieldDefinition(
            key="price_sensitivity",
            label="Budget comfort",
            description="Pick the overall budget feel that suits you most often.",
            select_mode="single",
            optional=True,
            step_order=7,
            options=[
                OnboardingOptionValue(
                    value="budget",
                    label="Budget-conscious",
                    description="Usually looking for lower-cost options.",
                ),
                OnboardingOptionValue(
                    value="balanced",
                    label="Balanced",
                    description="Comfortable with moderate prices.",
                ),
                OnboardingOptionValue(
                    value="premium",
                    label="Premium",
                    description="Comfortable paying more for the right experience.",
                ),
            ],
        ),
        OnboardingFieldDefinition(
            key="budget_range",
            label="Numeric budget range",
            description="A frontend can capture this as min/max spend per person in dollars.",
            select_mode="range",
            optional=True,
            step_order=8,
            options=[],
        ),
    ],
)


def get_onboarding_options() -> OnboardingOptionsResponse:
    return ONBOARDING_OPTIONS
