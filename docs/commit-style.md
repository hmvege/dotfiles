# Commit style

New commits use Conventional Commits:

```text
type(scope): short imperative message

Optional body explaining why the change was needed.
```

Use a lowercase type and scope. The scope names the affected part of the
dotfiles. Examples include `bash`, `zsh`, `tmux`, `vim`, `git`, `macos`,
`ubuntu`, `rocky`, `windows`, `wsl`, `scoop`, `brew`, `vscode`, `chezmoi`,
and `ci`. Pick a new short scope when none fits.

| Type | Use for |
| --- | --- |
| `feat` | Add a tool or behavior, previously `[ADD]` |
| `fix` | Correct broken behavior |
| `docs` | Change documentation |
| `refactor` | Restructure without changing behavior |
| `test` | Change tests |
| `ci` | Change automation |
| `build` | Change build or dependency setup |
| `perf` | Improve performance |
| `style` | Change formatting only |
| `chore` | Routine maintenance |
| `revert` | Undo a change |

Keep the subject within 72 characters, use an imperative verb, and omit
the final full stop. Separate an optional body with a blank line and wrap
its prose at 72 characters. For a breaking change, add `!` after the
scope and explain the impact in a `BREAKING CHANGE:` footer.

```text
fix(windows): refresh PATH before checking installed tools

Reload the environment after Scoop installation so verification
detects tools installed during the current run.
```

Install the local hook once in a checkout with pre-commit available:

```sh
pre-commit install
```

The hook checks the Conventional Commit format and requires a scope.
The length and wording guidance above is not enforced automatically.
Git merge messages are accepted. Older commits retain their original style.
