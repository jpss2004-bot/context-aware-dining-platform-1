#!/bin/bash
set -e

echo "cleaning mac metadata..."
find . -name ".DS_Store" -type f -delete

echo "removing generated frontend artifacts..."
rm -rf frontend/dist
rm -rf frontend/.vite
rm -f frontend/tsconfig.app.tsbuildinfo

echo "removing obvious duplicate files..."
rm -f "package-lock 2.json"
rm -f "playwright.config 2.ts"
rm -f "tests/full-system.spec 2.ts"

echo "removing exported zip bundles..."
rm -f backend.zip
rm -f frontend.zip

echo "removing backups..."
rm -f backend/.env.backup.1773340533
rm -rf backend/backups
rm -rf frontend/backups

echo "creating archive folders for non-runtime helper scripts..."
mkdir -p tools/archive/root
mkdir -p tools/archive/backend
mkdir -p tools/archive/frontend

echo "archiving root helper scripts..."
for f in \
  fix_catalog_and_recommendations.sh \
  fix_frontend_refactor.sh \
  setup_playwright_e2e.sh \
  write_batch1_part2.sh \
  write_batch2.sh \
  write_batch4.sh \
  write_batch5.sh \
  write_frontend_full.sh
do
  [ -f "$f" ] && mv "$f" tools/archive/root/
done

echo "archiving backend helper scripts..."
for f in \
  backend/backend_doctor.sh \
  backend/backend_patch.sh \
  backend/backend_patch_v2.sh \
  backend/fix_backend_database_and_seed.sh \
  backend/fix_backend_db.sh \
  backend/fix_python39_types.sh \
  backend/force_sqlite_dev_db.sh \
  backend/patch_db_stability_v1.sh \
  backend/repair_backend_env.sh \
  backend/seed_real_restaurants.sh \
  backend/write_batch3.sh \
  backend/write_missing_repositories.sh
do
  [ -f "$f" ] && mv "$f" tools/archive/backend/
done

echo "archiving frontend helper scripts..."
for f in \
  frontend/fix_recommendations_422.sh \
  frontend/phase1_part1_shared_ui.sh \
  frontend/phase1_part2_navigation.sh \
  frontend/phase1_part3_layout.sh \
  frontend/phase1_part4_styles.sh \
  frontend/phase1_part5_verify.sh \
  frontend/phase2_part1_restaurant_card.sh \
  frontend/phase2_part2_recommendation_card.sh \
  frontend/phase2_part3_dashboard_page.sh \
  frontend/phase2_part4_recommendations_page.sh \
  frontend/phase2_part5_verify.sh \
  frontend/phase3_full.sh \
  frontend/phase4_part1_shell_polish.sh \
  frontend/phase4_part2_dashboard_recommendations.sh \
  frontend/phase4_part3_restaurants_experiences.sh \
  frontend/phase4_part4_onboarding_auth.sh \
  frontend/phase4_part5_verify.sh \
  frontend/restructure_frontend.sh
do
  [ -f "$f" ] && mv "$f" tools/archive/frontend/
done

echo "cleanup complete."
echo
echo "kept runtime code intact."
echo "did not move backend/app, frontend/src, tests/full-system.spec.ts, package files, or env files."
