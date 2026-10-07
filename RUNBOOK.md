# Runbook: sincronizar ramas locales

El script [`sync-branches.sh`](./sync-branches.sh) integra una rama objetivo en
las demás ramas locales. Conserva los commits propios de cada rama mediante
`git merge`; no reinicia ramas ni usa `git push --force`.

## Requisitos

- Ejecutar desde Git Bash con Bash instalado.
- Estar dentro del repositorio Git.
- Tener un árbol de trabajo limpio. Confirma o guarda aparte los cambios antes
  de ejecutar el script.
- La rama objetivo debe existir localmente.
- Si hay un remoto llamado `origin`, el script actualiza sus referencias con
  `git fetch origin --prune` e integra `origin/<rama-objetivo>` en la rama
  objetivo local antes de propagarla.

## Uso

```bash
# Integra main en todas las ramas locales y no publica cambios.
bash sync-branches.sh main

# Integra develop en todas las ramas locales y luego las publica en origin.
bash sync-branches.sh develop --push
```

Reemplaza `main` o `develop` por cualquier rama objetivo local. La opción
`--push` es opcional y publica en `origin` todas las ramas locales que el script
procesó. Sin esa opción, el script solo cambia las ramas locales.

## Qué hace el script

1. Valida los argumentos y comprueba que se ejecuta dentro de un repositorio.
2. Se detiene si el árbol de trabajo tiene cambios sin guardar o si la rama
   objetivo no existe localmente.
3. Guarda el nombre de la rama activa y actualiza las referencias remotas
   disponibles.
4. Integra `origin/<rama-objetivo>` en la rama objetivo local, si existe.
5. Cambia a cada rama local y ejecuta `git merge <rama-objetivo>`. Los commits
   que solo existan en esa rama se conservan.
6. Vuelve a la rama que estaba activa al inicio.
7. Si se indicó `--push`, publica las ramas procesadas sin forzar los pushes.

Los pasos también están comentados directamente en el script.

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

Cuando todos los conflictos estén resueltos y el árbol vuelva a estar limpio,
vuelve a ejecutar el script con la misma rama objetivo. Las ramas procesadas
antes del conflicto ya tendrán el merge aplicado; Git indicará que están
actualizadas.

## Verificar los resultados

```bash
# Muestra el estado de cada rama local respecto de su rama remota configurada.
git branch -vv

# Compara commits exclusivos entre dos ramas locales.
git rev-list --left-right --count rama-a...rama-b
```

Con la estrategia de merge, las ramas incorporan los commits de la rama
objetivo, pero pueden conservar commits propios y por ello no necesariamente
terminan en el mismo hash.
