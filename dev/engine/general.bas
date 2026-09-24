'SUBS Y FUNCIONES GENERALES

Sub Test_SetSprites(byVal Total as ubyte, spraddress as uinteger, byval firstSprite as ubyte)
  ' sube sprites desde una posición de memoria a la memoria de sprites 
  ' Total = numero de sprites, spraddress = dirección de memoria 
  ' funciona con sprites de 8 y de 4 bits 
  ASM 
    ld d,(IX+5)
    ;selecciona el slot 0
    ;xor a        
        ld a,(ix+9)
    ld bc, $303b
    out (c), a

    ld b,d                ; cuantos sprites enviar 

    ld l, (IX+6)
    ld h, (IX+7)
sploop:
    push bc
    ld bc,$005b          
    otir
    pop bc 
    djnz sploop
  end asm 
end sub

' QTILE: la variable aux1 devuelve el tipo de tile (beh) que hay en las coordenadas x_punto,y_punto en tiles
'        la variable aux2 devuelve el número de tile en el tileset (posición de 0 a 127)
sub qtile(byval x_punto as uinteger, byval y_punto as uinteger)
  tilenum = x_punto + (ancho_mapa *cast(uinteger,y_punto+first_row)) 'sin el cast pasa a valores ubyte
  ' calcula la posición del tile de la pantalla x_punto + y_punto*H 
  ' (H = número de tiles por fila en área de juego) 
  asm : di: nextreg $56,90 : nextreg $57,91 : end asm 
  p = peek(tilenum + MAP_BUFFER) ' lee el número de tile que hay en esa posición
  asm : nextreg $56,0 : nextreg $57,1 : ei :end asm 
  aux1 = behs(p) 'consultamos el tipo del tile en el array behs y lo almacenamos
  aux2 = p
end sub


'CHECK_N_POINTS: devuelve el comportamiento (beh) del tile que hay en dos puntos (ct1 y ct2) 
'definidos por sus coordenadas x,y en píxeles: cx1,cy1 para ct1 y cx2,cy2 para ct2
sub check_n_points (num_points as ubyte)
    ' Punto ct1
    qtile(cx1 >> 4, cy1 >> 4)
    ct1 = aux1

    if num_points > 1
      ' Punto ct2
      qtile(cx2 >> 4, cy2 >> 4)
      ct2 = aux1
    end if

    if num_points > 2
      ' Punto ct3
      qtile(cx3 >> 4, cy3 >> 4)
      ct3 = aux1
    end if
end sub


sub pausa(tiempo as uinteger) 'gracias a Duefectu
    while tiempo > 0
      asm 
        push bc
        ld b,117
  pausa_Bucle1:        
          push bc
          ld b,255
  pausa_Bucle2:
            nop
            djnz pausa_Bucle2
          pop bc
          djnz pausa_Bucle1
        pop bc
      end asm
      tiempo = tiempo - 1
    wend
end sub


'MUSICA Y SONIDO

'iniciar players de sonido y musica
sub init_sound()
  ' MUSICA
  LoadSDBank("music/0.pt3",0,0,0,51) ' carga music.pt3 en el banco 51
  LoadSDBank("music/vt24000.bin",0,0,0,50) 'carga el reproductor de música en el banco 50
  LoadSDBank("music/fx.afb",0,0,0,52) 'carga el fichero SFX afb en el banco 52
  ' SFX
  InitSFX(52) ' inicia el motor SFX
  'AY1 (SFX) en mono, AY0 (música) en estéreo
  ' NextReg $09 bits 7,6,5 = AY2/AY1/AY0 mono respectivamente.
  NextReg($09, $40)
  InitMusic(50,51,0000) 'inicia el motor de música: 50 contiene el reproductor, 51 el PT3, 0000 el offset en el banco 51
  SetUpIM() 'inicia el código IM2 
  EnableSFX 'activa los AYFX; usa DisableSFX para parar
  DisableMusic
end sub


