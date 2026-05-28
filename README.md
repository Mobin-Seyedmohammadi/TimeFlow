# TimeFlow

CI para compilar el proyecto iOS con GitHub Actions (runner macOS). Esto solo verifica que el proyecto compila; no ofrece simulador interactivo.

## Requisitos
- Repositorio en GitHub
- Acceso a la pestaña Actions

## Pasos para ejecutar CI
1. Empuja la rama a GitHub.
2. Abre el repo en GitHub y ve a Actions.
3. Selecciona el workflow "iOS CI" y revisa el build.

## Ejecutar localmente
Este proyecto necesita macOS y Xcode para ejecutarse o usar el simulador.

## Notas
- El workflow usa `xcodebuild` con el esquema compartido `TimeFlow`.
- No se incluyen tests por defecto.
