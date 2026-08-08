# Devcontainer image for building the NetEye Userguide locally.
#
# This is NOT the production image. The production Dockerfile in the repo root
# needs Wuerth Phoenix internal infrastructure (docker-si.wuerth-phoenix.com base
# image, the dependency-graph endpoint on *.si.wp.lan) and cannot be built from
# outside the corporate network. This image only provides the Sphinx toolchain.
#
# Debian is used instead of the Alpine base of the production image because the
# devcontainer tooling and the VS Code server are far better behaved on glibc.

FROM mcr.microsoft.com/devcontainers/python:1-3.13-bookworm

# The base image ships an apt source for dl.yarnpkg.com whose bundled keyring
# (key 1646B01B86E50310) no longer matches the key Yarn signs the repo with, so
# every apt-get update fails on it. Nothing here needs yarn, so drop the source.
RUN rm -f /etc/apt/sources.list.d/yarn.list

# curl + jq: used by build_and_run.sh / create_nginx_rules.sh / archive_ug_version.sh
# zip: used by archive_ug_version.sh
# shellcheck: matches the pre-commit hook, so lint failures show up before CI
# graphviz: only needed if you add local .dot sources; harmless otherwise
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        jq \
        zip \
        shellcheck \
        graphviz \
        less \
    && rm -rf /var/lib/apt/lists/*

# Mount points for the named cache volumes declared in devcontainer.json. Docker
# creates a missing mount point as root:root, which leaves npm/pip unable to
# write their caches as the vscode user, so pre-create them with the right owner.
RUN mkdir -p /home/vscode/.npm /home/vscode/.cache/pip \
    && chown -R vscode:vscode /home/vscode/.npm /home/vscode/.cache

# A venv outside the workspace, so a bind-mounted host checkout stays clean and
# the interpreter survives `git clean -xfd`.
ENV UG_VENV=/opt/ug-venv
RUN python3 -m venv "${UG_VENV}" \
    && "${UG_VENV}/bin/python" -m pip install --no-cache-dir --upgrade pip \
    && chown -R vscode:vscode "${UG_VENV}"
ENV PATH="${UG_VENV}/bin:${PATH}"

# Linting entrypoint used by .pre-commit-config.yaml. The config relies on prek's
# `builtin` repo, which plain pre-commit rejects, so only prek is installed.
USER vscode
RUN pipx install prek
USER root
