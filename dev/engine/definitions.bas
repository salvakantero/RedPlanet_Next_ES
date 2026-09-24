#define _check_interrupts _checkints

'variables generales
dim track, old_track as ubyte
dim fichero as string
dim direccion, size as uinteger
dim half_life, half_life2, success as ubyte
dim i, j, k as ubyte
dim dif_x, dif_y as integer

' variables y defines del player
dim num_objects as ubyte
dim playing, player_energy, lives, player_damaged as ubyte
dim p_vx, p_vy, total_vx, total_vy as integer 
dim player_x_ini, player_y_ini as ubyte 
dim p_x, p_y as integer 
dim gpx, gpy as uinteger
dim p_frame, p_subframe, player_facing, spnum, p_frame_base as ubyte 
dim player_status, p_ct_estado, player_jumping, jump_pressed, brinco as ubyte 
dim on_ground as ubyte 
dim plataforma_vx, plataforma_vy as integer
dim ptx1, pty1, ptx2, pty2 as uinteger 'caja de colision player
dim _x1, _y1 as uinteger 
dim _x as integer
dim _y, _n, _t as ubyte

dim spike_touched as ubyte
dim ct1, ct2, ct3, aux1, aux2, aux3, aux4 as ubyte 'puntos auxiliares
dim cx1, cy1, cx2, cy2, cx3, cy3 as integer 'puntos auxiliares
dim contador as ubyte

dim player_counter, fps_animacion as ubyte
dim diferencia, distancia as integer
dim auxi1 as integer
dim auxi2, auxi3, auxi4, uit as ubyte
dim ajuste_ccol_y as ubyte
dim score, next_extra_life as ulong 'ulong (32-bit): evita el wrap a 65535 y soporta el HUD de 6 digitos
dim score_shown as ulong 'marcador rodante: aumenta score +1 cada frame
dim roll_click as ubyte 'marcador rodante: alterna 0/1 para espaciar el FX (1 de cada 2 frames)
dim food_seed as uinteger 'semilla para el tipo de comida aleatorio (burger, cake, donut)
dim ladder_on, ladder_up, ladder_down, ladder_middle as ubyte
dim val_a, val_b as ubyte

#define FACING_RIGHT    0
#define FACING_LEFT     8
#define FACING_UP       2
#define FACING_DOWN     3

#define NORMAL_ST 		0
#define JUMPING_ST1		1
#define FLICKERING_ST   9
#define DYING_ST        10

'array de frames del player
dim player_frames(MAX_FRAMES_PLAYER-1) as ubyte
                                 
'variables disparos player
dim disparando, disparado as ubyte 
dim x_bala (3)  as uinteger
dim y_bala (3)  as ubyte
dim v_bala (3)  as byte
dim facing_bala (3)  as byte
dim estado_bala (3)  as ubyte

'variables enemigos: estado por-enemigo en arrays indexados por enit (almacena TODOS los enemigos a la vez)
dim total_enemies as ubyte 'guarda el total de enemigos del nivel actual
dim enit, enviit as ubyte 'iteradores para enem y enem visibles

'lista de enemigos de la planta actual (optimiza rendimiento)
dim floor_enems_idx (MAX_ENEMS) as ubyte
dim floor_enems_count as ubyte
dim cached_floor as ubyte
dim fidx as ubyte

