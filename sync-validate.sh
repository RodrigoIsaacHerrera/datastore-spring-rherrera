#!/usr/bin/env bash
set -Eeuo pipefail

# Muestra cómo indicar la rama objetivo y el remoto.
usage() {
  cat <<'EOF'
Uso:
  bash sync-validate.sh <rama-objetivo> [remoto]

Ejemplos:
  bash sync-validate.sh main
  bash sync-validate.sh develop upstream

El remoto predeterminado es origin. Las ramas remotas sin contraparte local
se crean localmente con seguimiento; las ramas solo locales se dejan para
que sync-push.sh las publique después de sincronizarlas.
EOF
}

# Valida argumentos antes de consultar o modificar el repositorio.
if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 2
fi

target=$1
remote=${2:-origin}

# Sitúa el proceso en la raíz del repositorio.
repo_root=$(git rev-parse --show-toplevel) || {
  printf 'Error: ejecuta este script desde un repositorio Git.\n' >&2
  exit 1
}
cd "$repo_root"

# Requiere un árbol limpio para que la creación de ramas sea segura.
if [[ -n $(git status --porcelain) ]]; then
  printf 'Error: hay cambios sin guardar. Confírmalos o guárdalos aparte antes de continuar.\n' >&2
  exit 1
fi

# Rechaza nombres de rama mal formados y remotos inexistentes.
if ! git check-ref-format --branch "$target" >/dev/null; then
  printf 'Error: nombre de rama objetivo no válido: "%s".\n' "$target" >&2
  exit 2
fi
if ! git remote get-url "$remote" >/dev/null 2>&1; then
  printf 'Error: no existe el remoto "%s".\n' "$remote" >&2
  exit 1
fi

# Actualiza la lista de ramas del remoto antes de crear las parejas locales.
git fetch "$remote" --prune

# Crea una rama local con seguimiento por cada rama remota que aún no tenga pareja.
remote_refs=()
while IFS= read -r ref; do
  remote_refs+=("$ref")
done < <(git for-each-ref --format='%(refname)' "refs/remotes/$remote")

for ref in "${remote_refs[@]}"; do
  branch=${ref#"refs/remotes/$remote"/}
  branch=${branch#/}

  # Omite HEAD, los respaldos y el nombre que colisiona con el remoto.
  if [[ $branch == HEAD || $branch == "$remote" || $branch == backup-* || $branch == backup/* ]]; then
    continue
  fi

  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    printf 'Creando rama local de seguimiento: %s -> %s\n' "$branch" "$ref"
    git branch --track "$branch" "$ref"
  else
    # Configura seguimiento solo cuando la rama todavía no tiene upstream.
    upstream=$(git for-each-ref --format='%(upstream)' "refs/heads/$branch")
    if [[ -z $upstream ]]; then
      git branch --set-upstream-to="$ref" "$branch"
    fi
  fi
done

# Confirma que la rama objetivo exista localmente o en el remoto tras la validación.
if ! git show-ref --verify --quiet "refs/heads/$target" &&
  ! git show-ref --verify --quiet "refs/remotes/$remote/$target"; then
  printf 'Error: la rama objetivo "%s" no existe localmente ni en "%s".\n' "$target" "$remote" >&2
  exit 1
fi

# Informa de ramas locales que aún no tienen pareja remota; sync-push las publicará.
while IFS= read -r branch; do
  branch=${branch#refs/heads/}
  case "$branch" in
    "$remote"|backup-*|backup/*)
      continue
      ;;
  esac

  if ! git show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
    printf 'Rama solo local; se creará en "%s" durante el push: %s\n' "$remote" "$branch"
  fi
done < <(git for-each-ref --format='%(refname)' refs/heads/)

printf 'Validación completada para "%s" y remoto "%s".\n' "$target" "$remote"
