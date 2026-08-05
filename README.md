# Lyceum

Open source, self-hostable learning management system. Create courses, teach
cohorts, and track student progress.

Built with Elixir, Phoenix LiveView, and PostgreSQL.

> **Status: early.** This is a fresh Phoenix scaffold. Nothing below the setup
> steps works yet.

## Why

Most learning platforms are hosted services you rent. Lyceum is meant to be a
system you run yourself, on your own database, with your own data.

## Getting started

You need Elixir 1.20, Erlang/OTP 28, and PostgreSQL. If you use asdf or mise,
`.tool-versions` pins both.

```bash
mix setup          # install deps, create and migrate the database, build assets
mix phx.server     # or: iex -S mix phx.server
```

Then visit [localhost:4000](http://localhost:4000).

Run the tests with `mix test`.

### Local secrets (optional)

Local credentials (OAuth, email, and so on) go in `config/dev.secret.exs`, which
is gitignored and auto-loaded by `config/dev.exs`. Copy the template to get
started:

```sh
cp config/dev.secret.example.exs config/dev.secret.exs
```

No services need this yet, so the app runs without it. Add config as you
integrate third-party services — `config/dev.secret.example.exs` shows the shape.

## Deployment

See the [Phoenix deployment guides](https://phoenix.hexdocs.pm/deployment.html).

## License

MIT
