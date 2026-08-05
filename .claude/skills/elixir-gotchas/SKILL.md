---
name: elixir-gotchas
description: Elixir language traps, Mix workflow, and test mechanics for this Phoenix app. Use when writing or debugging any Elixir code, running Mix tasks, or writing tests. Triggers on list index access, variable rebinding in if/case/cond, String.to_atom, DynamicSupervisor/Registry, Task.async_stream, predicate naming, mix test, mix help, mix deps.clean, start_supervised!, Process.monitor, Process.sleep, :sys.get_state, DataCase, ConnCase.
when_to_use: Writing or fixing Elixir code, choosing a Mix task, or writing/debugging ExUnit tests. Not for Ecto/HEEx/router specifics (use phoenix-foundations) or LiveView mechanics (use phoenix-liveview).
paths: lib/**/*.ex, test/**/*.exs, priv/**/*.exs
---

# Elixir gotchas

## Language traps

- Elixir lists **do not support index-based access** through the access syntax:

  ```elixir
  # INVALID
  i = 0
  mylist = ["blue", "green"]
  mylist[i]

  # VALID
  Enum.at(mylist, i)
  ```

  Use `Enum.at/2`, pattern matching, or the `List` module.

- Variables are immutable but can be rebound. For block expressions (`if`, `case`, `cond`) you **must** bind the result — you **cannot** rebind inside the block:

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

- **Never** use map access syntax (`changeset[:field]`) on structs — they don't implement the Access behaviour. Access fields directly (`my_struct.field`) or use the higher-level API (`Ecto.Changeset.get_field/2` for changesets).
- **Never** nest multiple modules in one file. It causes cyclic dependencies and compilation errors.
- Don't call `String.to_atom/1` on user input — atoms aren't garbage collected, so it's a memory leak.
- Predicate functions end in `?` and don't start with `is_`. Reserve `is_*` names for guards.
- OTP primitives like `DynamicSupervisor` and `Registry` need a name in the child spec: `{DynamicSupervisor, name: Lyceum.MyDynamicSup}`, then `DynamicSupervisor.start_child(Lyceum.MyDynamicSup, child_spec)`.
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure — usually with `timeout: :infinity`.
- The standard library covers dates and times (`Time`, `Date`, `DateTime`, `Calendar`). **Never** add a dependency for date/time work unless asked, apart from `date_time_parser` for parsing.

## Mix

- Read a task's docs and options before using it: `mix help task_name`.
- Debug failures by running one file (`mix test test/my_test.exs`) or rerunning the last failures (`mix test --failed`).
- `mix deps.clean --all` is **almost never needed**. Avoid it without a good reason.
- `mix precommit` is the gate before any commit — see AGENTS.md → Verification.

## Tests

Contexts use `Lyceum.DataCase`; LiveViews and controllers use `LyceumWeb.ConnCase`.

- **Always use `start_supervised!/1`** to start processes in tests — it guarantees cleanup between tests.
- **Avoid** `Process.sleep/1` and `Process.alive?/1`:
  - To wait for a process to finish, monitor it and assert on the DOWN message:

    ```elixir
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    ```

  - To synchronize before the next call, use `_ = :sys.get_state(pid)` so you know the process handled prior messages.

For LiveView test assertions (`element/2`, `has_element?/2`, `LazyHTML`), see the `phoenix-liveview` skill.
