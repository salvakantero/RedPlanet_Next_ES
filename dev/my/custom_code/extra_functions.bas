' ESCRIBE AQUÍ TUS FUNCIONES O SUBS PERSONALIZADAS. Puedes llamarlas desde otros archivos de código personalizado.

'tipos de objeto recogible
#define OBJ_TNT     0
#define OBJ_OXYGEN  1
#define OBJ_AMMO    2
#define OBJ_KEY     3
#define MAX_AMMO    50

'Hotspots de comida (puntos extra, estilo Red Planet Pi)
'se identifican por su numero de sprite (_en_sprnum), no por posicion.
'slots libres del spriteset enemies_0.spr (fila 1, sin usar por enemigos/objetos)
'RESERVADO! Los sprites 16/17/18 NO deben asignarse a ningun enemigo/objeto en el
'editor de mapas: enems_collisions.bas trata cualquier sprite 16/17/18 como comida 
'(suma puntos y omite el efecto de obj_table)
#define SPR_BURGER  16
#define SPR_CAKE    17
#define SPR_DONUT   18

#define PTS_BURGER  100
#define PTS_CAKE    80
#define PTS_DONUT   60

'Variables del jugador
dim player_ammo as ubyte
dim player_keys as ubyte
dim hiscore as ulong 'ulong (32-bit) en paralelo con score, evita overflow
LoadSD("bin/hiscore.bin", @hiscore, 4, 0)
' Migracion: el fichero antiguo era de 2 bytes y puede dejar basura en los 2 bytes altos.
' Si el valor supera el maximo mostrable (6 digitos), reiniciar a 0.
if hiscore > 999999 then hiscore = 0

'Tabla de 30 bytes: tipo de objeto por zona (5 zonas x 6 plantas)
'Indice = level_floor * 5 + zona    (zona = tile_x / 15)
dim obj_table(29) as ubyte => { _
    OBJ_AMMO,   OBJ_TNT, OBJ_OXYGEN, OBJ_TNT,  OBJ_KEY,    _
    OBJ_KEY,    OBJ_TNT, OBJ_OXYGEN, OBJ_AMMO, OBJ_TNT,    _
    OBJ_KEY,    OBJ_TNT, OBJ_OXYGEN, OBJ_AMMO, OBJ_OXYGEN, _
    OBJ_KEY,    OBJ_AMMO, OBJ_KEY,   OBJ_OXYGEN, OBJ_TNT,  _
    OBJ_OXYGEN, OBJ_KEY,  OBJ_TNT,   OBJ_AMMO,   OBJ_TNT,  _
    OBJ_OXYGEN, OBJ_TNT,  OBJ_AMMO,  OBJ_TNT,    OBJ_OXYGEN _
}

'Screen names & visited tracking
dim current_screen, prev_screen as ubyte
#define SCREEN_WIDTH_PX 240
#define TOTAL_SCREENS 30
dim visited(TOTAL_SCREENS - 1) as ubyte
dim visited_count as ubyte
dim new_hiscore as ubyte
dim expl_round as ubyte
dim expl_i as ubyte
dim expl_seed as uinteger

dim scr_names(TOTAL_SCREENS - 1) as string
scr_names(0)  = "CENTRO DE CONTROL"
scr_names(1)  = "DEPOSITO DE SUMINISTROS"
scr_names(2)  = "PASILLO CENTRAL"
scr_names(3)  = "ALMACEN DE RESIDUOS"
scr_names(4)  = "ALMACEN DE RESIDUOS"
scr_names(5)  = "CORREDOR OESTE"
scr_names(6)  = "ACCESO A CORREDOR OESTE"
scr_names(7)  = "PASILLO CENTRAL"
scr_names(8)  = "ACCESO A MAZMORRAS"
scr_names(9)  = "MAZMORRAS"
scr_names(10) = "CORREDOR OESTE"
scr_names(11) = "DEPOSITO DE SUMINISTROS"
scr_names(12) = "PASILLO CENTRAL"
scr_names(13) = "ACCESO A SALIDA"
scr_names(14) = "SALIDA A SUBTERRANEOS"
scr_names(15) = "MADRIGUERA PELUSOIDE"
scr_names(16) = "GRUTA DE ALVARITO"
scr_names(17) = "GRUTA DE ALVARITO"
scr_names(18) = "ALMACEN DE RESIDUOS"
scr_names(19) = "TUNEL SUBTERRANEO"
scr_names(20) = "CORREDOR LATERAL"
scr_names(21) = "MADRIGUERA ARACNOVIRUS"
scr_names(22) = "PASILLOS INESTABLES"
scr_names(23) = "PASILLOS INESTABLES"
scr_names(24) = "ALMACEN DE RESIDUOS"
scr_names(25) = "CORREDOR LATERAL"
scr_names(26) = "MINA ABANDONADA"
scr_names(27) = "MINA ABANDONADA"
scr_names(28) = "MINA ABANDONADA"
scr_names(29) = "DEPOSITO DE EXPLOSIVOS"


