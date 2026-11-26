# consult-ghq

Select a [ghq](https://github.com/x-motemen/ghq)-managed repository with
[Consult](https://github.com/minad/consult) and open it as an Emacs project.

## Requirements

- Emacs 29.1+
- consult 1.0+
- `ghq` in `PATH`

## Installation

```elisp
(use-package consult-ghq
  :vc (:url "https://github.com/abroller666/consult-ghq")
  :after consult
  :bind ("C-c g" . consult-ghq))
```

## Usage

`M-x consult-ghq` lists repositories from `ghq list`, annotated with their
full paths. Selecting one opens it as a project and immediately prompts
for a file in it, like `projectile-switch-project`.

With multiple ghq roots, a repository name that exists under more than one
root is shown with its root appended, e.g. `github.com/foo/bar [~/ghq]`.

## Customization

| Variable              | Default                   | Description                              |
|-----------------------|---------------------------|------------------------------------------|
| `consult-ghq-program` | `"ghq"`                   | Name or path of the ghq executable       |
| `consult-ghq-action`  | `consult-ghq-find-file`   | Function called with the selected directory |

Example: show the `project-switch-project` command menu, as before 0.3.0.

```elisp
(setq consult-ghq-action #'project-switch-project)
```

Example: open the repository with Dired instead.

```elisp
(setq consult-ghq-action #'dired)
```

## License

MIT
