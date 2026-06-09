---
name: video2website
description: "Convierte un video (screen recording de un diseño, maqueta o sitio existente) en código web funcional (HTML/CSS/JS). Úsalo cuando el usuario tenga un .mp4/.mov/.webm de una página o flujo de UI y quiera recrear ese sitio en código. Recibe la ruta de un video; produce un sitio estático en una carpeta de salida."
argument-hint: "<ruta-del-video> [carpeta-salida]"
---

# video2website

Reconstruye un sitio web en código a partir de un video (grabación de pantalla de un
diseño, prototipo o sitio en vivo). El flujo es: **extraer frames → analizar el diseño
visualmente → generar HTML/CSS/JS → revisar contra el video**.

## Cuándo usar este skill

- El usuario tiene un `.mp4`, `.mov`, `.webm` o `.gif` de una página web o un flujo de UI.
- Quiere el **código** (no solo una descripción) que reproduzca ese diseño.
- Sirve para: clonar una landing, recrear una maqueta de Figma exportada como video,
  reconstruir un sitio del que solo queda una grabación, etc.

## Requisitos

- `ffmpeg` instalado (para extraer frames). Verifica con `ffmpeg -version`.
  - macOS: `brew install ffmpeg` · Debian/Ubuntu: `sudo apt install ffmpeg`
- Si no hay `ffmpeg`, pide al usuario un set de capturas (PNG/JPG) y salta al paso 2.

## Flujo de trabajo

### Paso 1 — Extraer frames del video

Ejecuta el script incluido. Extrae un frame cada N segundos **más** los frames donde
hay cambios de escena (scroll, navegación, transiciones), que son los que revelan
estados distintos de la UI:

```bash
bash scripts/extract_frames.sh "<ruta-del-video>" frames/
```

Esto deja imágenes en `frames/`. Revisa cuántas salieron; si son demasiadas (>40),
quédate con las que muestren estados visualmente distintos.

### Paso 2 — Analizar el diseño (visión)

**Mira los frames** (eres multimodal: ábrelos con la herramienta de lectura de imágenes).
Para cada estado distinto, anota:

- **Layout**: estructura general (header, hero, secciones, grid, footer), columnas,
  alineación, espaciado aproximado.
- **Tipografía**: familias (serif/sans), pesos, tamaños relativos, jerarquía (h1/h2/p).
- **Color**: paleta exacta que puedas inferir (fondo, texto, acentos, botones). Da los
  HEX aproximados.
- **Componentes**: navbar, botones, cards, formularios, tabs, modales, carruseles.
- **Imágenes/íconos**: dónde van; usa placeholders (`https://placehold.co/...`) o SVGs
  simples si no puedes extraer los assets reales.
- **Interacciones visibles en el video**: hover, scroll-reveal, sticky header, menú
  móvil, transiciones, autoplay. Estas definen el **JS** necesario.
- **Responsive**: si el video muestra distintos anchos, anota los breakpoints.

Si algo es ambiguo (texto ilegible, colores poco claros), **pregunta al usuario** o
asume algo razonable y déjalo marcado con un comentario `<!-- TODO: confirmar -->`.

### Paso 3 — Generar el código

Crea el sitio en la carpeta de salida (default: `output/`). Reglas:

1. **HTML semántico** (`<header>`, `<nav>`, `<main>`, `<section>`, `<footer>`).
2. **CSS moderno**: usa variables CSS para la paleta y la tipografía detectadas;
   Flexbox/Grid para el layout; `clamp()` para tipografía fluida.
3. **Mobile-first y responsive** con los breakpoints observados.
4. **JS mínimo y sin dependencias** para las interacciones del video (menú móvil,
   scroll-reveal con `IntersectionObserver`, sticky header, etc.). No metas frameworks
   salvo que el usuario lo pida.
5. **Accesibilidad básica**: `alt` en imágenes, contraste, foco visible, landmarks.
6. Estructura de salida sugerida:
   ```
   output/
     index.html
     css/styles.css
     js/main.js
     assets/   (placeholders o SVGs)
   ```
7. Comenta en el código qué frame/estado representa cada sección.

### Paso 4 — Revisar contra el video

- Vuelve a comparar el resultado con los frames clave: ¿coincide layout, colores,
  jerarquía y las interacciones?
- Lista las diferencias conocidas y los `TODO` (assets reales, textos ilegibles,
  estados que el video no mostró).
- Ofrece al usuario abrirlo: `open output/index.html` (macOS) o servirlo con
  `python3 -m http.server -d output`.

## Notas y límites

- El video da el **aspecto visual**, no el código fuente original: el HTML/CSS será una
  **reconstrucción**, no una copia exacta.
- Assets (imágenes, fuentes de pago, íconos propietarios) no se pueden extraer del video
  con fidelidad: usa placeholders y avísale al usuario.
- Frames borrosos por compresión → confírmalo con el usuario antes de inventar detalles.
- No reproduzcas marcas/logos protegidos como si fueran propios; deja placeholder.

## Ver también

- `scripts/extract_frames.sh` — extracción de frames con ffmpeg (intervalo + cambios de escena).
