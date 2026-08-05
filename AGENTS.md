Phoenix LiveView web application.

Task-specific conventions live as **skills** under `.claude/skills/` (mirrored to `.agents/skills` via symlink). They load by trigger — read the matching one before you start. This file holds only the always-true, non-inferable rules; for mechanics, read the code or load the relevant skill.

## Product scope

Lyceum is an open source, self-hostable learning management system: create courses, teach cohorts, track student progress. It is an early-stage project — the domain is not built yet, so the conventions below are framework-level rather than product-level.

## Stack

- Phoenix 1.8, LiveView 1.1, Elixir 1.20, Erlang/OTP 28 (pinned in `.tool-versions`)
- PostgreSQL via Ecto (`ecto_sql` + `postgrex`)
- Tailwind CSS v4 (no `tailwind.config.js`) with daisyUI, bundled by esbuild — only `app.js` / `app.css` ship
- `Req` for HTTP — **never** `:httpoison`, `:tesla`, or `:httpc`
- Bandit web server, Swoosh mailer (`Lyceum.Mailer`, mailbox preview at `/dev/mailbox` in dev), gettext for i18n, heroicons via `<.icon>`
- App module `Lyceum`; web module `LyceumWeb`

## Commands

- `mix setup` — install deps, set up the DB, build assets
- `mix phx.server` (or `iex -S mix phx.server`) — run the app at `localhost:4000`
- `mix test` — run tests (one file: `mix test test/path_test.exs`; reruns: `mix test --failed`)
- `mix precommit` — **run when you finish a change and fix everything it flags.** Runs `compile --warnings-as-errors`, `skills.check`, `deps.unlock --unused`, `format`, `gettext.extract --check-up-to-date`, `credo --strict`, `sobelow`, then `test`.

## Verification

After a change:

1. **Write tests for new behavior.** Context functions and LiveView interactions get tests — `Lyceum.DataCase` for contexts, `LyceumWeb.ConnCase` + `Phoenix.LiveViewTest` for LiveViews. Skip tests only for pure markup, copy, or styling changes. Test mechanics are in the **elixir-gotchas** skill; LiveView test assertions are in **phoenix-liveview**.
2. Run `mix precommit` and fix what it flags. When it reports stale POT files, run `mix gettext.extract --merge`.
3. For LiveView/UI changes, start the dev server and exercise the feature in the browser — tests don't verify UX.

## Local development

Run `mix setup` to bootstrap a fresh checkout or worktree, then `mix phx.server` at [http://localhost:4000](http://localhost:4000). Concurrent worktrees can each run a server by overriding `PORT`, for example `PORT=4001 mix phx.server`; they share the local development database.

`config/dev.secret.exs` is local, gitignored configuration, auto-loaded by `config/dev.exs` when present. Copy `config/dev.secret.example.exs` to create it, and add a commented entry to that template whenever you wire up a new service, so the shape stays documented. Prod reads the same values from env vars via `config/runtime.exs` — keep the two in step. Worktree tools copy the file through `.worktreeinclude`. **Never** commit it. The app runs stock without it; nothing needs it today.

Production builds go through the `Dockerfile` (`mix phx.gen.release --docker` output); `lib/lyceum/release.ex` runs migrations without Mix.

## Commit messages

Explain **what changed** and **why**. A future reader should understand the motivation without reading the diff.

- **Subject**: imperative mood, 72 chars or fewer.
- **Body**: one or two sentences on the *why* — the problem solved, the user-facing impact, or the architectural reason. Skip the body only for purely mechanical changes (gettext refresh, formatting, dependency bumps).

## AI attribution

When an AI agent writes a commit, end the body with a `Co-Authored-By:` trailer naming the model and its context window:

    Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

Use your own model name and co-author address — the line above is the form, not a fixed value. Append reasoning effort inside the parens when you know it. State only what you actually know: omit a field rather than guess the model, effort, or window.

## Skills

- **elixir-gotchas** — Elixir language traps, Mix workflow, test mechanics
- **phoenix-foundations** — Ecto, HEEx, forms, router scoping
- **phoenix-liveview** — streams, JS hooks, `push_event`, LiveView tests
- **liveview-interactions** — decide client-only vs. server for a LiveView interaction
- **ui-and-assets** — Phoenix 1.8 components, Tailwind v4, asset bundling, design
