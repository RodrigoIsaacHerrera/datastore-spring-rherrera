# Runbook: sincronizar y publicar ramas

La operación completa se ejecuta con [`sync-push.sh`](./sync-push.sh). Este
orquesta [`sync-validate.sh`](./sync-validate.sh) y
[`sync-branches.sh`](./sync-branches.sh) en ese orden: valida y empareja ramas,
integra cambios localmente y luego publica.

## Requisitos

- Ejecutar desde Git Bash con Bash instalado.
- Ejecutar desde un repositorio Git que tenga configurado el remoto indicado.
- Tener el árbol de trabajo limpio y no tener un merge o rebase en curso.
- La rama objetivo debe existir localmente o en el remoto.

## Uso

```bash
# Solo valida las ramas y crea ramas locales de seguimiento donde falten.
bash sync-validate.sh main

# Sincroniza las ramas localmente, sin publicar.
bash sync-branches.sh main

# Ejecuta la cadena completa contra origin: valida, sincroniza localmente y publica.
bash sync-push.sh main

# Ejecuta la cadena completa usando otro remoto.
bash sync-push.sh develop upstream
```

El remoto predeterminado es `origin`. Cambia `main` o `develop` por la rama que
debe propagarse a las demás.

## Cadena de ejecución

1. **`sync-push.sh <rama-objetivo> [remoto]`** valida argumentos y llama los
   siguientes scripts.
2. **`sync-validate.sh`** hace fetch y prune del remoto. Si hay una rama remota
   sin contraparte local, crea una rama local con seguimiento. Si hay una rama
   solo local, la deja lista para que el push cree su contraparte remota.
3. **`sync-branches.sh <rama-objetivo> [remoto]`** integra en cada rama local
   tanto su contraparte remota como la rama objetivo, preservando commits por
   medio de merge.
4. **`sync-branches.sh <rama-objetivo> <remoto> --push`** repite la comprobación
   de actualizaciones remotas y publica todas las ramas procesadas. No utiliza
   `--force`.

Las ramas `backup-*` y `backup/*` se excluyen de la sincronización y publicación
masivas para preservar respaldos locales.

## Si ocurre un conflicto

El script se detiene en la rama donde ocurrió el conflicto. En esa rama:

```bash
# Muestra los archivos que necesitan resolución.
git status

# Después de resolver los conflictos, marca los archivos como resueltos.
git add <archivos-resueltos>

# Completa el merge pendiente.
git commit
```

Después de resolverlo y confirmar que el árbol está limpio, vuelve a ejecutar
`bash sync-push.sh <rama-objetivo> [remoto]`. Las ramas procesadas antes del
conflicto ya tendrán sus merges aplicados.

Si el push falla por un rechazo non-fast-forward, el remoto recibió commits
nuevos durante la operación. No uses force-push; vuelve a ejecutar el script
después de revisar el rechazo. Si un push fue aceptado antes de que otro
fallara, la siguiente ejecución vuelve a integrar esas actualizaciones.

## Verificar los resultados

```bash
# Muestra el seguimiento y el ahead/behind de ramas locales.
git branch -vv

# Cuenta commits exclusivos entre dos ramas locales.
git rev-list --left-right --count rama-a...rama-b

# Compara las puntas de las ramas locales después del proceso.
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/heads/
```

Con la estrategia de merge, cada rama incorpora la rama objetivo y su
contraparte remota, pero puede conservar commits propios; por eso no todas
necesariamente terminan con el mismo hash.
