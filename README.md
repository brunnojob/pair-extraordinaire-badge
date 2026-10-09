# Git Collaboration Audit

An audit of Git history, authors, co-author trailers, file changes, and collaboration associated with substantive changes.

## Run

Requirements: Python 3.11+ and Git.

```sh
python main.py . --limit 200 > result.json
```

## Behavior

The tool reads existing history. Invalid trailers are included in the report. Badge automation files and artificial logs are excluded from the count of substantive changes.

## Optional report archive

Export a JSON report from the command above, then run `python cloud/sync.py enqueue result.json --project pair-extraordinaire-badge` and `python cloud/sync.py sync`. Synchronization requires `BRUNNODEV_ACCESS_TOKEN` and the external operations API; the local outbox retains unacknowledged reports.

## License

Original source and documentation are MIT licensed; see [LICENSE](LICENSE). Third-party dependencies and media retain their respective terms. Maintained by [Brunno Dev](https://brunnodev.store).
