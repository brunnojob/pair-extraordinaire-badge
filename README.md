# Git Collaboration Audit

An audit of Git history, authors, co-author trailers, file changes, and collaboration associated with substantive changes.

## Run

Requirements: Python 3.11+ and Git.

```sh
python main.py . --limit 200 > result.json
```

## Behavior

The tool reads existing history. Invalid trailers are included in the report. Badge automation files and artificial logs are excluded from the count of substantive changes.

## Result synchronization

The [operations archive](https://vercel-home-telemetry-api.vercel.app/laboratory.html?project=pair-extraordinaire-badge) stores execution results. Supabase migrations are in the [API repository](https://github.com/brunnojob/vercel-home-telemetry-api/tree/main/supabase/migrations).

```sh
python cloud/sync.py enqueue result.json --project pair-extraordinaire-badge
python cloud/sync.py sync
```

Set `BRUNNODEV_ACCESS_TOKEN` to your session token. The SQLite outbox retains reports until the server confirms persistence; identical content does not create duplicate records. Tokens are not stored in source code. To run the synchronization tests:

```sh
python -m unittest discover -s cloud
```
