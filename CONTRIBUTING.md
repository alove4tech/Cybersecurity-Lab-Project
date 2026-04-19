# Contributing

This is a personal homelab documentation repo, but suggestions and corrections are welcome.

## What to contribute

- **Typo fixes** — always welcome
- **Detection rule improvements** — if you've tested a variation that works better
- **Documentation clarity** — if something is confusing, a PR explaining it better helps everyone
- **New use case write-ups** — follow the existing structure under `detections/use-cases/`

## What probably won't land

- Major structural reorganizations without prior discussion
- Changes that remove existing documentation
- Tool-specific configs that aren't part of the lab stack (Wazuh, pfSense, AD)

## Format conventions

- Markdown everywhere
- Follow the naming pattern for new files (`uc-NNN-`, `pb-NNN-`, `cs-NNN-`)
- Keep ATT&CK mappings specific (technique + sub-technique where applicable)

## Commit style

Short, first-person, casual. Like you're writing a changelog for yourself.

```
fix typo in UC-003 thresholds section
add kerberos anomaly detection use case
```
