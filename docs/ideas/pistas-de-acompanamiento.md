# Pistas de acompañamiento (idea aparcada)

> **Estado: fuera del alcance.** PrronClick es un metrónomo para sincronizar a
> varios músicos, no un reproductor de playbacks como Ableton Live o
> LibreTracks. Este diseño se guarda por si algún día se decide hacerlo
> (decisión del 18-11-2026). No hay código escrito.

## 1. Requisitos

**Qué haría**

- Cada canción puede tener **una o varias pistas de audio**: un playback
  completo o stems separados (bajo, teclados, coros, guía…).
- Las pistas suenan **en sincronía exacta con el click**, sobre la misma línea
  de tiempo de Link: cuenta de entrada, cambios de canción del setlist, paro
  al llegar al Outro y seguidores que tengan los mismos archivos.
- Cada pista tiene volumen y mute, y se puede mandar **al PA o solo al
  in-ear** (por ejemplo, una pista guía que solo oye la banda).
- **Salida dividida** opcional para el escenario: izquierda = click, voz y
  pistas de in-ear; derecha = pistas para el PA, en mono. Con un cable en Y,
  el canal derecho va a la mesa y el izquierdo a los in-ears.
- Por canción se guarda **dónde cae el "1"** en el archivo (desplazamiento en
  segundos). Si el audio tiene anacrusa, esta suena durante la cuenta de
  entrada.

**Calidad**

- Pista y click alineados con menos de 1 ms de error: ambos se dibujan en el
  mismo buffer de audio, así que la latencia de salida les afecta igual.
- Sin deriva en una canción de 10 minutos.
- Memoria constante: un stem estéreo de 5 min decodificado ocupa unos 115 MB,
  así que se lee del disco en streaming.
- Nunca se bloquea el hilo de audio.

**Restricciones**

- Sin dependencias nuevas: miniaudio ya decodifica WAV, MP3 y FLAC y
  remuestrea.
- No se toca `third_party/link`.
- Android y Windows (mismo motor); iOS más adelante.

## 2. Arquitectura

```
 Dart                               C++ motor (miniaudio + Link)
 ────                               ───────────────────────────────────────────
 Song.tracks ──▶ AppState           Deck A (canción actual)   Deck B (la siguiente)
   (archivos, volumen, ruta,          ├ Stem 1: decoder ─▶ ring buffer (2 s)
    desplazamiento del 1)             ├ Stem 2: decoder ─▶ ring buffer
        │                             └ …                      ▲
        │ pc_deck_load(rutas)                                   │ hilo lector:
        │ pc_deck_schedule(origen, bpm, desplazamiento)         │ rellena los buffers
        │ pc_deck_mix(stem, volumen, ruta)                      │ (nunca el hilo de audio)
        ▼                                                       │
                                     Callback de audio, por cada frame:
                                       pulso de Link en ese instante (ya existe)
                                       ─▶ posición en el archivo =
                                          desplazamiento + (pulso − origen) × 60/bpm
                                       ─▶ lee del ring buffer, mezcla por ruta
                                       ─▶ L/R normal, o dividida
```

| Decisión | Alternativa | Por qué |
|---|---|---|
| La posición del audio se **deriva del pulso de Link** en cada buffer | Darle play al archivo y dejarlo correr | Cuadran solos el click, la cuenta, los saltos de setlist y los seguidores. El reloj de la tarjeta se desvía ~50 ppm del de Link: 15 ms en 5 min. |
| **Streaming** con ring buffer y un hilo lector | Decodificar todo en RAM | 8 stems × 5 min ≈ 900 MB; con streaming ≈ 6 MB. |
| Precargar el siguiente deck del setlist | Abrirlo al cambiar | Sin hueco entre canciones. |
| **Sin estiramiento de tiempo** | Rubber Band u otra librería | Una pista grabada a 120 solo vale a 120. Estirar añade una dependencia grande y CPU. |

**Corrección de deriva:** en cada buffer se compara la posición real con la
que dice Link. Si se desvían más de 1 ms, se lee un poco más rápido o más
lento (hasta ±0,05 %, interpolación lineal; inaudible). Si se desvían más de
50 ms (por ejemplo, tras una pausa del sistema), se salta con un fundido de
5 ms.

## 3. Detalle

**Datos** (`song.dart`, en el JSON de la biblioteca):

