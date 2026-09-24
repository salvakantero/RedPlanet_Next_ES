'Escribe aquí tu código personalizado para antes de comenzar la partida (al salir del menú).

'Mostrar la 2ª pantalla de título (title2: info/ayuda) hasta pulsar una tecla.
'title_screen deja title1 (Layer2) visible y la música sonando; aquí cargamos title2 sobre
'el MISMO banco 18 sin ocultar la capa, así se reemplaza la imagen sin parpadeo a la ULA.
'Antes de cambiar, limpiamos la ULA al color TRANSPARENTE (paper 3 = magenta) para borrar
'los créditos del carrusel, que se imprimen en paper 0 (negro OPACO) y quedarían "congelados"
'sobre title2. OJO: el fondo negro de title2 es la propia imagen de Layer2; la ULA debe estar
'en el color transparente para que Layer2 se vea. Limpiar a negro la haría opaca y taparía todo.
PAPER 3: CLS
LoadSDBank("gfx/title2.bin",0,0,0,18)
ClipLayer2(0,255,0,191)
ClipULA(0,255,0,191)
ShowLayer2(1)
'texto parpadeante en la linea 23 (mismo estilo que el carrusel de title), centrado.
'alterna ~0,5s mostrandolo (paper 0) y ~0,5s borrandolo con espacios transparentes
'(paper 3) para que se vea la imagen de Layer2 debajo.
dim blink_c as ubyte = 0
dim blink_on as ubyte = 1
PRINT AT 23,0; INK 4; BRIGHT 1; PAPER 0; "        PULSA UNA TECLA        ";
do
    WaitRetrace(1)
    v = in(31)
    blink_c = blink_c + 1
    if blink_c = 25
        blink_c = 0
        blink_on = 1 - blink_on
        if blink_on = 1
            PRINT AT 23,0; INK 4; BRIGHT 1; PAPER 0; "        PULSA UNA TECLA        ";
        else
            PAPER 3: PRINT AT 23,0; "                               ";
        end if
    end if
loop until GetKeyScanCode <> 0 OR v <> 0
WaitForNoKey()

'Transición de arranque de la partida (movida desde title_screen.bas): suena el jingle de
'inicio al entrar de verdad al juego, se oculta Layer2 y se recorta la ULA para el marcador.
DisableMusic
PlaySFX(SOUND_START_GAME)
pausa(50)
CLS
ShowLayer2(0)
CLS256(0)
SHOW_DIALOG 'Recorta la ULA a la zona del marcador/diálogos para el juego

'Inicializar inventario
player_ammo = 5
player_keys = 0 'Llaves para abrir puertas

'Inicializar tracking de pantallas visitadas
for i = 0 to TOTAL_SCREENS - 1
    visited(i) = 0
next i
visited_count = 0 'Contador de pantallas visitadas
new_hiscore = 0
tnt_placed = 0 'TNT ya colocado (para pulsar detonador)
tnt_drawn = 0 'TNT ya dibujado (para no repintar cada frame)
tnt_msg_shown = 0 'Mensaje de TNT mostrado (para no mostrarlo cada frame)
music_muted = 0
fire2_edge = 0 'Control de pulsación del botón 2 para mutear música
dialog_shown = 0 'Control de mostrar ayuda al inicio del juego'
