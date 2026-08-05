---
name: phoenix-liveview
description: LiveView mechanics — streams, colocated JS hooks, push_event, and LiveView tests. Use when writing or editing a LiveView module, working with streams (stream/3, stream_insert, stream_delete, phx-update="stream"), wiring up phx-hook or a colocated hook, calling push_event/handleEvent, or writing Phoenix.LiveViewTest assertions. Triggers on LiveView, stream, stream_insert, stream_delete, phx-update, phx-hook, ColocatedHook, push_event, handleEvent, render_submit, render_change, element/2, has_element?, LazyHTML, LiveViewTest.
when_to_use: Writing or editing a LiveView (the *Live module), a LiveComponent, or a LiveView test. Also when wiring up a colocated JS hook or pushing an event from server to client.
paths: lib/lyceum_web/live/**/*.ex, lib/lyceum_web/live/**/*.heex, test/lyceum_web/live/**/*.exs
---

# LiveView mechanics

## Naming and navigation

- LiveViews are named with a `Live` suffix — `LyceumWeb.CourseLive`. The router's `:browser` scope is already aliased with `LyceumWeb`, so write `live "/courses", CourseLive`.
- **Never** use the deprecated `live_redirect` and `live_patch`. In templates use `<.link navigate={href}>` and `<.link patch={href}>`; in LiveViews use `push_navigate` and `push_patch`.
- **Avoid LiveComponents** unless you have a strong, specific need for them.

## LiveView streams

**Always** use streams for collections rather than assigning regular lists — plain lists balloon memory and can terminate the runtime.

- append N items — `stream(socket, :messages, [new_msg])`
- reset with new items (e.g. filtering) — `stream(socket, :messages, [new_msg], reset: true)`
- prepend — `stream(socket, :messages, [new_msg], at: -1)`
- delete — `stream_delete(socket, :messages, msg)`

The template must set `phx-update="stream"` on the parent, give the parent a DOM id, and use the stream id as each child's DOM id:

```heex
<div id="messages" phx-update="stream">
  <div :for={{id, msg} <- @streams.messages} id={id}>
    {msg.text}
  </div>
</div>
```

Streams are **not enumerable** — `Enum.filter/2` and `Enum.reject/2` don't work on them. To filter, prune, or refresh, refetch the data and re-stream the whole collection with `reset: true`:

```elixir
def handle_event("filter", %{"filter" => filter}, socket) do
  messages = list_messages(filter)

  {:noreply,
   socket
   |> assign(:messages_empty?, messages == [])
   |> stream(:messages, messages, reset: true)}
end
```

Streams **do not support counting or empty states**. Track a count in a separate assign. For an empty state, use Tailwind's `only:` variant — this works only when the empty state is the sole HTML block alongside the stream comprehension:

```heex
<div id="tasks" phx-update="stream">
  <div class="hidden only:block">No tasks yet</div>
  <div :for={{id, task} <- @streams.tasks} id={id}>
    {task.name}
  </div>
</div>
```

When an assign changes content *inside* streamed items, you **must** re-stream those items along with the assign:

```elixir
def handle_event("edit_message", %{"message_id" => message_id}, socket) do
  message = Chat.get_message!(message_id)
  edit_form = to_form(Chat.change_message(message, %{content: message.content}))

  # re-insert so the @editing_message_id toggle takes effect for that item
  {:noreply,
   socket
   |> stream_insert(:messages, message)
   |> assign(:editing_message_id, String.to_integer(message_id))
   |> assign(:edit_form, edit_form)}
end
```

**Never** use the deprecated `phx-update="append"` or `phx-update="prepend"`.

## JavaScript interop

Any `phx-hook="MyHook"` that manages its own DOM **must** also set `phx-update="ignore"`, and **must** have a unique DOM id or the compiler raises.

Hooks come in two flavors.

### Colocated hooks (inline)

**Never** write raw `<script>` tags in HEEx — they're incompatible with LiveView. For scripts inside a template, use a colocated hook:

```heex
<input type="text" name="user[phone_number]" id="user-phone-number" phx-hook=".PhoneNumber" />
<script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
  export default {
    mounted() {
      this.el.addEventListener("input", e => {
        let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
        if(match) {
          this.el.value = `${match[1]}-${match[2]}-${match[3]}`
        }
      })
    }
  }
</script>
```

Colocated hook names **must** start with a `.` prefix. They're folded into the `app.js` bundle automatically.

### External hooks

External hooks (`<div id="myhook" phx-hook="MyHook">`) live in `assets/js/` and are passed to the LiveSocket constructor:

```javascript
const MyHook = {
  mounted() { ... }
}
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { MyHook }
});
```

### Pushing events

**Always** rebind or return the socket when calling `push_event/3`:

```elixir
socket = push_event(socket, "my_event", %{...})

# or return it directly
def handle_event("some_event", _, socket) do
  {:noreply, push_event(socket, "my_event", %{...})}
end
```

Pick it up in a hook with `this.handleEvent`:

```javascript
mounted() {
  this.handleEvent("my_event", data => console.log("from server:", data));
}
```

The client pushes to the server with `this.pushEvent`, optionally taking a reply:

```javascript
this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply:", reply));
```

```elixir
def handle_event("my_event", %{"one" => 1}, socket) do
  {:reply, %{two: 2}, socket}
end
```

## LiveView tests

Use `Phoenix.LiveViewTest` for assertions and `LazyHTML` (already included) for querying markup. Forms are driven by `render_submit/2` and `render_change/2`.

- **Never** assert against raw HTML. Use `element/2` and `has_element?/2`: `assert has_element?(view, "#my-form")`.
- **Always reference the DOM ids you put in the template** — that's what these functions select on.
- Favor asserting on key elements over text content, which changes often.
- Test outcomes, not implementation details.
- `Phoenix.Component` functions like `<.form>` may produce different HTML than you expect. Assert against the real output structure.
- Split major cases into small, isolated files. Start with tests that verify content exists, then add interaction tests.

When a selector doesn't match, print the actual HTML but narrow it first:

```elixir
html = render(view)
document = LazyHTML.from_fragment(html)
matches = LazyHTML.filter(document, "your-complex-selector")
IO.inspect(matches, label: "Matches")
```
