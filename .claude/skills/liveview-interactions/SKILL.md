---
name: liveview-interactions
description: Decide whether a LiveView interaction belongs on the client or the server. Default to client-only for any pure UI state change — modal/dropdown/popover/overlay visibility, tab switching, expand/collapse, theme toggle, copy-to-clipboard, hover state, prefill from per-row data. Cross the websocket only when the server's response would actually change what the user sees. Triggers on phx-click, JS.show, JS.hide, JS.push, JS.toggle, modal, dropdown, dialog, popover, overlay, tab strip, accordion, edit button, delete button, colocated hook, prepare_, open_, close_.
when_to_use: Adding or modifying any LiveView interaction — buttons, toggles, dialogs, dropdowns, tab strips, anything wired up with phx-click or JS. Also when reviewing your own diff before declaring a UI task done.
paths: lib/lyceum_web/**/*.ex, lib/lyceum_web/**/*.heex
---

# Client or server?

## Core principle

LiveView's websocket is fast but not free. Every `phx-*` event is a server roundtrip — render, diff, patch. For UI state the server doesn't need to know about, that's wasted latency, and the UX feels sluggish.

**The decision test:** *would the server's response change what the user sees?*

- **No** → client-side. Use `Phoenix.LiveView.JS` commands straight from `phx-click`, or the `show/2` / `hide/2` helpers in `LyceumWeb.CoreComponents`, or a colocated hook. No `handle_event`, no `:foo_open?` assign.
- **Yes** → server-side. `phx-click="event_name"` with a `handle_event/3` is correct.

**Always client-side** — the server doesn't need to know:

- Opening and closing modals, dropdowns, popovers, overlays
- Switching tabs when all panels are already in the DOM (not lazy-loaded)
- Expand/collapse on accordions or "show more" panels
- Theme toggles
- Copy-to-clipboard
- Focusing or blurring inputs
- Carrying per-row data into a shared dialog (bake it into `data-*` attrs at render time, read it in a colocated hook on open)

**Requires the server:**

- Mutations (save, delete, enroll, publish)
- Loading data not yet in the DOM (paginate, search, filter)
- Validation feedback driven by the server's view of state
- Anything where the dialog's *content* depends on a fresh query

## Forbidden patterns

WRONG — uses the server to flip visibility:

```heex
<button phx-click="open_edit_modal">Edit</button>
```
```elixir
def handle_event("open_edit_modal", _, socket), do: {:noreply, assign(socket, edit_open?: true)}
```

WRONG — pushes to the server to "prepare" data that's already on the page:

```heex
<button phx-click={JS.push("prepare_delete", value: %{id: @id}) |> JS.show(to: "#delete-dialog")}>
```

WRONG — server roundtrip with no `JS.show`, then `push_event` back to open:

```elixir
def handle_event("prepare_archive", %{"id" => id}, socket) do
  {:noreply, socket |> assign(:archive_id, id) |> push_event("archive-dialog:open", %{})}
end
```

## Right patterns

**Open and close from `phx-click`** — `show/2` and `hide/2` in `LyceumWeb.CoreComponents` wrap `JS.show`/`JS.hide` with the app's transitions and are imported into every template:

```heex
<button phx-click={show("#edit-modal")}>Edit</button>
<button phx-click={hide("#edit-modal")}>Cancel</button>
```

For a plain show/hide without transitions, `JS.show(to: "#id", display: "flex")` and `JS.hide(to: "#id")` work too.

**Per-row data into a shared dialog** — bake the data into `data-*` attrs at server-render time, then read it on open from a colocated hook. One dialog in the DOM instead of one per row, and no roundtrip just to learn which row was clicked. Hook mechanics are in the `phoenix-liveview` skill.

**Closing after a successful mutation** — when a `handle_event/3` mutates and then needs to close a dialog the client opened, call `push_event(socket, "<dialog-id>:close", %{})` and have a colocated hook on the dialog clear the inline `display`. Don't try to close it by re-asserting a class — see the first gotcha.

## Gotchas

- `JS.show`/`JS.hide` set an inline `style="display:..."` that **persists across LiveView diffs**. If you opened with `JS.show` and the server then re-renders, you must clear the inline display on success — flipping a class won't override an inline style. Clear `el.style.display` from a hook triggered by `push_event("<id>:close", %{})`.
- A modal with `backdrop-blur` — or any element that establishes a containing block — will **clip** anything `position: fixed` rendered inside it. Render overlays and modals at the top level of `render/1`, never nested inside a blurred or transformed container.
- Setting `el.style.display` directly from a hook bypasses LiveView's tracking and gets stripped on the next re-render. Go through `JS.show` / `JS.hide`, or `push_event` plus a hook.

## Before declaring a UI task done

Grep your diff for:

- `phx-click="(open|close|show|hide|prepare|toggle)_`
- `JS.push("(open|close|show|hide|prepare)_`
- `:foo_open?` / `:foo_visible?` assigns paired with `handle_event("open_foo", ...)`

Any hit is a regression unless the server genuinely needs to know.
