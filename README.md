# Context-Aware Dining Experience Recommendation Platform

A full-stack web application that helps users discover restaurants, dishes, and drinks based on their preferences, dining history, atmosphere goals, dietary needs, and social context.

## Product Overview

This platform behaves like a personal dining assistant. It supports recommendation flows such as:

- cheap drinks and fast crowd-pleasing food with friends
- romantic dinner
- comfort pasta night
- late night quick bite
- quiet solo meal
- lively social dinner
- specialty cocktail outing

The system collects onboarding preferences, supports structured and natural-language recommendation modes, and learns from logged dining experiences over time.

## Core Features

### Authentication
- user registration with first name, last name, email, and password
- secure password hashing
- JWT-based login
- protected API routes

### Onboarding
- dietary restrictions
- cuisine preferences
- food texture preferences
- dining pace preferences
- social vs private preference
- drink preferences
- atmosphere preferences
- favorite dining experiences

### Recommendation Modes
- **Build Your Night**: structured input mode
- **Describe Your Night**: natural-language input mode
- **Surprise Me**: profile-based suggestion mode

### Experience Logging
Users can log:
- restaurant
- dishes ordered
- drinks ordered
- ratings
- notes
- context

These logs can later refine recommendation quality.

## Tech Stack

### Backend
- Python
- FastAPI
- SQLAlchemy
- PostgreSQL (Neon)
- JWT authentication
- Passlib + bcrypt password hashing

### Frontend
- React
- TypeScript
- Vite

### Database
- Neon PostgreSQL

## Architecture

This project follows an API-first client-server architecture.

### Backend layers
- `api/` for route definitions
- `services/` for business logic
- `repositories/` for database access
- `models/` for SQLAlchemy models
- `schemas/` for request/response validation
- `core/` for configuration and security
- `db/` for database session and setup

### Frontend responsibilities
- authentication flows
- onboarding UI
- recommendation input pages
- results display
- experience logging
- protected app routing

## Initial Project Structure

```text
context-aware-dining-platform/
├── .env.example
├── README.md
├── backend/
│   ├── requirements.txt
│   └── app/
│       ├── __init__.py
│       ├── main.py
│       ├── api/
│       │   ├── __init__.py
│       │   ├── deps.py
│       │   ├── router.py
│       │   └── routes/
│       │       ├── __init__.py
│       │       ├── auth.py
│       │       ├── experiences.py
│       │       ├── onboarding.py
│       │       ├── recommendations.py
│       │       ├── restaurants.py
│       │       └── users.py
│       ├── core/
│       │   ├── __init__.py
│       │   ├── config.py
│       │   └── security.py
│       ├── db/
│       │   ├── __init__.py
│       │   ├── base.py
│       │   ├── deps.py
│       │   ├── init_db.py
│       │   ├── seed.py
│       │   └── session.py
│       ├── models/
│       │   ├── __init__.py
│       │   ├── experience.py
│       │   ├── restaurant.py
│       │   └── user.py
│       ├── repositories/
│       │   ├── __init__.py
│       │   ├── experience_repository.py
│       │   ├── restaurant_repository.py
│       │   └── user_repository.py
│       ├── schemas/
│       │   ├── __init__.py
│       │   ├── auth.py
│       │   ├── experience.py
│       │   ├── onboarding.py
│       │   ├── recommendation.py
│       │   ├── restaurant.py
│       │   └── user.py
│       └── services/
│           ├── __init__.py
│           ├── auth_service.py
│           ├── experience_service.py
│           ├── onboarding_service.py
│           └── recommendation_service.py
├── frontend/
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.app.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   └── src/
│       ├── App.tsx
│       ├── main.tsx
│       ├── styles.css
│       ├── types.ts
│       ├── components/
│       │   ├── Layout.tsx
│       │   └── ProtectedRoute.tsx
│       ├── context/
│       │   └── AuthContext.tsx
│       ├── lib/
│       │   ├── api.ts
│       │   └── auth.ts
│       └── pages/
│           ├── DashboardPage.tsx
│           ├── ExperiencesPage.tsx
│           ├── LoginPage.tsx
│           ├── OnboardingPage.tsx
│           ├── RecommendationsPage.tsx
│           ├── RegisterPage.tsx
│           └── RestaurantsPage.tsx
└── scripts/
    └── setup_backend.sh
