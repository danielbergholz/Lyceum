---
name: phoenix-foundations
description: Ecto, HEEx template, form, and Phoenix router mechanics. Use when writing a changeset or schema, generating a migration, building an HEEx template (class lists, interpolation, comments), driving a form from to_form/2, or adding a route to the router. Triggers on Ecto.Changeset, cast, get_field, validate_number, ecto.gen.migration, preload, phx-no-curly-interpolation, <.form, to_form, inputs_for, scope, pipe_through, live "/", HEEx, changeset, migration.
when_to_use: Writing Ecto schemas, changesets, or migrations; HEEx templates; forms with to_form/2 and <.form>; or router scope blocks. Not for LiveView-specific mechanics (streams, hooks, push_event, LiveView tests) — use the phoenix-liveview skill for those.
paths: lib/lyceum/**/*.ex, lib/lyceum_web/**/*.ex, lib/lyceum_web/**/*.heex, priv/repo/migrations/*.exs
---

# Phoenix foundations

## Ecto

- **Always** preload associations that templates will touch — a message rendering `message.user.email` needs the user preloaded in the query.
- Schema fields always use `:string`, even for `:text` columns: `field :name, :string`.
- Fields set programmatically (`user_id`, `role`) must **not** appear in `cast` calls. Set them explicitly when building the struct — listing them is a security hole.
- Access changeset fields with `Ecto.Changeset.get_field(changeset, :field)`.
- `Ecto.Changeset.validate_number/2` has **no `:allow_nil` option**. Validations only run when a change exists and isn't nil, so the option would be meaningless.
- Generate migrations with `mix ecto.gen.migration migration_name_using_underscores` so timestamps and conventions are right.
- Remember to `import Ecto.Query` and any supporting modules in `seeds.exs`.

## Router

`scope` blocks carry an optional alias that prefixes every route inside them. You **never** need your own alias for route definitions:

```elixir
scope "/admin", LyceumWeb.Admin do
  pipe_through :browser

  live "/users", UserLive, :index
end
```

That route points at `LyceumWeb.Admin.UserLive`. Watch for accidental double prefixes.

`Phoenix.View` no longer ships with Phoenix — don't use it.

## HEEx

Templates always use `~H` or `.html.heex` files. **Never** use `~E`.

### Interpolation

`{...}` works in tag attributes and tag bodies. `<%= ... %>` works **only** in tag bodies, and is what you use for block constructs (`if`, `cond`, `case`, `for`).

```heex
<%!-- correct --%>
<div id={@id}>
  {@my_assign}
  <%= if @some_block_condition do %>
    {@another_assign}
  <% end %>
</div>
```

```heex
<%!-- INVALID — syntax error --%>
<div id="<%= @invalid_interpolation %>">
  {if @invalid_block_construct do}
  {end}
</div>
```

### Conditionals

Elixir has `if/else` but **no `else if` or `elsif`**. Use `cond` or `case` for multiple branches:

```heex
<%= cond do %>
  <% condition -> %>
    ...
  <% condition2 -> %>
    ...
  <% true -> %>
    ...
<% end %>
```

### Class lists

Class attrs support lists, and you **must** use `[...]` syntax for multiple values. Wrap any `if` in parens:

```heex
<a class={[
  "px-2 text-white",
  @some_flag && "py-5",
  if(@other_condition, do: "border-red-500", else: "border-blue-100")
]}>Text</a>
```

Omitting the brackets raises a compile syntax error.

### Comprehensions and comments

- **Never** use `<% Enum.each %>` or non-`for` comprehensions to generate content. Use `<%= for item <- @collection do %>` or the `:for` attribute.
- Comments use `<%!-- comment --%>`.

### Literal curly braces

To show `{` or `}` as text (a code snippet in `<pre>` or `<code>`), annotate the parent tag with `phx-no-curly-interpolation`:

```heex
<code phx-no-curly-interpolation>
  let obj = {key: "val"}
</code>
```

Inside that tag, `<%= ... %>` still works for dynamic values.

## Forms

**Always** use `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1`. **Never** `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` — both are outdated.

Build the form with `to_form/2` in the LiveView, then drive everything from the form assign:

```heex
<%!-- ALWAYS --%>
<.form for={@form} id="my-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:field]} type="text" />
</.form>
```

```heex
<%!-- NEVER — accessing the changeset in the template raises --%>
<.form for={@changeset} id="my-form">
  <.input field={@changeset[:field]} type="text" />
</.form>
```

**Never** use `<.form let={f} ...>`. Always give the form an explicit, unique DOM id — tests select on it.

### From params

```elixir
def handle_event("submitted", params, socket) do
  {:noreply, assign(socket, form: to_form(params))}
end
```

A map passed to `to_form/1` is treated as form params, so its keys must be strings. Nest them with `:as`:

```elixir
def handle_event("submitted", %{"user" => user_params}, socket) do
  {:noreply, assign(socket, form: to_form(user_params, as: :user))}
end
```

### From changesets

Data, params, and errors all come off the changeset, and `:as` is computed automatically:

```elixir
%Lyceum.Accounts.User{}
|> Ecto.Changeset.change()
|> to_form()
```

Submitted params then arrive under `%{"user" => user_params}`.

## App-wide imports

For imports and aliases every template should see, add them to the `html_helpers` block in `lyceum_web.ex`. They become available to all LiveViews, LiveComponents, and any module doing `use LyceumWeb, :html`.
