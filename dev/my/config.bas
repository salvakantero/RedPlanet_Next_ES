/'
CONFIGURACION DEL MOTOR, MK1 CHURRERA STYLE
- Se pueden cambiar los valores de los #define para variar parámetros como la velocidad del jugador,
pantalla de inicio, vidas, que enemigos activar, posicionar elementos del hud, etc.
- Comenta los defines que no se vayan a usar si por ejemplo tu juego no salta, comenta #define PLAYER_JUMPS
'/

' ============================================================================
' Configuración general
' ============================================================================
#define FIX_MUSIC_60HZ 'Hace que la música suene a la misma velocidad en 50/60 Hz (requiere modificar Nextlib.bas)

'#define DEBUGGING     'Si se define, permite ir al mapa anterior/siguiente pulsando Z/X'

'#define CUSTOM_PALETTE 'Activar para usar paletas personalizadas. Nombra los ficheros como sprites.pal / tiles.pal en data/pal/'
#define SPRITES_TRANSPARENT_COLOR 227
#define GLOBAL_TRANSPARENT_COLOR 231

' Menu
#define REDEFINE_TEXT_X 9   'Coordenada donde imprimir el diálogo de redefinición de teclas'
#define REDEFINE_TEXT_Y 23

' CAMERA SETTINGS: define los límites a partir de los cuales la cámara sigue al jugador haciendo un scroll
' Valores en píxeles: de 8 a 296 para horizontal y de 8 a 168 para vertical)'
#define CAM_LEFT_LIMIT      152
#define CAM_RIGHT_LIMIT     152
'#define CAM_DOWN_LIMIT      100
'#define CAM_UP_LIMIT        80

' ============================================================================
' CONFIGURACIÓN DE NIVELES (aquí consideramos cada mapa como un nivel)
' ============================================================================
#define FIRST_LEVEL			    0		        ' Nivel inicial
#define MAX_LEVELS				1		        ' Número total de niveles (si ganas el último, termina el juego)
#define LEVELS_TILESETS         0   	        ' Tilesets (spr) usados en cada nivel, separados por comas //Ej. el valor 0 usará: "tiles_1.spr + beh1.bin"
#define LEVELS_ENEMIES          0   	        ' Spriteset de enemigos usado en cada nivel, separado por comas //Ej. el valor 0 usará: "enemies_1.spr"
#define LEVELS_MUSICS           1               ' Número de música usada en cada nivel, separada por comas //Ej. el valor 2 usará el archivo "2.pt3"
#define MAX_ENEMS               125             ' Máximo de enemigos+objetos+plataformas por nivel (un nivel es un mapa)' // PERSONALIZADO // ampliado de 111 para hotspots de comida
#define ENABLE_AUTOSCROLL      

' ============================================================================
' TILES ANIMADOS'
' ============================================================================
#define TILANIMS                                ' Si se define, se activan las animaciones de tiles'
#define MAX_TILANIMS               27           ' Número máximo de tiles animados por mapa (no usar demasiados)'
#define MAX_FRAMES_TILANIM          2           ' Número de tiles que usa la animación'
#define TILANIM_FREQUENCY          12           ' Número de frames (tiempo) hasta mostrar el siguiente tile de la animación'
#define LEVELS_FIRST_TILANIM      118	        ' Primer tile animado (para cambiarlo en un nivel concreto, usar FIRST_TILANIM = N en "before_entering_map.bas")

' ============================================================================
' CONFIGURACIÓN DEL TEMPORIZADOR
' ============================================================================
#define TIMER_ENABLE					' Activar temporizador
#define TIMER_INITIAL 			99		' Valor inicial.
#define TIMER_LAPSE			    100		' Número de frames entre decrementos
#define TIMER_START						' Si se define, iniciar el temporizador desde el principio
'#define TIMER_AUTO_RESET				' Si se define, el temporizador se reinicia al agotarse