```dart
class Track { String name; String file; double gain; bool muted; bool inEarOnly; }
// en Song:
List<Track> tracks;  double trackOffset;  // segundos del archivo donde cae el "1"
```

- Los archivos se **copian** a la carpeta de la app (`tracks/<songId>/`), para
  que no se rompan si se borra el original y Android no pierda el permiso.
- `Settings.splitOutput` (bool) activa la salida dividida.

**API del motor** (nuevo `native/tracks.hpp` con la parte pura y testeable):

```c
int  pc_deck_load(const char** paths, int n);    // abre y empieza a llenar; devuelve deck id
int  pc_deck_state(int deck);                    // cargando / listo / error (y qué archivo)
void pc_deck_schedule(int deck, double originBeat, double bpm, double offsetSec);
void pc_deck_mix(int deck, int stem, float gain, bool inEarOnly);
void pc_deck_unload(int deck);
void pc_set_split_output(bool on);
```

- Como mucho **2 decks**: la canción actual y la siguiente del setlist.
- Al cambiar de canción, el deck siguiente se programa con el `pendingOrigin`
  que el motor ya conoce: el cambio cae en el mismo pulso que el del click.

**Cuándo calla la pista**

- **Tempo distinto al de la canción** (rampa, tap tempo, alguien cambia el
  tempo en Link): calla y la app avisa "Pistas en pausa: el tempo no es el de
  la canción". Vuelve sola cuando coincide.
- Al **parar** o en el **paro del Outro**: fundido de 10 ms para que no haga
  clic.
- En los compases callados del **gap trainer** la pista sigue: el gap trainer
  solo calla el click.

**Interfaz**

- **Editor de canción**, sección "Pistas": añadir archivos (varios a la vez);
  lista con nombre, volumen, mute y "solo in-ear"; desplazamiento del "1" con
  − y + (a mano).
- **Metrónomo**: si la canción tiene pistas, un botón **Mezcla** abre un panel
  con un deslizador por stem para ajustar en vivo; los cambios se guardan.
- **Ajustes**: "Salida dividida (click a la izquierda, pistas a la derecha)".

## 4. Fiabilidad y riesgos

- **Disco lento:** si el hilo lector no llega, suena silencio (no basura) y se
  registra. Con 2 s de margen y archivos locales no debería pasar.
- **Archivo que falta o no se decodifica:** el deck queda en "error" con el
  nombre del archivo; el click sigue y la app avisa.
- **Batería:** decodificar varios MP3 cuesta poco frente a la pantalla. El
  servicio en segundo plano ya existe.
- **Seguidores:** las pistas no se envían por la red (tamaño). Un seguidor solo
  las oye si tiene los mismos archivos en esa canción.
- **Copias de seguridad:** el JSON guarda la configuración pero no el audio. Al
  restaurar en otro teléfono, la app indica qué archivos faltan.

## 5. Pruebas

- **C++ (`tracks_test.cpp`):** del pulso a la posición en el archivo (anacrusa,
  cuenta de entrada, cambio de canción); corrector de deriva (100 ppm
  simulados se quedan por debajo de 1 ms); ring buffer con hilos; silencio
  cuando el buffer se vacía.
- **Motor real en Windows:** un WAV con un "pip" en cada pulso renderizado
  junto al click; ambos en la misma muestra (±1). Sigue el patrón de
  `tool/sections_smoke_test.dart`.
- **Dart:** guardar y cargar `tracks`; restaurar una copia avisa de los
  archivos que faltan.
- **Dispositivo:** setlist de 2 canciones con pistas, cambio automático,
  pantalla apagada y Outro.

## 6. Fases

1. Pistas por canción con volumen y mute; sincronía con Link y corrección de
   deriva; precarga del siguiente tema; desplazamiento del "1"; silencio si el
   tempo no coincide; edición en el editor de canción.
2. Salida dividida L/R, "solo in-ear" por pista y panel de mezcla en vivo.
3. Más adelante: estiramiento de tiempo, interfaces USB de 4+ salidas,
   detección automática del "1", copias de seguridad con audio (zip), iOS.

**Decisiones por defecto que se tomaron:** WAV, MP3 y FLAC (no M4A/AAC, que
necesitaría el decodificador del sistema); sin estiramiento de tiempo; el gap
trainer solo calla el click; las pistas no se envían a los seguidores.