'reproduce una canción desde el principio (track = numero de canción). Guarda las canciones como 1.pt3, 2.pt3, etc.'
sub play_music ()
	LoadSDBank("music/"+ str(track) +".pt3",0,0,0,51)
	InitMusic(50,51,0000)
end sub


' leer la frecuencia vertical de refresco
sub get_frecuency()
    contador_frecuencia60 = 6
    v=GetReg($05) bAND %100
    if v=0 then
      VarFrec=50  ' 50Hz
    else
      VarFrec=60  ' 60Hz
    end if
end sub


sub NoOptimizar()
    print VarFrec
    print contador_frecuencia60
end sub


'forzar kempston joystick MD1 3/6 botones
sub set_joystick()
v = GetReg($05)
v = v bAND %101
v = v bOR %01001000 
NextRegA($05,v)
end sub

'configurar los registros del Next
sub set_registers()
  NextReg($7,$3) 'fija 28MHz
  NextReg($15,%01110011) 'configura sprites, L2 y ULA
  NextReg(GLOBAL_TRANSPARENCY_NR_14, GLOBAL_TRANSPARENT_COLOR) 'color transparente global (incluye tiles de 8 bits)
  NextReg(SPRITE_TRANSPARENCY_I_NR_4B, SPRITES_TRANSPARENT_COLOR) 'color transparente para sprites
  NextReg(LAYER2_RAM_BANK_NR_12,9)
end sub


'cargar la paleta personalizada'
sub load_palettes()
  LoadSD("pal/sprites.pal",PALETTE_BUFFER,512,0)
  NextReg($43,%00100000)
  PalUpload(PALETTE_BUFFER,0,0)
  LoadSD("pal/tiles.pal",PALETTE_BUFFER,512,0)
  NextReg($43,%00010000)
  PalUpload(PALETTE_BUFFER,0,0)
end sub


'nivel superado
sub stage_clear ()
#include "../my/custom_code/game_cc/stage_clear.bas"
  CROP_ULA 'vuelve al estado normal de la ULA (muestra solo el hud)
end sub
 

'elimina todos los sprites
sub clear_sprites()
  for i = 0 to 96
    RemoveSprite(i,0)
  next i
end sub


'detecta colisión entre el jugador y enemigos
function collide () as ubyte
	#ifdef SMALL_COLLISION_ENEM
    if (gpx + 10 >= cx2 AND gpx <= cx2 + 10 AND gpy + 10 >= cy2 - ENEMY_EXTRA_TOP_BB AND gpy - PLAYER_EXTRA_TOP_BB <= cy2 + 10)
	#else
		if (gpx + 13 >= cx2 AND gpx <= cx2 + 13 AND gpy + 13 >= cy2 - ENEMY_EXTRA_TOP_BB AND gpy - PLAYER_EXTRA_TOP_BB  <= cy2 + 13)
	#endif
      return 1
    else 
      return 0
  end if
end function


' detecta la colisión de un punto con el player (por ejemplo, disparos enemigos)
function point_collide () as ubyte
	#ifdef SMALL_COLLISION_SHOTS
		if (cx2 > gpx  AND cx2 < gpx+12 AND cy2 > gpy + 4- PLAYER_EXTRA_TOP_BB AND cy2 < gpy+12)
	#else
		if (cx2 > gpx  AND cx2 < gpx+15 AND cy2 > gpy- PLAYER_EXTRA_TOP_BB AND cy2 < gpy+15)
	#endif
      return 1
    else 
      return 0
  end if
end function


'TILES ANIMADOS
#ifdef TILANIMS
  sub AnimateTiles()
    tiles_subframe = tiles_subframe + 1
    if tiles_subframe = TILANIM_FREQUENCY 'cambio de tile cada n frames 
      tiles_subframe = 0
      tiles_frame = tiles_frame + 1
      if tiles_frame = MAX_FRAMES_TILANIM 
          tiles_frame = 0
      end if

      for tile_id = 0 to MAX_TILANIMS
        _t = tiles_animados_t (tile_id) 
        if _t = 255 then EXIT FOR
        _x = tiles_animados_x (tile_id)
        _y = tiles_animados_y (tile_id)
        _t = _t + tiles_frame 
        update_tile(0)
      next tile_id
    end if
  end sub
