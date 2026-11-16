# Contribuir a PrronClick

¡Gracias por querer contribuir!

## Licencia de tus contribuciones

PrronClick se publica bajo la **GPL-3.0-or-later** con los permisos
adicionales de [`LICENSE-EXCEPTION.md`](LICENSE-EXCEPTION.md). Estos
permisos permiten enlazar con LinkKit y distribuir la app por la App Store.

Al contribuir, aceptas que tu código se publique bajo esa misma licencia,
**permisos adicionales incluidos**.

## Developer Certificate of Origin (DCO)

No pedimos CLA. Cada commit debe llevar la firma del
[Developer Certificate of Origin 1.1](https://developercertificate.org/).
Con ella certificas que escribiste el código, o que tienes derecho a
aportarlo bajo la licencia del proyecto.

Para firmar, haz commit con `-s`:

```bash
git commit -s -m "Tu mensaje"
```

Eso añade al final del mensaje una línea como esta:

```
Signed-off-by: Tu Nombre <tu@email.com>
```

El nombre y el email deben ser reales y coincidir con los del autor del commit.
Un check automático rechaza los PRs que tengan commits sin firmar.

Si olvidaste firmar el último commit:

```bash
git commit --amend -s --no-edit
```

Para firmar todos los commits de tu rama:

```bash
git rebase --signoff main
```

## Dependencias

No añadas código ni librerías **GPL de terceros** al build de iOS. No están
cubiertas por nuestros permisos adicionales y romperían la distribución por la
App Store. Las librerías con licencias permisivas (MIT, BSD, Apache-2.0, zlib)
sí son compatibles. Si tienes dudas, pregunta en el PR.
