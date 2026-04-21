#!/bin/sh
# Clone the `crimson` submodule (see .gitmodules).
#
# Env:
#   CRIMSON_GIT_URL   — optional override of clone URL
#   CRIMSON_GIT_REF   — optional branch, tag, or commit. If unset or empty, the clone
#     stays on the remote default branch (avoids assuming `master` vs `main`).
#   CRIMSON_SSH_KEY_PATH — optional path to a private SSH key file. When it exists and
#     is non-empty, the clone URL is used as-is for git+ssh (no HTTPS rewrite). Railway
#     supplies this via Dockerfile RUN + ARG CRIMSON_GIT_SSH_KEY_B64 (see Dockerfiles).

set -eu

url="${CRIMSON_GIT_URL:-}"
if [ -z "$url" ]; then
  url=$(git config -f .gitmodules submodule.crimson.url)
fi

KEY_PATH="${CRIMSON_SSH_KEY_PATH:-/run/secrets/crimson_git_ssh_key}"
identity=/root/.ssh/crimson_git

if [ -f "$KEY_PATH" ] && [ -s "$KEY_PATH" ]; then
  mkdir -p /root/.ssh
  # Dockerfile may already decode the key to $identity; avoid cp onto itself.
  if [ "$KEY_PATH" != "$identity" ]; then
    cp "$KEY_PATH" "$identity"
  fi
  chmod 600 "$identity"
  clone_host=$(printf '%s' "$url" | sed -n 's/^git@\([^:]*\):.*/\1/p')
  if [ -n "$clone_host" ]; then
    ssh-keyscan -t rsa,ecdsa,ed25519 "$clone_host" 2>/dev/null >> /root/.ssh/known_hosts || true
  fi
  export GIT_SSH_COMMAND="ssh -i ${identity} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
  git clone "$url" crimson
else
  case "$url" in
    git@github.com:*)
      gh="${url#git@github.com:}"
      gh="${gh%.git}"
      url="https://github.com/${gh}.git"
      ;;
  esac
  git clone "$url" crimson
fi

if [ -n "${CRIMSON_GIT_REF:-}" ]; then
  git -C crimson checkout "$CRIMSON_GIT_REF"
fi