#endif


sub game_over ()
    'se reemplaza imagen gameover.bin por DIALOG
    update_hiscore()
    clear_sprites()
    PRINT_HUD
    track = MUSIC_GAMEOVER : play_music()
    EnableMusic 'SILENCIO solo silencia durante la partida, no en game over
    'pantalla de estadísticas en lugar de DIALOG
    print_stats("*** GAME OVER ***", "INTENTALO DE NUEVO!")
end sub


sub fin()
#include "../my/custom_code/game_cc/game_ending.bas"
end sub


sub ResetScroll320()
  asm
  nextreg $16,0 ;este registro mueve el layer2 de 0 a 255 pixeles 
  nextreg $71,0 ;este registro usa el bit 0 para moverlo hasta 319 en modo 320x256
  end asm
end sub


#ifdef TIMER_ENABLE
sub time_over ()
#include "../my/custom_code/game_cc/time_up.bas"
end sub


sub run_timer()
    if timer_zero 
        time_over ()
        timer_zero = 0
        #ifdef TIMER_AUTO_RESET 			
            timer_t = TIMER_INITIAL
        #endif 
    end if
    ' Timer
    if timer_on AND timer_t
        timer_count = timer_count + 1
        if timer_count = timer_frames
            timer_count = 0
            timer_t = timer_t-1
            print_time()
            if timer_t = 0 : timer_zero = 1 : end if
        end if
    end if
end sub

#endif


sub new_page()
  WaitForNoKey()
  WaitKey()
  borra_cadena() 
  xc = 1 : yc = DIALOG_TOP_ROW + 1
end sub


sub print_cadena(salto_linea as ubyte)
    borra_cadena()
    'SHOW_DIALOG
    xc = 1 : yc = DIALOG_TOP_ROW + 1 : contador_cadena = 0
    do
      caracter = CHR(peek(TXT_BUFFER + contador_cadena))
      if caracter = "*" OR contador_cadena = 512
        EXIT DO
      end if
      if caracter = "%" 
        xc = 1
        yc = yc + salto_linea
        if yc > DIALOG_BOTTOM_ROW - 1 then new_page()
      else
        if xc = 31 then xc = 1 : yc = yc + salto_linea
        if yc > DIALOG_BOTTOM_ROW - 1 then new_page()
        PRINT AT yc,xc;PAPER TEXT_PAPER;INK TEXT_INK;BRIGHT TEXT_BRIGHT;caracter$
        xc = xc + 1
      end if
      pause 1
      contador_cadena = contador_cadena + 1
    loop
    WaitKey()
    ' CROP_ULA
    DELETE_TEXT_AREA
end sub


sub borra_cadena()
    'asegurar fila del nombre de pantalla antes del marco
    prev_screen = 255
    print_screen_name()
    INK FRAME_INK: PAPER FRAME_PAPER: bright FRAME_BRIGHT
    print at DIALOG_TOP_ROW,0;"<^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^>"
    print at DIALOG_BOTTOM_ROW,0;"[______________________________]"
     _y = DIALOG_TOP_ROW + 1
    while _y < DIALOG_BOTTOM_ROW
        PRINT AT _y,0;chr(92)
        PRINT AT _y,31;chr(64)
        for _x = 1 to 30
          PRINT AT _y,_x;" "
        next _x
        _y = _y + 1
    wend
    SHOW_DIALOG
end sub


sub WaitForNoKey()
do
  v = in(31)
  if GetKeyScanCode = 0 AND v = 0 then EXIT DO
loop
end sub


'REDEFINIR TECLAS'

'comprueba si una tecla ya se definió antes al redefinir teclas'
function already_defined(codigo as uinteger) as ubyte
    for i = 0 to tecla
      if codigo = keys_to_play(i)
        return 1
      end if
    next i
    return 0
end function


