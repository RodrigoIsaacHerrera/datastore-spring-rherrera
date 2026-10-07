#!/usr/bin/env bash
set -Eeuo pipefail

# Muestra la sintaxis y las opciones soportadas.
usage() {
  cat <<'EOF'
Uso:
  bash sync-branches.sh <rama-objetivo> [remoto] [--push]

Ejemplos:
  bash sync-branches.sh main
  bash sync-branches.sh main origin
  bash sync-branches.sh main origin --push

Sin --push, integra los cambios localmente.
Con --push, publica todas las ramas locales sincronizadas en el remoto.
Las ramas backup-* y backup/* se excluyen del proceso.
EOF
}

# Valida el número de argumentos antes de hacer cualquier operación Git.
if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage
  exit 2
fi

target=$1
remote=origin
push_changes=false
remote_seen=false

# Acepta el remoto y --push en cualquier orden después de la rama objetivo.
for argument in "${@:2}"; do
  if [[ $argument == "--push" ]]; then
    if [[ $push_changes == true ]]; then
      printf 'Error: --push no debe repetirse.\n' >&2
      exit 2
    fi
    push_changes=true
  elif [[ $remote_seen == false ]]; then
    remote=$argument
    remote_seen=true
  else
    printf 'Error: argumento inesperado "%s".\n' "$argument" >&2
    usage
    exit 2
  fi
done

# Resuelve la raíz del repositorio para ejecutar operaciones desde una ubicación estable.
repo_root=$(git rev-parse --show-toplevel) || {
  printf 'Error: ejecuta este script desde un repositorio Git.\n' >&2
  exit 1
}
cd "$repo_root"

# Evita mezclar los merges automáticos con cambios sin guardar.
if [[ -n $(git status --porcelain) ]]; then
  printf 'Error: hay cambios sin guardar. Confírmalos o guárdalos aparte antes de continuar.\n' >&2
  exit 1
fi

# Comprueba el formato del nombre de rama antes de usarlo como referencia.
if ! git check-ref-format --branch "$target" >/dev/null; then
  printf 'Error: nombre de rama objetivo no válido: "%s".\n' "$target" >&2
  exit 2
fi

# Requiere que el remoto exista para traer y, opcionalmente, publicar ramas.
if ! git remote get-url "$remote" >/dev/null 2>&1; then
  printf 'Error: no existe el remoto "%s".\n' "$remote" >&2
  exit 1
fi

# Detiene el proceso si el repositorio ya tiene una operación Git sin terminar.
if [[ -f $(git rev-parse --git-path MERGE_HEAD) ]] ||
  [[ -d $(git rev-parse --git-path rebase-merge) ]] ||
  [[ -d $(git rev-parse --git-path rebase-apply) ]]; then
  printf 'Error: hay un merge o rebase en curso; complétalo o abórtalo antes de continuar.\n' >&2
  exit 1
fi

# Conserva la rama activa para regresar a ella después de recorrer las ramas.
original_branch=$(git branch --show-current)
if [[ -z $original_branch ]]; then
  printf 'Error: HEAD está separado; cambia a una rama antes de ejecutar el script.\n' >&2
  exit 1
fi

# Actualiza las referencias remotas antes de comparar o integrar commits.
git fetch "$remote" --prune

# Confirma que la validación previa creó o encontró localmente la rama objetivo.
if ! git show-ref --verify --quiet "refs/heads/$target"; then
  printf 'Error: la rama objetivo "%s" no existe localmente. Ejecuta sync-validate.sh primero.\n' "$target" >&2
  exit 1
fi

# Construye la lista de ramas normales; se excluyen explícitamente las de respaldo.
branches=()
while IFS= read -r branch; do
  case "$branch" in
    backup-*|backup/*)
      printf 'Omitiendo rama de respaldo: %s\n' "$branch"
      ;;
    *)
      branches+=("$branch")
      ;;
  esac
done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

# Integra primero los commits que existan en la rama objetivo del remoto.
if git show-ref --verify --quiet "refs/remotes/$remote/$target"; then
  git switch "$target"
  git merge --no-edit "$remote/$target"
fi

# Integra en cada rama local su contraparte remota y luego la rama objetivo.
# Los merges conservan commits exclusivos; cualquier conflicto detiene el script.
for branch in "${branches[@]}"; do
  git switch "$branch"

  if git show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
    git merge --no-edit "$remote/$branch"
  fi

  if [[ $branch != "$target" ]]; then
    git merge --no-edit "$target"
  fi
done

# Vuelve a la rama que estaba activa cuando inició el proceso.
git switch "$original_branch"

# Publica todas las ramas procesadas solo si se solicitó expresamente.
if [[ $push_changes == true ]]; then
  git push "$remote" "${branches[@]}"

  # Configura el seguimiento remoto para las ramas que acaba de publicar.
  git fetch "$remote"
  for branch in "${branches[@]}"; do
    if git show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
      git branch --set-upstream-to="$remote/$branch" "$branch" >/dev/null
    fi
  done
fi

# Informa si las ramas se sincronizaron localmente o también se publicaron.
if [[ $push_changes == true ]]; then
  printf 'Listo: se sincronizaron y publicaron las ramas locales en "%s".\n' "$remote"
else
  printf 'Listo: se sincronizaron las ramas locales con "%s".\n' "$remote"
fi
