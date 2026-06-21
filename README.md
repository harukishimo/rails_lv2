# SkillEvidenceHub

Internal evaluation support application for declaring skill exams, submitting evidence, requesting reviews, scheduling interviews, and recording qualifications.

## Runtime Policy

- Ruby: see `.ruby-version`
- Rails: 8.1.x
- Primary local DB: SQLite under `storage/`
- DB schema management: Ridgepole with `db/Schemafile` and `db/schemas/tables/*.schema`
- Docker: handled by a later Issue. Local setup is treated as first-class because of workstation storage constraints.

## Setup

```sh
bin/setup --skip-server
```

`bin/setup` installs gems, prepares the Rails database, and applies `db/Schemafile` through Ridgepole.

## Development Server

```sh
bin/dev
```

`bin/dev` starts Rails and `bin/rails tailwindcss:watch[always]` through `Procfile.dev`.
For one-off stylesheet generation, run:

```sh
bin/rails tailwindcss:build
```

Then open:

- Root screen: `http://localhost:3000/`
- Rails health check: `http://localhost:3000/up`

## Verification

```sh
bin/rails -v
bin/rails db:prepare
bin/ridgepole-dry-run
bin/rails test
```

## Quality Gates

Run the same core checks locally before opening or updating a pull request:

```sh
bin/rubocop
bin/rails test
bin/bundler-audit check --update
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
env RAILS_ENV=test bin/ridgepole-dry-run
bin/ci
```

GitHub Actions runs the initial CI workflow defined in `.github/workflows/ci.yml`.

## Notes

- Rails migrations are not the primary application schema workflow.
- Domain table changes should be made in `db/schemas/tables/*.schema`, reviewed with `bin/ridgepole-dry-run`, then applied with `bin/ridgepole-apply`.
- Data migrations should be implemented separately as explicit tasks or dedicated Issues.
- Detailed DB schema operations are documented in `docs/db_schema_operations.md`.