sub redefine_keys()
    Print at REDEFINE_TEXT_Y,0;"                                "
      let teclas_redef(0) = "IZQUIERDA"
      let teclas_redef(1) = "DERECHA"
      let teclas_redef(2) = "ARRIBA"
      let teclas_redef(3) = "ABAJO"
      let teclas_redef(4) = "DISPARO"
      let teclas_redef(5) = "MUSICA"
      let teclas_redef(6) = "PAUSA"
       cadena1 = "PULSA"

    'resetear teclas'
    for i = 0 to 6
      keys_to_play(i) = 0
    next i

    j = 0
    Print ink 4;at REDEFINE_TEXT_Y,REDEFINE_TEXT_X;cadena1$
    tecla = 0
    while tecla < 7
        'saltar ABAJO (tecla 3); no se usa en este juego'
        if tecla = 3 then tecla = tecla + 1
        Print ink 6;at REDEFINE_TEXT_Y,REDEFINE_TEXT_X+6;teclas_redef(tecla)+"   "
        WaitForNoKey()
        WaitKey()
        if GetKeyScanCode <> KEYR AND GetKeyScanCode <> KEYJ
          if tecla = 0 OR already_defined(GetKeyScanCode) = 0
            if tecla = 0 then key_left = GetKeyScanCode
            if tecla = 1 then key_right = GetKeyScanCode
            if tecla = 2 then key_up = GetKeyScanCode
            if tecla = 3 then key_down = GetKeyScanCode
            if tecla = 4 then key_fire = GetKeyScanCode
            if tecla = 5 then key_fire2 = GetKeyScanCode
            if tecla = 6 then key_pause = GetKeyScanCode
            keys_to_play(tecla) = GetKeyScanCode
            PlaySFX(SOUND_KEY_DEFINED)
            tecla = tecla + 1
          end if
        end if
    wend

    WaitForNoKey()
    CLS
    WaitRetrace(60)
    SaveSD("bin/keys.bin",@keys_to_play(0), 14)
end sub


sub control_vars() 
    if control = 1 'control por kempston 3 botones
        v=in(31) 'leer el puerto kempston 1
        press_up = v bAND %1000 
        press_down = v bAND %100
        press_left = v bAND %10
        press_right = v bAND %1
        press_fire = v bAND %10000
        press_fire2 = (v bAND %100000) OR MultiKeys(key_fire2)
        press_pause = (v bAND %10000000) OR MultiKeys(key_pause)
    else 'control por teclado
        press_up = MultiKeys(key_up) 
        press_down = MultiKeys(key_down)
        press_left = MultiKeys(key_left) 
        press_right = MultiKeys(key_right)
        press_fire = MultiKeys(key_fire)
        press_fire2 = MultiKeys(key_fire2)
        press_pause = MultiKeys(key_pause)
    end if
end sub


'RUTINAS DE SCROLL
sub process_right_scroll() 
      columna_actual = x_scroll_temp>>4
      if x_scroll_temp_6 >= 20480 'es lo mismo que 320<<6'
          x_scroll_temp_6 = x_scroll_temp_6 - 20480
          x_scroll_temp = cast(integer, (x_scroll_temp_6 >> 6))
          columna_actual = 0
      end if
      if columna_actual <> columna_anterior
          draw_column_right()
          columna_anterior = columna_actual 
      end if  
end sub


sub process_left_scroll() 
    columna_actual = x_scroll_temp>>4
    if x_scroll_temp_6 < 0
        x_scroll_temp_6 = 20480 + x_scroll_temp_6
        x_scroll_temp = cast(integer, (x_scroll_temp_6 >> 6))
        columna_actual = 0
    end if
    if columna_actual <> columna_anterior
        draw_column_left()
        columna_anterior = columna_actual 
    end if  
end sub


sub do_x_scroll()
  asm
  ld hl, (_x_scroll_temp)
  ld a,l
  nextreg $16,a ;este registro mueve el layer2 de 0 a 255 pixeles 
  ld a,h 
  nextreg $71,a ;este registro usa el bit 0 para moverlo hasta 319 en modo 320x256
  end asm
end sub


