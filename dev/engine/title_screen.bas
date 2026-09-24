'pantalla de inicio, menu, etc
DisableMusic
MODE256
HIDE_SPRITES
ScrollLayer(0,0)
PAPER 3: BRIGHT 1: CLS
LoadSDBank("gfx/title.bin",0,0,0,18)
ClipLayer2(0,255,0,191)
ClipULA(0,255,0,191)
ShowLayer2(1)
contador = 0
track = MUSIC_TITLE : play_music()
EnableMusic
border 0
contador = 149
dim titulo_idx as ubyte = 0
menu:
control = 1

do
	WaitRetrace(1)
	v = in(31)
	'entropía para el PRNG de comida: avanza cada fotograma mientras se espera la pulsacion de START
	food_seed = food_seed * 181 + 59

	'1: control por teclas'
	if MultiKeys(KEY1)
		control = 0
		EXIT DO
	end if

	'2: control por joystick'
	if MultiKeys(KEY2)
		control = 1
		EXIT DO
	end if

	'3: redefinir teclas'
	if MultiKeys(KEY3)
		redefine_keys()
		'al volver, reinicia el carrusel para mostrar de inmediato las opciones de menú
		titulo_idx = 0
		contador = 149
	end if

	'carrusel de textos
	contador = contador + 1
	if contador = 150
		contador = 0
		if titulo_idx = 0 then PRINT AT 23,0; INK 4; BRIGHT 1; PAPER 0; "1-TECLAS 2-JOYSTICK 3-REDEFINE ";
		if titulo_idx = 1 then PRINT AT 23,0; INK 4; BRIGHT 1; PAPER 0; "    PROGRAMA:  SALVAKANTERO    ";
		if titulo_idx = 2 then PRINT AT 23,0; INK 4; BRIGHT 1; PAPER 0; "    GRAFICOS:  SALVAKANTERO    ";
		if titulo_idx = 3 then PRINT AT 23,0; INK 4; BRIGHT 1; PAPER 0; "        MUSICA:  TACHA         ";
		if titulo_idx = 4 then PRINT AT 23,0; INK 4; BRIGHT 1; PAPER 0; " REALIZADO CON  NEXT MS ENGINE ";
		titulo_idx = titulo_idx + 1
		if titulo_idx = 5 then titulo_idx = 0
	end if
loop

'Antirrebote solo UNA vez, al salir: dentro del bucle se comía pulsaciones (gira
'durante toda la pulsacion, asi que MultiKeys nunca la ve y la opcion se ignora
'hasta pulsar otra vez o mantener la tecla). redefine_keys() ya termina con su
'propio WaitForNoKey().
WaitForNoKey()

'la transición de arranque (jingle SOUND_START_GAME, ocultar Layer2, limpiar y SHOW_DIALOG) 
'se hace ahora al final de before_game.bas, después de la 2a pantalla de título
'(title2). Aqui dejamos title1 (Layer2) visible y la música sonando para encadenar con title2
' sin parpadeo a la ULA, y para que el sonido de inicio suene al entrar de verdad al juego
