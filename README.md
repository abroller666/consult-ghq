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
full paths. Selecting one calls `consult-ghq-action`
(default: `project-switch-project`).

## Customization

| Variable              | Default                   | Description                              |
|-----------------------|---------------------------|------------------------------------------|
| `consult-ghq-program` | `"ghq"`                   | Name or path of the ghq executable       |
| `consult-ghq-action`  | `project-switch-project`  | Function called with the selected directory |

Example: open the repository with Dired instead.

```elisp
(setq consult-ghq-action #'dired)
```

## License

MIT