sub calculos_vx_scroll()
#ifdef ENABLE_AUTOSCROLL
  if NOT autoscroll_on
    x_scroll_6 = x_scroll_6 + cast(long, total_vx)
    x_scroll_temp_6 = x_scroll_temp_6 + cast(long, total_vx)
  else
    x_scroll_6 = x_scroll_6 + cast(long, autoscroll_vel)
    x_scroll_temp_6 = x_scroll_temp_6 + cast(long, autoscroll_vel)
  end if
  x_scroll = cast(integer, (x_scroll_6 >> 6))
  x_scroll_temp = cast(integer, (x_scroll_temp_6 >> 6))
#else
  x_scroll_6 = x_scroll_6 + cast(long, total_vx)
  x_scroll = cast(integer, (x_scroll_6 >> 6))
  x_scroll_temp_6 = x_scroll_temp_6 + cast(long, total_vx)
  x_scroll_temp = cast(integer, (x_scroll_temp_6 >> 6))
#endif
end sub


function ScrollToLeft() as ubyte
  if x_scroll > -32
          calculos_vx_scroll()
          process_left_scroll()
          'Scroll en X'
          haz_scroll = 1
          return 1
  else
#ifdef ENABLE_AUTOSCROLL
    autoscroll_vel = 0
#endif
    return 0
  end if
end function


function ScrollToRight() as ubyte
  if x_scroll < x_fin_mapa
          calculos_vx_scroll()
          process_right_scroll()
          'Scroll en X'
          haz_scroll = 1
          return 1
  else
#ifdef ENABLE_AUTOSCROLL
    autoscroll_vel = 0
#endif
    return 0
  end if
end function


sub coloca_scroll()
  colocando_scroll = 1
  posicion_x_inicial = (cast(uinteger, player_x_ini) << 4) - CAM_RIGHT_LIMIT
  if changing_floor
    total_vx = 64 'avanza 1 px (asegura la posicion del player al cambiar de floor)
  else
    total_vx = 512 'avanza 4 px (asegura el dibujado de las columnas)
  end if
  'eliminada llamada duplicada a calculos_vx_scroll() que doblaba el avance del scroll
  while x_scroll < posicion_x_inicial AND x_scroll < x_fin_mapa
    ScrollToRight()
  wend
  total_vx = 0
  colocando_scroll = 0
  do_x_scroll()
end sub


'funciones y subs disparos jugador
sub shoot()
    for i = 0 to MAX_BULLETS-1
        if estado_bala(i) = 0
            'ajustamos la posición inicial de la bala para que salga por el lado correcto 
            'dependiendo de hacia donde esté mirando el jugador
            if player_facing = FACING_LEFT then 
              x_bala(i) = gpx - 8
            else 
              x_bala(i) = gpx + 8
            end if
            y_bala(i) = gpy + 0
            estado_bala(i) = 1
            v_bala(i) = 4 - player_facing
            facing_bala(i) = player_facing
            PlaySFX(SOUND_PLAYER_SHOOT)
            EXIT FOR
        end if
    next i
end sub


sub BulletsPlayerMove()
    'seleccionar frame del disparo
    dim sprite_bala as ubyte = BULLET_SPRITE
    asm : nextreg $50,32 : nextreg $51,33 : end asm 'paginamos a los bancos 32 y 33'
    direccion = $0000+(256*sprite_bala)
    Test_SetSprites(1,direccion,PLAYER_BULLET_FIRST_SP_VRAM)
    asm : nextreg $50,$ff : nextreg $51,$ff : end asm 'paginamos a los bancos por defecto

    for i = 0 to 2
      if estado_bala(i) = 1 
        x_bala(i) =  x_bala(i) + v_bala(i)
        _x1 = x_bala(i) + 4 + x_scroll
        _y = y_bala(i)+4
        qtile(_x1 >> 4, _y >> 4) 'consultamos tipo de tile que está tocando la bala, nos lo devuelve aux1
        if x_bala(i) > 310 OR aux1 = 8 then estado_bala(i) = 0 'si sale de la pantalla o el tipo de tile es sólido la borramos
        UpdateSprite(x_bala(i), y_bala(i) + (SCREEN_Y_OFFSET<<4),PLAYER_BULLET_FIRST_SP_VRAM+i,PLAYER_BULLET_FIRST_SP_VRAM,facing_bala(i),0)
      else 
        RemoveSprite(PLAYER_BULLET_FIRST_SP_VRAM+i,0)
      end if
  next i