' ============================================================================
' MISCELÁNEA
' ============================================================================
#define EXTRA_LIFE_SCORE    1500    'Ganar una vida extra cada N puntos'
'#define SPIKES_KILL_VERTICAL_ONLY   ' Si se define, el tile de tipo 1 solo daña al tocarlo por arriba o abajo; horizontalmente es un bloque sólido
'#define FULL_CHARSET                ' Si se define, la fuente también usará minúsculas. Si no se necesita, desactivarlo ahorrará algunos bytes.

' ============================================================================
' CONFIGURACIÓN DEL JUGADOR
' ============================================================================
'#define PLAYER_SPRITE_16X32                 ' El sprite del player usará el tamaño de 16x32 píxeles en lugar de 16x16
#define MAX_FRAMES_PLAYER   4               ' Numero de sprites del player por animación'
#define PLAYER_FLICKERS                     ' Si se define, el jugador parpadea tras recibir daño durante los frames indicados en FLICKERING_TIME
#define FLICKERING_TIME     100             ' número de frames de parpadeo

' Player data
#define INIT_ENERGY 				1		' Energía inicial (usar 1 para que un impacto mate al jugador)
#define INIT_LIVES				    10		' Vidas máximas e iniciales (usar 1 para una sola vida y usar la energía en su lugar)

' Fire
#define PLAYER_CAN_FIRE			     		' Si se define, el jugador puede disparar
#define BULLET_SPRITE				63		' Número de sprite para las balas en el spriteset
#define MAX_BULLETS				    1		' Número de sprites para las balas en el spriteset
#define STOP_WHEN_FIRE			 	        ' Si se define, el jugador se detiene al disparar durante el tiempo indicado en RATE_OF_FIRE
#define RATE_OF_FIRE			    4	    ' número mínimo de frames entre dos disparos

' Vertical movement.
#define PLAYER_GRAVITY				16		' Si se define, aplicar aceleración de gravedad (el valor aumenta la caída cada frame hasta alcanzar PLAYER_MAX_VY_FALLING)
#define PLAYER_MAX_VY_FALLING		256 	' Velocidad máxima de caída

#define PLAYER_JUMPS                        ' Si se define, el jugador puede saltar
#define JUMP_POWER		            280 	' Velocidad Y inicial del salto
#define DAMAGE_BOUNCE_POWER    		200 	' Si se define, el jugador rebota al recibir daño. El valor es la velocidad Y

'#define ENABLE_UPDOWN_MOVE                 ' Si se define, el jugador puede moverse arriba y abajo (para juegos cenitales, recordar desactivar gravedad y salto)

'#define ENABLE_LADDERS                      ' Si se define, los tiles de tipo 2 son escaleras.
'#define LADDER_VY                   64      ' Velocidad Y al subir/bajar por escaleras.
'#define JUMP_POWER_ON_LADDER        128     ' Velocidad Y inicial del salto en escaleras.
'#define FALL_OFF_LADDER                     ' Si se define y el jugador recibe daño en una escalera, caerá de ella.


' Horizontal (side view) or general (top view) movement.
#define PLAYER_MAX_VX				128  	' Velocidad X máxima (96/64 = 1,5 píxeles/frame)
'#define INERTIA                             ' Comentar esta línea para desactivar la inercia'
#define PLAYER_AX					8		' Acceleration (24/64 = 0,375 pixels/frame^2)
#define PLAYER_RX					8		' Friction (32/64 = 0,5 pixels/frame^2)

' Bounding box size
' Colisión con tiles; usar 0 para una caja normal de 16x16
#define BOUNDING_BOX_LEFT_OFFSET	   -1	' En píxeles: negativo reduce la caja, positivo la aumenta
#define BOUNDING_BOX_RIGHT_OFFSET	   -1	' En píxeles: negativo reduce la caja, positivo la aumenta
#define BOUNDING_BOX_UP_OFFSET	       -1	' En píxeles: negativo reduce la caja, positivo la aumenta
#define BOUNDING_BOX_DOWN_OFFSET	   0	' En píxeles: negativo reduce la caja, positivo la aumenta (con gravedad, dejarlo en 0)

' Colisión con enemigos y disparos'
#define SMALL_COLLISION_ENEM 				' caja reducida para colisiones con enemigos
'#define SMALL_COLLISION_SHOTS				' caja reducida para colisiones con balas enemigas
'#define STOMP_ENEMIES                       ' Eliminar enemigos saltando sobre ellos'

