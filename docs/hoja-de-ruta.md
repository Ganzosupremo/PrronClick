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
5. **Calibración automática de latencia:** hecho. En Ajustes, "Calibrar con
   el líder": un seguidor, con el líder sonando, cambia su click por un tono
   más agudo (2400 Hz) y graba 8 s con el micrófono. Los dos clicks pasan por
   el mismo micrófono, así que su latencia de entrada se anula: la distancia
   entre ambos es lo que este dispositivo va tarde, y se suma al ajuste de
   latencia. No hace falta nada del líder ni del broadcast.
   - Análisis en `native/calibrate.hpp`, probado con grabaciones sintéticas
     (`native/calibrate_test.cpp`): error de menos de 1 ms, también con eco y
     con el líder flojo.
   - Comprobado: el PC con Windows midió 166 ms tarde (a mano habíamos visto
     unos 170); con la corrección, -4 y -5 ms (lo que tarda el sonido entre
     los dos aparatos). El teléfono como seguidor, -3 ms.
   - Si los clicks no dan un desfase estable (80% a menos de 5 ms de la
     mediana), no se aplica nada: líder con click desplazado, otro seguidor
     sonando o ruido. El ataque del click del líder se cuela en nuestra banda;
     se resta antes de buscar nuestros clicks.
   - Límite: errores de más de medio pulso (250 ms a 120 BPM) se confunden;
     calibrar a un tempo moderado y sin otros seguidores sonando.

6. **iOS** (hecho en código, sin probar en un iPhone): el mismo motor C++
   compilado dentro de la app, sin LinkKit (Link es solo cabeceras y ya
   soporta Darwin). Dart lo encuentra con `DynamicLibrary.process()`.
   - `ios/Runner/NativeEngine.mm` incluye `native/engine.cpp` como
     Objective-C++ y `ios/Runner/Miniaudio.m` incluye miniaudio como
     Objective-C. Los ajustes (cabeceras, defines de Link, frameworks, no
     quitar los símbolos `pc_*`) están en `ios/Runner/Engine.xcconfig`.
   - Una sola sesión de audio `PlayAndRecord` (altavoz, Bluetooth A2DP,
     mezcla con otras apps) para el click y el micrófono: si no, abrir el
     micrófono al calibrar pasaría la sesión a `Record` y callaría el click.
   - Latencia de salida: `AVAudioSession.outputLatency + IOBufferDuration`,
     al iniciar y en cada play (un cambio de salida en marcha espera al
     siguiente play).
   - Permiso de micrófono por el mismo canal `prronclick/mic` que Android.
   - Info.plist: red local, micrófono y audio en segundo plano (sigue
     sonando con la pantalla bloqueada).
   - Entitlement `com.apple.developer.networking.multicast`
     (`Runner.entitlements`): sin él iOS bloquea el multicast de Link y el
     broadcast del compás. Apple tiene que concederlo al equipo antes de
     poder firmar: <https://developer.apple.com/contact/request/networking-multicast>.

7. **Tap tempo y cuenta de entrada** (hecho en código, sin oír en un
   dispositivo):
   - Tap tempo: media de los últimos 5 toques; más de 3 s sin tocar empieza
     de nuevo (`tapBpm` en `lib/song.dart`).
   - Cuenta de entrada (Ajustes: 0, 1 o 2 compases): al dar a play y en cada
     cambio de canción del setlist, después de la pausa, suenan compases de
     click en otro tono (1200/750 Hz) que no cuentan para la duración de la
     canción. Es un tramo `countUntil` en las reglas del click, compartido
     en el broadcast (`count`): los seguidores oyen la cuenta del líder, no
     la de su ajuste. El entrenador de tempo no la silencia.
   - Cada setlist puede fijar su propia cuenta (0, 1 o 2) o usar la de
     Ajustes; manda la del setlist mientras está en marcha. Orden en cada
     cambio: pausa en silencio, cuenta, canción.

## Audio con la pantalla apagada (Android) — hecho

- `PlaybackService`: servicio en primer plano (tipo `mediaPlayback`) con
  notificación, wake lock parcial y Wi-Fi lock de baja latencia, para que
  Android no congele la app y Link siga llegando a tiempo.
- La app lo enciende mientras suena el click o mientras comparte (líder o
  seguidor: el seguidor tiene que oír cuando arranca el líder). Lo comprueba
  cada 500 ms porque el play cambia desde muchos sitios.
- Android 12+ solo deja arrancarlo con la app delante; si se niega, se
  reintenta. Se cierra al quitar la app de recientes.
- La notificación tiene un botón **Parar** (también en la pantalla de
  bloqueo). Como líder o en Solo para el click igual que el botón de la app;
  como seguidor primero vuelve a Solo, para no parar a toda la banda.
- Android 13+ pide permiso de notificaciones la primera vez que suena; sin él
  el click sigue sonando con la pantalla apagada, pero no se ve la
  notificación.
- Comprobado en el Samsung: con la pantalla apagada el click siguió sonando, y Parar desde la
  notificación lo detuvo y cerró el servicio.
- Comprobado con el PC como compañero: Parar en el seguidor lo saca de la
  sesión y el líder sigue sonando; Parar en el líder para también al
  seguidor y el teléfono sigue como líder.

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

- iOS: compilar y probar en un iPhone (latencia medida contra la calibración,
  llamadas entrantes que interrumpen el audio, Bluetooth). Con la sesión
  activa el motor sigue corriendo en segundo plano aunque esté parado; pararlo
  si se queda sin sonar ni compañeros.
- Latencia real en Windows (reloj de WASAPI).
- Más adelante: código de sesión para varias bandas en la misma red,
  subdivisiones audibles, secciones dentro de una canción, y
  exportar/importar setlists.

## Herramientas de desarrollo

- `tool/link_smoke.dart`: actúa como líder y comprueba que el tempo es el
  esperado.
- `native/rules_test.cpp`: test de las reglas del click. Se compila con
  `-DPRRONCLICK_TESTS=ON` en `native/CMakeLists.txt`.
- `tool/setlist_smoke.dart`: comprueba que un cambio de canción programado no
  mueve el pulso y que el final del setlist para la música.
- `tool/calibrate_smoke.dart`: sigue al líder y ejecuta la calibración desde
  el PC, imprimiendo cuánto va tarde.
- `native/calibrate_test.cpp`: test del análisis de la calibración (mismo
  `-DPRRONCLICK_TESTS=ON`).
- `tool/latency_probe`: graba el micrófono alineado con Link para medir dónde
  suena cada dispositivo. Se compila con CMake (ver su `CMakeLists.txt`).
