'/INSERTA AQUÍ TUS RUTINAS ADICIONALES DENTRO DEL BUCLE DEL JUEGO'

' // TRUCO // Pulsar E para forzar el final (COMENTAR cuando no se necesite)
'if MultiKeys(KEYE) then END_GAME

'Alternar silencio (BOTÓN 2 / M por defecto)
if press_fire2 AND fire2_edge = 0
    fire2_edge = 1
    if music_muted = 0
        DisableMusic
        music_muted = 1
    else
        EnableMusic
        music_muted = 0
    end if
end if
if NOT press_fire2 then fire2_edge = 0

print_screen_name()

'Comprobar si el jugador toca una puerta
check_door()

'DETONADOR: activar ending si el TNT está colocado (planta 0, pantalla 0)
if tnt_placed = 1
    IF PLAYER_IN_ZONE(1,7,1,7) 'Zona de detonador en planta 0, pantalla 0
        END_GAME
    END IF
end if

'COLOCAR TNT en EXPLOSIVES STOCKPILE (planta 5)
if tnt_placed = 0 AND num_objects = 10
    IF PLAYER_IN_ZONE(66,56,70,56)
        tnt_placed = 1
        PlaySFX(5)
        add_points(200) 'recompensa por juntar y colocar los 10 TNT
    END IF
end if

'Pintar TNTs una sola vez (al colocar o al volver a la planta 5)
if tnt_placed = 1 AND tnt_drawn = 0 AND level_floor = 5
    for tnt_i = 0 to 4
        actualizar_tile(66 + tnt_i, 55, TNT_TILE)
        actualizar_tile(66 + tnt_i, 56, TNT_TILE)
    next tnt_i
    tnt_drawn = 1
end if

'Feedback al pisar la zona de colocación (planta 5)
if level_floor = 5 AND tnt_msg_shown = 0
    IF PLAYER_IN_ZONE(66,56,70,56)
        if num_objects = 10 then DIALOG 3 else DIALOG 4
        tnt_msg_shown = 1
        prev_screen = 255 'Forzar repintado del nombre de pantalla tras el DIALOG
        PRINT_HUD
    END IF
end if

'Resetear flags al salir de planta 5
if level_floor <> 5
    tnt_drawn = 0
    tnt_msg_shown = 0
end if




