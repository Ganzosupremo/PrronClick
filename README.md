# PrronClick

Metrónomo para iOS y Android. Un teléfono hace de **líder**, marca el tempo, y
los demás se conectan por la misma red Wi-Fi para tocar en sincronía.
La sincronización usa [Ableton Link](https://ableton.github.io/link/).

## Clonar

Ableton Link y miniaudio van como submódulos de git. Para descargarlos al clonar:

```bash
git clone --recursive <url-del-repo>
```

Si ya clonaste sin `--recursive`:

```bash
git submodule update --init --recursive
```

Sin los submódulos, el motor nativo (`native/`) no compila.

## Licencia

Copyright (C) 2026 The PrronClick contributors.

PrronClick es software libre bajo la **GNU GPL versión 3 o posterior**
([`LICENSE`](LICENSE)), con permisos adicionales para enlazar con el SDK
LinkKit de Ableton y para distribuir por app stores
([`LICENSE-EXCEPTION.md`](LICENSE-EXCEPTION.md)).

- **Android, iOS y Windows** usan la librería [Ableton Link](https://github.com/Ableton/link)
  (GPLv2+), con una cabecera parcheada en `native/link_patch` (código de sesión).
- Para publicar en el App Store hace falta la licencia propietaria de Link
  (se pide a link-devs@ableton.com): la GPL de Link no es compatible con sus
  condiciones, y el permiso de `LICENSE-EXCEPTION.md` solo cubre nuestro código.

Para contribuir, consulta [`CONTRIBUTING.md`](CONTRIBUTING.md). Usamos DCO
(`git commit -s`).
