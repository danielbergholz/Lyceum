---
name: ui-and-assets
description: Phoenix 1.8 layout/component conventions, Tailwind v4 + asset bundling rules, and UI/UX design principles. Use when building or styling any UI — writing a LiveView template, picking an icon or input component, editing app.css/app.js, adding a vendor dependency, or making a design decision. Triggers on Layouts.app, current_scope, flash_group, <.icon>, hero-, <.input>, core_components, Tailwind, daisyUI, @apply, app.css, app.js, @source, vendor script, inline script, micro-interaction, hover, transition, responsive design.
when_to_use: Any visual, markup, or asset work — layouts, shared components, icons, inputs, Tailwind/CSS, the JS/CSS bundle, or design polish. For HEEx syntax mechanics use phoenix-foundations; for LiveView JS hooks use phoenix-liveview; for deciding client vs server on an interaction use liveview-interactions.
paths: lib/lyceum_web/**/*.heex, lib/lyceum_web/components/**/*.ex, assets/css/**/*.css, assets/js/**/*.js
---

# UI and assets

## Layout and components

- LiveView templates **always** begin with `<Layouts.app flash={@flash} ...>`, which wraps all inner content. `LyceumWeb.Layouts` is aliased in `lyceum_web.ex` — don't re-alias it.
- A missing `current_scope` assign means the routes are in the wrong `live_session`, or `current_scope` wasn't passed to `<Layouts.app>`. Fix the route placement rather than working around the assign.
- `<.flash_group>` lives in the `Layouts` module (Phoenix 1.8 moved it there). Calling it anywhere outside `layouts.ex` is **forbidden**.
- Icons: **always** use `<.icon name="hero-x-mark" class="w-5 h-5" />` from `core_components.ex`. **Never** use `Heroicons` modules.
- Inputs: **always** use the imported `<.input>` component. If you override `class`, no defaults are inherited — your classes must fully style the input.
- `show/2` and `hide/2` in `core_components.ex` wrap `JS.show`/`JS.hide` with the app's transitions and are imported into every template. They're the canonical way to open and close things client-side.

## Tailwind v4 and bundling

- Tailwind v4 needs **no** `tailwind.config.js`. Keep the `app.css` import block intact:

  ```css
  @import "tailwindcss" source(none);
  @source "../css";
  @source "../js";
  @source "../../lib/lyceum_web";
  ```

- **Never** use `@apply` in raw CSS.
- Only `app.js` and `app.css` are bundled. You **cannot** reference an external vendor `src` or `href` from a layout — import vendor deps into `app.js` / `app.css` instead.
- **Never** write inline `<script>` tags in HEEx. Use colocated hooks — see the `phoenix-liveview` skill.

## Design

Lyceum ships with daisyUI available, but write your own Tailwind-based components rather than leaning on daisyUI defaults — the product should have its own look, not the look of every daisyUI app.

- Usability first, then aesthetics. Favor clear, conventional patterns over clever or surprising ones.
- Add subtle micro-interactions: button hover states, smooth transitions.
- Keep typography, spacing, and layout balance clean for a refined feel.
- Sweat the details that signal quality — hover effects, loading and empty states, smooth transitions between views.
- This is a learning platform used by instructors and students for long stretches at a time. Optimize for reading comfort and low friction on repeated tasks over visual novelty.