' ============================================================================
' CONFIGURACIÓN DE ENEMIGOS, PLATAFORMAS Y OBJETOS
' ============================================================================
'#define ENEMY_SPRITES_16X32         ' Los Sprites enemigos usarán el tamaño de 16x32 píxeles en lugar de 16x16
#define MAX_SPRITES_ON_SCREEN  10   ' Numero máximo de sprites en pantalla (a la vez), contando enemigos, objetos y plataformas móviles'

#define MAX_FRAMES_ENEMIES  2   ' Numero máximo de sprites de animacion de los enemigos'
#define DEFAULT_ENEM_FPS    4   ' Numero de frames que pasan para cambiar el sprite de animacion de los enemigos'

#define RESPAWN_ENEMIES         ' Si se define, los enemigos reaparecen en el lugar donde murieron al quedar fuera del área visible.'
'#define ENEMY_DEATH_BOUNCE  24  ' Si se define, los enemigos rebotan al morir; el número es la velocidad vertical (VY) del rebote (por defecto 24)'
#define ENEMY_DYING_TIME    16  'Número de frames que dura el estado de muerte.'
'#define WALLS_STOP_ENEMIES      ' Si se define, los enemigos cambian de dirección al chocar con un tile sólido.

#define ENABLE_PLATFORMS        ' Si se define, el enemigo de tipo 49 será una plataforma móvil
#define ENABLE_OBJECTS          ' Si se define, el enemigo de tipo 50 será un objeto coleccionable
#define OBJECTS_GET_SOUND   6   ' Sonido reproducido al recoger un objeto coleccionable
' rebote vertical de los objetos (los hace mas visibles, como en la version Pi)
' botan en Y siguiendo la tabla bob_offset() (16 pasos, amplitud 4 px). Solo afecta a la Y mostrada
' OBJ_BOB_FRAMES = frames por paso: mayor = rebote mas lento
#define OBJ_BOB_FRAMES      2   ' frames por paso del rebote (mayor = mas lento)
#define OBJ_BOB_CYCLE       (16 * OBJ_BOB_FRAMES) ' derivado: 16 pasos de bob_offset() (mejor no tocar)

' Fantys
#define FANTYS                  ' Activar el tipo de enemigo perseguidor (tipo 2)'
#define FANTYS_MAX_VEL 32 
#define FANTYS_ACELERACION 1

' Jumpers
#define JUMPERS                 ' Activar el tipo de enemigo saltador (tipo 3)'
#define ENEM_JUMP_POWER     42  ' Velocidad vertical inicial del salto para el tipo 3

' Oscillators
'#define OSCILLATORS              ' Enemigo oscilante (tipo 4)'
 
#define ENEMY_GRAVITY       2    ' Para saltadores, osciladores o enemigos que pueden caer
#define ENEMY_MAX_VY        96   ' Para saltadores, osciladores o enemigos que pueden caer

' Enemy fire'
'#define ENEMY_BULLETS           ' Si se define, los enemigos pueden disparar
'#define MAX_ENEMY_BULLETS   3   ' número máximo de balas enemigas en pantalla
'#define ENEM_BULLET_ANIM 62,63  ' Animación de las balas enemigas, separada por comas (2 frames)