sub print_screen_name()
    dim scr_name as string
    dim name_x as ubyte
    dim scr_idx as ubyte

    current_screen = cast(ubyte, cast(uinteger, gpx + x_scroll) / SCREEN_WIDTH_PX)
    'mapa único: 30 pantallas = 5 horizontales x 6 plantas
    scr_idx = level_floor * 5 + current_screen

    if scr_idx = prev_screen then
        return
    end if

    prev_screen = scr_idx

    'marcar pantalla como visitada
    if visited(scr_idx) = 0
        visited(scr_idx) = 1
        visited_count = visited_count + 1
    end if

    scr_name = scr_names(scr_idx)

    'título de la pantalla centrado en la parte superior de la pantalla ULA (capa 2)
    '+ línea rodeando el título
    PRINT AT 3,3;PAPER 0;INK TEXT_INK;BRIGHT 0;"__________________________"
    if scr_name <> ""
        scr_name = " " + scr_name + " "
        name_x = (32 - len(scr_name)) >> 1
        PRINT AT 3,name_x;PAPER 0;INK TEXT_INK;BRIGHT 0;scr_name
    end if
end sub

'HUD personalizado: munición y llaves
#define AMMO_X  13
#define AMMO_Y  1
#define KEYS_X  21
#define KEYS_Y  1


sub print_ammo()
    'rojo si munición <= 5, verde en caso contrario
    dim ammo_ink as ubyte
    if player_ammo <= 5 then ammo_ink = 2 else ammo_ink = 4
    if player_ammo < 10
        PRINT AT AMMO_Y,AMMO_X;INK ammo_ink;BRIGHT 1;"0"+str(player_ammo);INK 4;"/50"
    else
        PRINT AT AMMO_Y,AMMO_X;INK ammo_ink;BRIGHT 1;str(player_ammo);INK 4;"/50"
    end if
end sub


sub print_keys()
    'rojo si no hay llaves, verde en caso contrario
    if player_keys = 0
        PRINT AT KEYS_Y,KEYS_X;INK 2;BRIGHT 1;"0"+str(player_keys)
    else
        PRINT AT KEYS_Y,KEYS_X;INK 4;BRIGHT 1;"0"+str(player_keys)
    end if
end sub


sub print_hiscore()
    '6 digitos (hiscore es ulong). Campo en columnas 8..13 (tras "RECORD:")
    dim s as string = str(hiscore)
    dim hx as ubyte = 8 + 6 - LEN(s) '8 = columna base; 6 = ancho del campo; alinea a la derecha
    print INK 4;BRIGHT 1;at SCORE_Y,8;"000000"
    print INK 4;BRIGHT 1;at SCORE_Y,hx; s
end sub


sub update_hiscore()
    new_hiscore = 0
    if score > hiscore then
        hiscore = score
        SaveSD("bin/hiscore.bin", @hiscore, 4) '4 bytes (ulong)
        new_hiscore = 1
    end if
end sub