end sub


sub reset_bullets() 'resetea todas las balas, del player y de los enemigos
#ifdef PLAYER_CAN_FIRE
    for i = 0 to MAX_BULLETS-1
        estado_bala(i) = 0
    next i
#endif
#ifdef ENEMY_BULLETS
    for i = 0 to MAX_ENEMY_BULLETS-1
        estado_enemyBullet(i) = 0 
    next i
#endif
end sub


#ifdef ENEMY_BULLETS
'disparos enemigos
sub shoot_enemyBullet(vx as byte, vy as byte)
    for i = 0 to MAX_ENEMY_BULLETS-1
        if estado_enemyBullet(i) = 0 
            estado_enemyBullet(i) = 1
            x_enemyBullet(i) = _en_x + 4
            if _en_facing = 8 then x_enemyBullet(i) = _en_x - 4
            y_enemyBullet(i) = _en_y
            vx_enemyBullet(i) = vx
            vy_enemyBullet(i) = vy
            EXIT FOR
        end if
    next i
end sub


sub EnemyBulletsMove() 
    for i = 0 to MAX_ENEMY_BULLETS-1
        if estado_enemyBullet(i) = 1 
            spnum = sprite_enemyBullet(frame_enemyBullet)
            asm : nextreg $50,34 : nextreg $51,35 : end asm 
                direccion = $0000+(256*spnum)
                Test_SetSprites(1,direccion,ENEMBULLET_FIRST_SP_VRAM)
            asm : nextreg $50,$ff : nextreg $51,$ff : end asm  
            x_enemyBullet(i) =  x_enemyBullet(i) + vx_enemyBullet(i)
            y_enemyBullet(i) =  y_enemyBullet(i) + vy_enemyBullet(i)
            _x1 = x_enemyBullet(i) + 4
            _y = y_enemyBullet(i)+4
            qtile(_x1 >> 4, _y >> 4) 'consultamos tipo de tile que está tocando la bala, nos lo devuelve aux1
            'si sale de la pantalla o el tipo de tile es sólido la borramos
            if (x_enemyBullet(i) - x_scroll) > 310 OR (x_enemyBullet(i) - x_scroll) < 10 then 
                estado_enemyBullet(i) = 0 
            elseif y_enemyBullet(i) > 160 OR  y_enemyBullet(i) < 0 then 
                estado_enemyBullet(i) = 0
            end if
            
            if aux1 = 8 
               estado_enemyBullet(i) = 0
            end if

            UpdateSprite(x_enemyBullet(i)- x_scroll, y_enemyBullet(i) + (SCREEN_Y_OFFSET<<4),ENEMBULLET_FIRST_SP_VRAM+i,ENEMBULLET_FIRST_SP_VRAM,0,0)

            'colisión con el player
            if i bAND 1 = half_life 'procesa solo la mitad de las balas en cada ciclo
              if player_status < FLICKERING_ST
                  cx2 = x_enemyBullet(i) + 8 - x_scroll
                  cy2 = y_enemyBullet(i) + 8
                  if point_collide() = 1
                      estado_enemyBullet(i) = 0
                      player_damaged = 1
                      PlaySFX(SOUND_PLAYER_DAMAGED)
                  end if
              end if
            end if
        else 
            RemoveSprite(ENEMBULLET_FIRST_SP_VRAM+i,0)
        end if
    next i
    if half_life then frame_enemyBullet = frame_enemyBullet + 1
    if frame_enemyBullet > 1 then frame_enemyBullet = 0
end sub
#endif


'cargar textos'
sub load_text(num_txt as uinteger)
  fichero = "txt/"+ str(num_txt) +".txt"
  LoadSD(fichero,TXT_BUFFER,512,0)
  print_cadena(1)
end sub