' ============================================================================
' CONFIGURACIÓN DEL HUD
' ============================================================================
#define HUD_HEIGHT 2 'Número de FILAS DE TILES (16 px cada una): recomendado 1 o 2 según las necesidades; 0 si no se usa HUD.
' IMPORTANTE: actualmente no hay scroll vertical; ajusta la altura de los mapas al HUD usado: altura del área de juego en tiles = 18 - altura del HUD
#define SHOW_SCORE                      ' Si se define, mostrar la puntuación en el HUD
#define SCORE_X                 25       ' Coordenada X de la puntuación en el HUD
#define SCORE_Y                 2       ' Coordenada Y de la puntuación en el HUD
' // PERSONALIZADO // Marcador "rodante" estilo recreativa: el marcador mostrado sube +SCORE_ROLL_STEP
' por frame hasta alcanzar la puntuacion real (no salta de golpe). Con 1, sube de uno en uno.
' La duracion es proporcional a los puntos (a 50fps: 1 punto/frame). Si se queda corto, sube a 2.
#define SCORE_ROLL_STEP         1       ' Incremento del marcador por frame
' PERSONALIZADO: click continuo del marcador rodante: mientras el marcador sube suena el FX cada frame
' (cada disparo pisa al anterior), creando un tableteo que se corta en seco al pararse el marcador.
#define SOUND_SCORE_CLICK   10      ' Fx de click del marcador rodante
'#define SHOW_ENERGYBAR                  ' Si se define, mostrar la barra de energía en el HUD
'#define ENERGYBAR_X             0       ' Coordenada X de la barra de energía en el HUD
'#define ENERGYBAR_Y             1       ' Coordenada Y de la barra de energía en el HUD
#define SHOW_LIVES                      ' Si se define, mostrar el número de vidas en el HUD
#define LIVES_X                 3       ' Coordenada X de las vidas en el HUD
#define LIVES_Y                 1       ' Coordenada Y de las vidas en el HUD
#define SHOW_TIMER                      ' Si se define, mostrar el O2 (oxígeno) en el HUD
#define TIMER_X                 8       ' Coordenada X del O2 en el HUD
#define TIMER_Y                 1       ' Coordenada Y del O2 en el HUD
#define SHOW_OBJECTS                    ' Si se define, mostrar el número de TNT en el HUD
#define OBJECTS_X               26      ' Coordenada X del TNT en el HUD
#define OBJECTS_Y               1       ' Coordenada Y del TNT en el HUD


' ============================================================================
' CONFIGURACIÓN DE MÚSICA Y SONIDO
' ============================================================================

'Canciones predeterminadas'
#define MUSIC_TITLE 0       'Pantalla de título/menú'
#define MUSIC_GAMEOVER 2
#define MUSIC_ENDING 0
'#define MUSIC_STAGE_CLEAR 11

'Sonidos FX predeterminados'
#define SOUND_ENEMY_DIE 4
#define SOUND_PLAYER_SHOOT 15
#define SOUND_JUMP 2 'espadazo'
#define SOUND_EXTRA_LIFE 8 'vida extra'
#define SOUND_PLAYER_DAMAGED 0 'caida'

#define SOUND_LANGUAGE_SELECTED 11
#define SOUND_KEY_DEFINED 13
#define SOUND_START_GAME 6
#define SOUND_ENEMY_DAMAGED 7
#define SOUND_ENEMY_STOMPED 12


' ============================================================================
' CONFIGURACIÓN DE CONTROLES
' ============================================================================

#define KEY_TO_LEFT     PRESS_LEFT
#define KEY_TO_RIGHT    PRESS_RIGHT
#define KEY_TO_UP       PRESS_UP
#define KEY_TO_DOWN     PRESS_DOWN

#define KEY_TO_FIRE     PRESS_FIRE
#define KEY_TO_JUMP     PRESS_UP
#define KEY_TO_PAUSE    PRESS_PAUSE

' ============================================================================
' CONFIGURACIÓN DE TEXTOS Y DIÁLOGOS
' ============================================================================
#define TEXT_INK 7
#define TEXT_BRIGHT 1
#define TEXT_PAPER 0
#define FRAME_INK 7
#define FRAME_BRIGHT 1
#define FRAME_PAPER 0

' posicion vertical de la ventana de dialogo (filas de caracteres ULA)
' la caja (6 filas) se centra en la PANTALLA completa (24 filas): 9 filas arriba y 9 abajo -> filas 9..14.
' para subir/bajar la caja, cambia SOLO DIALOG_TOP_ROW
' DIALOG_BOTTOM_ROW se deriva: borde superior + 4 lineas de texto + borde inferior = +5 filas.
#define DIALOG_TOP_ROW      9                   'fila del borde superior de la caja
#define DIALOG_BOTTOM_ROW   (DIALOG_TOP_ROW + 5) 'NO tocar