sub print_stats(title as string, msg as string)
    dim pct as ubyte
    dim val_x as ubyte
    dim val_str as string

    'Final = 100%; si no: exploración 40% + TNT 40% (máx. 80%)
    if title = "MISION COMPLETADA!" then
        pct = 100
    else
        pct = cast(ubyte, (cast(uinteger, visited_count) * 40) / TOTAL_SCREENS) + cast(ubyte, (cast(uinteger, num_objects) * 40) / 10)
    end if

    borra_cadena()

    'Línea 1: Título centrado
    val_x = cast(ubyte, (32 - len(title)) >> 1)
    PRINT AT DIALOG_TOP_ROW+1,val_x;PAPER 0;INK 7;BRIGHT 1;title

    'Línea 2: pantallas exploradas
    PRINT AT DIALOG_TOP_ROW+2,7;PAPER 0;INK 5;BRIGHT 1;"EXPLORADO"
    if title = "MISION COMPLETADA!" then
        val_str = "30/30"
    else
        val_str = str(visited_count) + "/30"
    end if
    val_x = cast(ubyte, 24 - len(val_str))
    PRINT AT DIALOG_TOP_ROW+2,val_x;PAPER 0;INK 4;BRIGHT 1;val_str

    'Línea 3: porcentaje de exploración
    PRINT AT DIALOG_TOP_ROW+3,7;PAPER 0;INK 5;BRIGHT 1;"COMPLETADO"
    val_str = str(pct) + "%"
    val_x = cast(ubyte, 24 - len(val_str))
    PRINT AT DIALOG_TOP_ROW+3,val_x;PAPER 0;INK 4;BRIGHT 1;val_str

    'Línea 4: NEW RECORD o mensaje alternativo
    if new_hiscore = 1
        PRINT AT DIALOG_TOP_ROW+4,7;PAPER 0;INK 6;BRIGHT 1;"**NUEVO RECORD!**"
    else
        val_x = cast(ubyte, (32 - len(msg)) >> 1)
        PRINT AT DIALOG_TOP_ROW+4,val_x;PAPER 0;INK 7;BRIGHT 1;msg
    end if

    WaitForNoKey()
    WaitKey()
    DELETE_TEXT_AREA
end sub


'Tiles de puerta
#define DOOR_TILE    26
#define DOOR_REPLACE 2

dim door_tx as ubyte
dim door_ty as ubyte
dim door_locked_snd as ubyte


sub check_door()
    'si no tiene llaves, comprobar si toca puerta para sonar a "bloqueado"
    if player_keys = 0
        if player_facing = FACING_RIGHT
            door_tx = cast(ubyte, (gpx + 16 + x_scroll) >> 4)
        else
            door_tx = cast(ubyte, (gpx - 1 + x_scroll) >> 4)
        end if
        door_ty = cast(ubyte, (gpy + 8) >> 4)
        qtile(cast(uinteger, door_tx), cast(uinteger, door_ty))
        if aux2 = DOOR_TILE
            if door_locked_snd = 0
                PlaySFX(10)
                door_locked_snd = 1
            end if
        else
            door_locked_snd = 0
        end if
        return
    end if
    'calcular tile X delante del jugador según su dirección
    if player_facing = FACING_RIGHT
        door_tx = cast(ubyte, (gpx + 16 + x_scroll) >> 4)
    else
        door_tx = cast(ubyte, (gpx - 1 + x_scroll) >> 4)
    end if
    'comprobar a la altura superior del jugador
    door_ty = cast(ubyte, (gpy + 3) >> 4)
    qtile(cast(uinteger, door_tx), cast(uinteger, door_ty))
    'si no es puerta arriba, comprobar a la altura inferior
    if aux2 <> DOOR_TILE
        door_ty = cast(ubyte, (gpy + 15) >> 4)
        qtile(cast(uinteger, door_tx), cast(uinteger, door_ty))
    end if
    'si encontramos puerta, abrirla
    if aux2 = DOOR_TILE
        player_keys = player_keys - 1
        print_keys()
        actualizar_tile(door_tx, door_ty + first_row, DOOR_REPLACE)
        PlaySFX(7) 'remolino'
        add_points(50)
    end if
end sub

'emplazamiento del TNT
#define TNT_TILE 27
dim tnt_placed as ubyte
dim tnt_drawn as ubyte
dim tnt_i as ubyte
dim tnt_msg_shown as ubyte

'Music/Mute
dim music_muted as ubyte
dim fire2_edge as ubyte
