# Hoja de ruta

## Fases

1. **Interfaz** (hecha): pestañas (Metrónomo, Canciones, Setlists), Ajustes, panel de
   Herramientas (con "Compartir click") y persistencia en `library.json`.
   No toca el audio.
2. **Motor y sincronización** (hecha):
   - Quantum de Link fijo en 1. El compás lo calcula el motor a partir de un
     pulso de origen, con cambios programados para un pulso futuro.
   - Reglas del click como funciones puras del pulso: click desplazado,
     entrenador de tempo. Con test en C++ (`native/rules_test.cpp`).
   - Broadcast UDP (puerto 20809, cada 300 ms) del líder a los seguidores con
     `{pulso del líder, sonando, compás, origen, próximo cambio}`
     (`lib/share.dart`).
     - El seguidor calcula la diferencia entera de pulsos con
       `k = floor(miPulso − pulsoLíder + 0,05)`.
     - El seguidor arranca solo si el líder ya está sonando. Link no lo hace.
3. **Canciones** (hecha): crear, editar y borrar (nombre, tempo, compás y
   duración opcional), y cargarlas en el metrónomo tocándolas.
4. **Setlists** (hecha): listas ordenadas de canciones, con avance automático
   al acabar la duración de cada una. El tempo y el compás cambian en el pulso
   exacto (`pc_schedule_song`) y al final del setlist se para. Botones de
   anterior/siguiente (cambian en el próximo compás). El broadcast añade el
   nombre de la canción y el estado del setlist: los seguidores ven la misma
   tarjeta (setlist, posición, qué sigue y cuándo), sin los botones.
   - Pausa opcional entre canciones: compases en silencio al tempo de la
     siguiente (tramo silenciado `muteUntil` en las reglas del click, también
     compartido con los seguidores).
   - Comprobado con un seguidor sonando: sigue el cambio de canción con la
     fase del compás igual a la del líder.
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
- Con el compás compartido por broadcast, un seguidor que entra tarde arranca
  en menos de 200 ms y su fase dentro del compás coincide con la del líder
  (diferencia de 0,001 pulsos), también al pasar de 3/4 a 5/4 en marcha.
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
- `native/rules_test.cpp`: test de las reglas del click. Se compila con
  `-DPRRONCLICK_TESTS=ON` en `native/CMakeLists.txt`.
- `tool/setlist_smoke.dart`: comprueba que un cambio de canción programado no
  mueve el pulso y que el final del setlist para la música.
- `tool/latency_probe`: graba el micrófono alineado con Link para medir dónde
  suena cada dispositivo. Se compila con CMake (ver su `CMakeLists.txt`).
