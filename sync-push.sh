#!/usr/bin/env bash
set -Eeuo pipefail

# Muestra la forma de ejecutar la sincronización completa.
usage() {
  cat <<'EOF'
Uso:
  bash sync-push.sh <rama-objetivo> [remoto]

Ejemplos:
  bash sync-push.sh main
  bash sync-push.sh develop upstream

El remoto predeterminado es origin. El proceso valida las parejas de ramas,
sincroniza localmente y finalmente publica sin usar force-push.
EOF
}

# Valida los argumentos antes de iniciar la secuencia de sincronización.
if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 2
fi

target=$1
remote=${2:-origin}

# Resuelve la ruta del repositorio para llamar los otros scripts desde cualquier directorio.
repo_root=$(git rev-parse --show-toplevel) || {
  printf 'Error: ejecuta este script desde un repositorio Git.\n' >&2
  exit 1
}
cd "$repo_root"
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Crea las ramas locales que falten para las referencias remotas y valida el objetivo.
bash "$script_dir/sync-validate.sh" "$target" "$remote"

# Integra las ramas remotas y la rama objetivo en todas las ramas locales normales.
bash "$script_dir/sync-branches.sh" "$target" "$remote"

# Publica el resultado solo después de completar la sincronización local.
bash "$script_dir/sync-branches.sh" "$target" "$remote" --push

printf 'Sincronización completa: ramas locales y remotas actualizadas en "%s".\n' "$remote"
