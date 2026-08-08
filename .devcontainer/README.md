# Devcontainer: NetEye Userguide

Builds the whole User Guide inside the container. Nothing needs to be
installed on the host beyond Docker (or Podman) and the VS Code Dev
Containers extension.

## Getting started

1. Open the repo in VS Code, then *Dev Containers: Reopen in Container*.
   From the CLI instead: `devcontainer up --workspace-folder .`
2. `post-create.sh` runs automatically and does three things: initializes the
   content submodules via the repo's own `build_init.sh`, installs
   `sphinx/requirements_dev.txt` into `/opt/ug-venv`, and sets up Playwright.
   The first run takes several minutes, mostly submodule checkout (~48 MB of
   `.rst` and images) and the Chromium download.
3. `ug serve` and open <http://localhost:8000>.

## Commands

| Command | What it does |
| --- | --- |
| `ug serve` | `sphinx-autobuild` with live reload on port 8000 |
| `ug build` | one-shot build into `sphinx/build/html` |
| `ug build -s` | same with `-W`, matching the CI pipeline |
| `ug static` | plain HTTP server for an existing build, port 8001 |
| `prek run --all-files` | the repo's lint hooks |

`ug build` and `ug serve` accept `-v/--version`; the defaults come from
`UG_NETEYE_VERSION` and `FEATURE` in `devcontainer.json`. `ug --help` lists
everything.

## Choosing a version

`sphinx/conf.py` refuses to build without `UG_NETEYE_VERSION`, because it derives
version-dependent substitutions from it. The default is pinned to `4.44` in
`devcontainer.json`; change it there, or per invocation:

```bash
ug build -v 4.45
```

To build a documentation branch other than `main`, set `UG_SUBMODULE_BRANCH` and
re-run the bootstrap:

```bash
UG_SUBMODULE_BRANCH=4.45 .devcontainer/post-create.sh
```

## Known limitations

**The production `Dockerfile` in the repo root will not build here.** It pulls a
base image from `docker-si.wuerth-phoenix.com` and fetches dependency-graph SVGs
from `neteye-userguide-deps-graph.apps.rdopenshift.si.wp.lan`. Both are Würth
Phoenix internal. This devcontainer deliberately reproduces only the Sphinx
toolchain, which is the part that matters for writing and reviewing docs.

**`--strict` fails on three warnings** for exactly that reason:
`dependencies-install.svg`, `dependencies-update_upgrade.svg` and
`dependencies-backup.svg` are injected by the production build and are missing
here. Everything else builds warning-free, so `--strict` is still useful for
checking your own changes — just expect those three.

**The version switcher in the theme is empty** unless `versions.json` and
`last_archived_version.json` could be fetched from `neteye.guide` at build time.
The scripts treat this as non-fatal.

**Hooks needing extras:** `hadolint-docker` wants a Docker daemon inside the
container. If you need it, add the docker-in-docker feature to
`devcontainer.json`, or skip it: `prek run --all-files --skip hadolint-docker`.

## Playwright tests

The suite expects a running instance:

```bash
ug build && ug static &
cd src/t/playwright && npx playwright test
```

The bash checks under `src/t/bash/` take the URL as an argument:

```bash
sh src/t/run_tests.sh http://localhost:8001 4.44
```

## Notes on layout

The venv lives at `/opt/ug-venv`, outside the workspace, so a bind-mounted host
checkout stays clean and `git clean -xfd` cannot destroy the interpreter. pip and
npm caches are named volumes, so a container rebuild does not re-download
everything. `sphinx/build` is already in `.gitignore`.
