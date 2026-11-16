# Hoja de ruta

## Fases

1. **Interfaz:** pestañas (Metrónomo, Canciones, Setlists), Ajustes, panel de
   Herramientas (con "Compartir click") y persistencia en `library.json`.
   No toca el audio.
2. **Motor y sincronización:**
   - Quantum de Link fijo en 1. El compás lo calcula el motor a partir de un
     pulso de origen, con cambios programados para un pulso futuro.
   - Reglas del click como funciones puras del pulso: click desplazado,
     entrenador de tempo y tramo silenciado. Con test en C++.
   - Broadcast UDP del líder a los seguidores con `{pulso del líder, sonando,
     canción, compás, origen}`.
     - El seguidor calcula la diferencia entera de pulsos con
       `k = floor(miPulso − pulsoLíder + 0,05)`.
     - El seguidor arranca solo si el líder ya está sonando. Link no lo hace.
3. **Canciones:** crear, editar y borrar, y cargarlas en el metrónomo.
4. **Setlists:** avance automático entre canciones (cambio de tempo y de compás
   en el pulso exacto) y pausa entre canciones.
5. **Calibración automática de latencia:** el líder escucha con su micrófono
   los clicks de cada seguidor, los sitúa en la rejilla de Link y le envía la
   corrección por el broadcast. Así los dispositivos que no informan de su
   latencia real (PC, Bluetooth, algunos móviles) quedan alineados sin ajuste
   manual. El método ya está probado con `tool/latency_probe`.

## Comprobado con dispositivos reales

- Link alinea la fase entre dispositivos, pero cada uno numera los pulsos con
  una diferencia entera. Esa diferencia se mantiene constante aunque cambie el
  tempo.
- Cambiar el quantum de Link mientras suena no mueve el pulso.
- Si un seguidor se une a una sesión que ya está sonando, Link no lo arranca.
- La latencia que AAudio informa en un Samsung SM-G780G cuadra con la medida
  por micrófono. En un PC con Windows, la latencia real era unos 170 ms mayor
  que la estimada.

## Pendiente

- iOS: integrar LinkKit, `NSLocalNetworkUsageDescription` y el entitlement de
  multicast.
- Audio con la pantalla apagada (foreground service en Android).
- Latencia real en Windows (reloj de WASAPI) y en iOS
  (`AVAudioSession.outputLatency`).
- Más adelante: código de sesión para varias bandas en la misma red, cuenta de
  entrada, subdivisiones audibles, secciones dentro de una canción, y
  exportar/importar setlists.

## Herramientas de desarrollo

- `tool/link_smoke.dart`: actúa como líder y comprueba que el tempo es el
  esperado.
- `tool/latency_probe`: graba el micrófono alineado con Link para medir dónde
  suena cada dispositivo. Se compila con CMake (ver su `CMakeLists.txt`).
