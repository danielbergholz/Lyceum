defmodule Mix.Tasks.Skills.Check do
  use Mix.Task

  @shortdoc "Verify .agents/skills mirrors .claude/skills (no cross-harness drift)"

  @moduledoc """
  Guards against drift between the two skill trees that different agent
  harnesses read.

  `.claude/skills` is canonical. `.agents/skills` must expose byte-identical
  content — by default it is a symlink to `.claude/skills`, so they cannot
  diverge. This task still compares the resolved trees so that if the symlink
  is ever replaced by real (and stale) copies, `mix precommit` fails before the
  drift reaches a commit.

  Run directly with `mix skills.check`; it is also part of `mix precommit`.
  """

  @canonical ".claude/skills"
  @mirror ".agents/skills"

  @impl Mix.Task
  def run(_args) do
    unless File.dir?(@canonical) do
      Mix.raise("#{@canonical} is missing — cannot verify skills sync.")
    end

    canonical = read_tree(@canonical)
    mirror = read_tree(@mirror)

    cond do
      canonical == %{} ->
        Mix.raise("#{@canonical} has no files — cannot verify skills sync.")

      canonical == mirror ->
        Mix.shell().info(
          "skills.check: #{@mirror} is in sync with #{@canonical} (#{map_size(canonical)} files)."
        )

      true ->
        report_drift(canonical, mirror)

        Mix.raise("""
        #{@mirror} has drifted from #{@canonical}.

        Both skill trees must be identical so every agent harness reads the same
        skills. Restore the mirror as a symlink with:

            rm -rf #{@mirror} && ln -s ../.claude/skills #{@mirror}
        """)
    end
  end

  # Resolve a one-level symlink so we read the real directory either way.
  defp real_root(root) do
    case File.read_link(root) do
      {:ok, target} -> Path.expand(target, Path.dirname(root))
      _ -> root
    end
  end

  defp read_tree(root) do
    real = real_root(root)

    real
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Map.new(fn path -> {Path.relative_to(path, real), File.read!(path)} end)
  end

  defp report_drift(canonical, mirror) do
    canonical_keys = MapSet.new(Map.keys(canonical))
    mirror_keys = MapSet.new(Map.keys(mirror))

    for f <- MapSet.difference(canonical_keys, mirror_keys),
        do: Mix.shell().error("  missing in mirror: #{f}")

    for f <- MapSet.difference(mirror_keys, canonical_keys),
        do: Mix.shell().error("  extra in mirror:   #{f}")

    for f <- MapSet.intersection(canonical_keys, mirror_keys),
        canonical[f] != mirror[f],
        do: Mix.shell().error("  differs:           #{f}")
  end
end
