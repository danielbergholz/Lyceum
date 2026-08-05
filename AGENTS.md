Phoenix LiveView web application.

Task-specific conventions live as **skills** under `.claude/skills/` — they load by trigger, so read the one that matches before you start. This file holds only the always-true, non-inferable rules; for mechanics, read the code.

## Product scope

Lyceum is an open source, self-hostable learning management system: create courses, teach cohorts, track student progress. It is an early-stage project — the domain is not built yet, so the conventions below are framework-level rather than product-level.

## Stack

- Phoenix 1.8, LiveView 1.1, Elixir 1.20, Erlang/OTP 28 (pinned in `.tool-versions`)
- Tailwind CSS v4 (no `tailwind.config.js`) with daisyUI
- PostgreSQL via Ecto
- `Req` for HTTP — never `:httpoison`, `:tesla`, `:httpc`
- Swoosh mailer (`Lyceum.Mailer`), local mailbox preview at `/dev/mailbox` in dev
- Bandit as the web server

## Verification

After a change:

1. **Write tests for new behavior.** Context functions and LiveView interactions get tests — `Lyceum.DataCase` for contexts, `LyceumWeb.ConnCase` + `Phoenix.LiveViewTest` for LiveViews. Skip tests only for pure markup, copy, or styling changes. Test mechanics: **always** use `start_supervised!/1` to start processes, since it guarantees cleanup between tests; **avoid** `Process.sleep/1` and `Process.alive?/1` — wait on a process with `Process.monitor/1` plus `assert_receive {:DOWN, ^ref, :process, ^pid, :normal}`, and synchronize with `_ = :sys.get_state(pid)`. For LiveView test assertions, see the **`phoenix-liveview` skill**.
2. Run `mix precommit` and fix what it flags. It runs `mix test` last, plus `gettext.extract --check-up-to-date` (run `mix gettext.extract --merge` when POT files are stale), `credo --strict`, `sobelow`, and `skills.check` (the skill trees must stay in sync).
3. For LiveView/UI changes, start the dev server and exercise the feature in the browser — tests don't verify UX.

## Local development

- Bootstrap a fresh checkout with `mix setup`.
- Run the app with `mix phx.server` at `http://localhost:4000`.
- Production builds go through the `Dockerfile` (`mix phx.gen.release --docker` output); `lib/lyceum/release.ex` runs migrations without Mix.

## Commit messages

Explain **what changed** and **why**. A future reader should understand the motivation without reading the diff.

- **Subject**: imperative mood, 72 chars or fewer.
- **Body**: one or two sentences on the *why* — the problem solved, the user-facing impact, or the architectural reason. Skip the body only for purely mechanical changes (gettext refresh, formatting, dependency bumps).

## AI attribution

When an AI agent writes a commit, end the body with a `Co-Authored-By:` trailer naming the model and its context window:

    Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

Use your own model name and co-author address — the line above is the form, not a fixed value. Append reasoning effort inside the parens when you know it. State only what you actually know: omit a field rather than guess the model, effort, or window.

## Mix

- Read the docs and options before using a task: `mix help task_name`.
- Debug failures with `mix test test/my_test.exs`, or rerun the last failures with `mix test --failed`.
- `mix deps.clean --all` is **almost never needed**. Avoid it without good reason.

## Elixir gotchas

Always-true language rules, not task-triggered:

- Elixir variables are immutable but can be rebound. For block expressions (`if`, `case`, `cond`), bind the result to a variable — you **cannot** rebind inside the expression:

```elixir
# INVALID: rebinding inside the `if`; the result never gets assigned
if connected?(socket) do
  socket = assign(socket, :val, val)
end

# VALID: rebind the result of the `if`
socket =
  if connected?(socket) do
    assign(socket, :val, val)
  end
```

- Elixir lists **do not support index-based access** (`mylist[i]`). Use `Enum.at/2` or pattern matching.
- **Never** use map access syntax (`changeset[:field]`) on structs — they don't implement the Access behaviour. Access fields directly (`my_struct.field`) or use the higher-level API (`Ecto.Changeset.get_field/2` for changesets).
- **Never** nest multiple modules in one file — it causes cyclic dependencies and compilation errors.
- Don't call `String.to_atom/1` on user input (memory leak risk).
- Predicate functions end in `?` and don't start with `is_`. Reserve `is_` names for guards.
- OTP primitives like `DynamicSupervisor` and `Registry` need names in the child spec: `{DynamicSupervisor, name: Lyceum.MyDynamicSup}`.
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure — usually with `timeout: :infinity`.
- The standard library covers dates and times (`Time`, `Date`, `DateTime`, `Calendar`). **Never** add a dependency for date/time work unless asked, apart from `date_time_parser` for parsing.

## Phoenix/LiveView basics

- LiveView templates **always** begin with `<Layouts.app flash={@flash} ...>`, which wraps all inner content. `Layouts` is already aliased in `lyceum_web.ex`.
- A missing `current_scope` assign means routes are in the wrong `live_session`, or `current_scope` wasn't passed to `<Layouts.app>`. Fix it by moving the routes, not by working around the assign.
- `<.flash_group>` lives in `Layouts` and is **forbidden** outside `layouts.ex`.
- Use `<.icon name="hero-x-mark" class="w-5 h-5" />` from `core_components.ex` for icons — never `Heroicons` modules.
- Use the imported `<.input>` component for form inputs. If you override `class`, your classes must fully style the input — defaults are not inherited.

## Assets

- Tailwind v4: keep the `app.css` import block intact (`@import "tailwindcss" source(none); @source ...`). **Never** use `@apply` in raw CSS.
- Only `app.js` and `app.css` are bundled. Import vendor deps into those files — never reference an external script `src` or stylesheet `href` from a layout, and never write inline `<script>` tags in HEEx (use colocated hooks — see the **`phoenix-liveview` skill**).

## Design

Aim for polished, responsive interfaces: clean typography, balanced spacing, subtle micro-interactions (hover effects, smooth transitions), and considered loading states. Write your own Tailwind-based components rather than leaning on daisyUI defaults, so the product has its own look.

## Framework reference

Detailed Phoenix, LiveView, HEEx, Ecto, and form patterns live in two skills: **`phoenix-liveview`** (streams, colocated JS hooks, `push_event`, LiveView tests) and **`phoenix-foundations`** (Ecto, HEEx, forms, router). Load the one that matches the work.
