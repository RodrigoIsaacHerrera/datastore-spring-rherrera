#!/usr/bin/env bash
set -Eeuo pipefail

# Muestra cómo ejecutar el script y qué opciones acepta.
usage() {
  cat <<'EOF'
Uso:
  ./sync-branches.sh <rama-objetivo> [--push]

Ejemplos:
  ./sync-branches.sh main
  ./sync-branches.sh develop --push

Sin --push, solo actualiza las ramas locales.
Con --push, publica en origin todas las ramas locales actualizadas.
EOF
}

# Termina con un mensaje claro cuando los argumentos no son válidos.
if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 2
fi

target=$1
push_changes=false

# Interpreta la opción que permite publicar las ramas en origin.
if [[ $# -eq 2 ]]; then
  if [[ $2 != "--push" ]]; then
    usage
    exit 2
  fi
  push_changes=true
fi

# Encuentra la raíz del repositorio y ejecuta el resto desde allí.
repo_root=$(git rev-parse --show-toplevel) || {
  printf 'Error: ejecuta este script desde un repositorio Git.\n' >&2
  exit 1
}
cd "$repo_root"

# Exige un árbol limpio para evitar mezclar o perder cambios sin guardar.
worktree_status=$(git status --porcelain)
if [[ -n $worktree_status ]]; then
  printf 'Error: hay cambios sin guardar. Confírmalos o guárdalos aparte antes de continuar.\n' >&2
  exit 1
fi

# Requiere que la rama objetivo exista localmente.
if ! git show-ref --verify --quiet "refs/heads/$target"; then
  printf 'Error: la rama objetivo "%s" no existe localmente.\n' "$target" >&2
  exit 1
fi

# Guarda la rama actual para volver a ella al terminar.
original_branch=$(git branch --show-current)
if [[ -z $original_branch ]]; then
  printf 'Error: HEAD está separado; cambia a una rama antes de ejecutar el script.\n' >&2
  exit 1
fi

# Comprueba que origin exista si se solicitó publicar.
if [[ $push_changes == true ]] && ! git remote get-url origin >/dev/null 2>&1; then
  printf 'Error: no existe un remoto llamado origin.\n' >&2
  exit 1
fi

# Actualiza las referencias remotas para poder integrar los commits recientes
# de origin/<rama-objetivo> antes de propagar la rama objetivo local.
if git remote get-url origin >/dev/null 2>&1; then
  git fetch origin --prune
else
  printf 'Aviso: no hay remoto origin; se trabajará solo con ramas locales.\n'
fi

# Obtiene la lista de ramas locales que se actualizarán.
mapfile -t branches < <(git for-each-ref --format='%(refname:short)' refs/heads/)

# Integra los commits remotos de la rama objetivo sin descartar commits locales.
if git show-ref --verify --quiet "refs/remotes/origin/$target"; then
  git switch "$target"
  git merge --no-edit "origin/$target"
else
  printf 'Aviso: origin/%s no existe; se usará la rama objetivo local.\n' "$target"
fi

# Integra la rama objetivo en cada otra rama local mediante merge.
# Los commits propios de cada rama se conservan; si hay conflictos, el script
# se detiene en esa rama para que puedan resolverse antes de volver a ejecutarlo.
for branch in "${branches[@]}"; do
  if [[ $branch == "$target" ]]; then
    continue
  fi

  git switch "$branch"
  git merge --no-edit "$target"
done

# Vuelve a la rama que estaba activa al iniciar el script.
git switch "$original_branch"

# Publica todas las ramas locales solo cuando se pidió explícitamente --push.
# No se fuerza ningún push; Git rechazará de forma segura cambios divergentes.
if [[ $push_changes == true ]]; then
  git push origin "${branches[@]}"
fi

# Informa si solo se actualizaron las ramas locales o si también se publicaron.
if [[ $push_changes == true ]]; then
  printf 'Listo: se integró "%s" en las ramas locales y se publicaron en origin.\n' "$target"
else
  printf 'Listo: se integró "%s" en las ramas locales.\n' "$target"
fi