dim enoffset as uinteger
dim active, no_kill as ubyte
dim en_an_frame (MAX_ENEMS) as ubyte
dim en_an_subframe (MAX_ENEMS) as ubyte
dim enem_counter (MAX_ENEMS) as ubyte
dim en_an_state (MAX_ENEMS) as ubyte
dim en_an_facing (MAX_ENEMS) as ubyte
dim en_an_fps (MAX_ENEMS) as ubyte
dim en_an_num_frames (MAX_ENEMS) as ubyte
dim enemies_t (MAX_ENEMS) as ubyte
dim enemies_npant (MAX_ENEMS) as ubyte
dim enemies_spritenum (MAX_ENEMS) as ubyte
dim enemies_life (MAX_ENEMS) as byte
dim enemies_maxlife (MAX_ENEMS) as byte
dim enemies_x (MAX_ENEMS) as integer
dim enemies_y (MAX_ENEMS) as integer
dim enemies_x1 (MAX_ENEMS) as integer
dim enemies_y1 (MAX_ENEMS) as integer
dim enemies_x2 (MAX_ENEMS) as integer
dim enemies_y2 (MAX_ENEMS) as integer
dim enemies_mx (MAX_ENEMS) as byte
dim enemies_mx_ini (MAX_ENEMS) as byte
dim enemies_my (MAX_ENEMS) as byte
dim enemies_my_ini (MAX_ENEMS) as byte
dim enem_vy (MAX_ENEMS) as integer 'velocidad saltarines y osciladores
dim enem_ajuste_ccol_y as ubyte

'variables auxiliares para código personalizado
dim enem_var1 (MAX_ENEMS) as ubyte
dim enem_var2 (MAX_ENEMS) as ubyte
dim enem_var3 (MAX_ENEMS) as ubyte
dim enem_var4 (MAX_ENEMS) as ubyte
dim enem_var5 (MAX_ENEMS) as ubyte
dim enem_counter2 (MAX_ENEMS) as ubyte
dim obj_collected (MAX_ENEMS) as ubyte '0=no recogido, 1=recogido(listo para comida), 2=ya convertido a comida

dim dialog_shown as ubyte = 0

#ifdef FANTYS
dim enemies_x_fanty (MAX_ENEMS) as integer
dim enemies_y_fanty (MAX_ENEMS) as integer
dim enemies_mx_fanty (MAX_ENEMS) as integer
dim enemies_my_fanty (MAX_ENEMS) as integer
#endif

'variables simples enemigos: copia escalar del enemigo "actual" (enemies_*(enit)) durante el bucle; acceso más rápido en Z80. Ver enengine.bas
dim _en_x, _en_x1, _en_x2 as integer
dim _en_y, _en_y1, _en_y2 as integer
dim _en_mx, _en_my as byte
dim _en_t, _en_facing, _en_sprnum as ubyte
dim _en_life as byte
dim _en_vy as integer
dim enem_status as ubyte

#ifdef ENEMY_BULLETS
'disparos enemigos (enemyBullets)
dim x_enemyBullet (3)  as integer
dim y_enemyBullet (3)  as integer
dim vx_enemyBullet (3)  as integer
dim vy_enemyBullet (3)  as integer
dim estado_enemyBullet (3)  as ubyte
'secuencias de animación de enemyBullets
dim sprite_enemyBullet(1) as ubyte => {ENEM_BULLET_ANIM} '2 frames
dim frame_enemyBullet as ubyte
#endif

'arrays animaciones enemigos
dim enem_animation (MAX_ENEMS, MAX_FRAMES_ENEMIES) as ubyte

'estados enemigos
#define ENEM_NORMAL     0  
#define ENEM_DAMAGED    10
#define ENEM_DYING      11
#define ENEM_DEAD       12
#define ENEM_NO_RESPAWN 99

'************************************************'
'variables mapas
dim level_completed as ubyte
dim mapbuffer as uinteger
dim p, tilenum  as uinteger 
dim x, y  as ubyte
dim tt as uinteger
dim current_level, level_number, teleport  as ubyte
dim ancho_mapa, alto_mapa as uinteger
dim level_floor, first_row, changing_floor as ubyte 

'************************************************'
'variables tiles animados
#ifdef TILANIMS
dim tiles_animados_x (0 to MAX_TILANIMS) as ubyte
dim tiles_animados_y (0 to MAX_TILANIMS) as ubyte
dim tiles_animados_t (0 to MAX_TILANIMS) as ubyte
dim tiles_frame, tiles_subframe, tilanim_num, total_tilanims, tile_id as ubyte
dim tilanims_first as ubyte
#endif     

