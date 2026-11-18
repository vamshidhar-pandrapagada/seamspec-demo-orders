# orders-demo

A small orders service (checkout, order lookup, password resets) used to demo
[SeamSpec](https://github.com/seamspec/seamspec): security rules an AI coding agent can't quietly break.

The rules this project keeps are listed by `seamspec spec`. Each one is a plain sentence plus a pytest test
in `.seamspec/tests/`, approved by a person and locked by hash. Hooks, the pre-commit check and CI stop an
agent (or anyone) from breaking or weakening them without an approved supersede.

```bash
uv sync
uv run pytest            # the project's own tests
seamspec verify          # the locked security rules
seamspec spec            # the rules, in plain language
```

Everything is in memory and made up: no real customers, cards or services.

`demo/demo.sh` is the presenter script for a live demo: `demo/demo.sh` (main flow), `demo/demo.sh fallback` (the same guarantees without the agent), `demo/demo.sh reset` (back to the starting state).
