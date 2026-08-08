#!/usr/bin/env bash
# Runs once after the container is created. Idempotent: safe to re-run with
# `Dev Containers: Rebuild Container` or by hand.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

TARGET_BRANCH="${UG_SUBMODULE_BRANCH:-main}"

echo "[+] Ensuring the cache volumes are writable"
# Belt and braces for the chown in the Dockerfile: a volume that was first
# created by an older image keeps its root-owned mount point across rebuilds,
# and npm then fails with EACCES on ~/.npm/_cacache.
for cache_dir in "${HOME}/.npm" "${HOME}/.cache/pip"; do
    sudo mkdir -p "${cache_dir}"
    [ -O "${cache_dir}" ] || sudo chown -R "$(id -u):$(id -g)" "${cache_dir}"
done

echo "[+] Marking the workspace as a safe git directory"
# The bind-mounted checkout is owned by the host uid, which git otherwise refuses
# to touch. Without this, `git submodule update` fails with "dubious ownership".
git config --global --add safe.directory "${REPO_ROOT}"
git config --global --add safe.directory '*'

echo "[+] Initializing content submodules (branch: ${TARGET_BRANCH})"
# build_init.sh walks the whole tree:
#   sphinx/source -> neteye-userguide-content
#                    |-> nep, satayo, troubleshooting
# It falls back to main when the requested branch does not exist in a submodule.
sh ./build_init.sh "${TARGET_BRANCH}"

echo "[+] Installing Sphinx toolchain into ${VIRTUAL_ENV:-/opt/ug-venv}"
python3 -m pip install --upgrade pip
python3 -m pip install -r ./sphinx/requirements_dev.txt

if command -v npm >/dev/null 2>&1; then
    echo "[+] Installing Playwright test dependencies"
    (
        cd src/t/playwright
        npm ci --no-audit --no-fund
        # Browsers are ~400 MB; skip with UG_SKIP_PLAYWRIGHT_BROWSERS=1
        if [ "${UG_SKIP_PLAYWRIGHT_BROWSERS:-0}" != "1" ]; then
            npx playwright install --with-deps chromium
        else
            echo "[i] Skipping browser download (UG_SKIP_PLAYWRIGHT_BROWSERS=1)"
        fi
    )
else
    echo "[i] npm not found, skipping Playwright setup"
fi

cat <<EOF

[+] Ready.

    ug serve       live reload on http://localhost:8000
    ug build       one-shot static build into sphinx/build/html
    ug build -s    same, but -W (treat warnings as errors, like CI)
    ug static      serve an existing build on http://localhost:8001
    ug --help      all commands and options

    prek run --all-files    run the lint hooks

    Version currently selected: UG_NETEYE_VERSION=${UG_NETEYE_VERSION:-unset}

EOF
