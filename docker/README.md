# Nginx proxy for ArchivesSpace

The Nginx proxy provides a single access point for routing to the
ArchivesSpace server applications. It can run in two modes:

- `single`
  - public and staff interfaces are available via the same hostname
- `multi`
  - public and staff interfaces are available via separate hostnames

## Test

```bash
docker compose build
docker compose up
UPSTREAM_HOST=app docker compose up
```

## Publish

```bash
./build_and_push.sh
```