'************************************************'
'variables scroll
dim x_scroll, x_scroll_temp, posicion_x_inicial as integer
dim x_scroll_6, x_scroll_temp_6 as long
dim columna_actual, columna_anterior, addx, haz_scroll as ubyte
dim columna_inicial, colocando_scroll as byte
dim x_fin_mapa as uinteger
dim resto_scrollx as integer

'************************************************'
'variables timer
#ifdef TIMER_ENABLE
dim timer_on as ubyte
dim timer_t as uinteger
dim timer_frames as ubyte
dim timer_count as ubyte
dim timer_zero as ubyte
#endif                          

#define PLATFORM_TYPE   49  ' tipo para las plataformas móviles
#define OBJECT_TYPE     50  ' tipo para los objetos coleccionables

'rebote vertical para animación de los objetos (Sube hasta 4px. y baja) 
dim bob_offset(15) as ubyte => {0,0,1,1,2,3,3,4,4,4,3,3,2,1,1,0}

'NUMERO DEL PRIMER SPRITE EN MEMORIA DE SPRITES
#define PLAYER_FIRST_SP_VRAM            0
#define PLAYER_BULLET_FIRST_SP_VRAM     4
#define ENEMIES_FIRST_SP_VRAM           20
#define ENEMBULLET_FIRST_SP_VRAM        10

'DEFINICION DE BUFFERS EN ZONA DE PANTALLA ULA
'PALETTE BUFFER
#define PALETTE_BUFFER 20480 'SOLO SE USARÍA PARA CARGAR UNA PALETA PERSONALIZADA, luego se borra
#define TXT_BUFFER 20480 
'ENEMIES BUFFER
#define ENEMIES_BUFFER  21248 'Dejamos 512 (21248-20480) bytes para cargar antes los txt para dialogos en TXT_BUFFER
#define ENEMIES_DATA  ENEMIES_BUFFER+1
'MAP BUFFER
#define DIMENSIONES_MAPA $C000 'En los bancos 90,91. Paginamos para acceder.
#define MAP_BUFFER DIMENSIONES_MAPA+2 '2 BYTES Después de DIMENSIONES_MAPA, esos dos bytes guardan el ancho y alto del mapa en tiles

'carga el charset (fuente)
fichero = "bin/font.bin"
#ifdef FULL_CHARSET
LoadSD(fichero,@font_buffer,768,0) 'mayúsculas, minúsculas, números y símbolos
#else
LoadSD(fichero,@font_buffer,512,0) 'solo mayúsculas, números y algunos símbolos
#endif
direccion = @font_buffer
poke uInteger 23606, direccion - 256

dim cadena1, cadena2, cadena3 as string   
'dim idioma as ubyte
'calculos para FPS'
dim v, VarFrec, contador_frecuencia60 as ubyte

#define SCREEN_Y_OFFSET (HUD_HEIGHT+2)
#define SCREENS_H (12-HUD_HEIGHT)
#ifndef LIMITE_ARRIBA
#define LIMITE_ARRIBA -1024 
#endif
#ifndef LIMITE_ABAJO
#define LIMITE_ABAJO (SCREENS_H-1)*16*64
#endif
dim behs(128) as ubyte AT $5b00

'Dialogs
dim caracter as string
dim contador_cadena as uinteger
dim xc, yc as ubyte

#ifndef TEXT_INK
    #define TEXT_INK 7
#endif
#ifndef TEXT_BRIGHT
    #define TEXT_BRIGHT 1
#endif
#ifndef FRAME_INK
    #define FRAME_INK 7
#endif
#ifndef FRAME_BRIGHT
    #define FRAME_BRIGHT 1
#endif

'autoscroll
dim autoscroll_vel as integer
dim autoscroll_on as ubyte

dim player_max_energy as ubyte

#ifndef ENEMY_DYING_TIME
    #define ENEMY_DYING_TIME 32
#endif

#ifndef RATE_OF_FIRE
    #define RATE_OF_FIRE 4
#endif
