'deteccion de colisiones con el player
if player_status < DYING_ST
    cx2 = _en_x - x_scroll
    cy2 = _en_y
    no_kill = 0 'por defecto la colision mata al player (será anulada para objetos)

    'colisiones enemigos-balas y player-enemigos
#ifdef ENABLE_PLATFORMS    
    if _en_t <> PLATFORM_TYPE 'no afecta a plataformas
#endif
        if enem_status < ENEM_DAMAGED 'afecta solo a estados diferentes a dañado o muriendo

        'DISPAROS
#ifdef ENABLE_OBJECTS
        if _en_t <> OBJECT_TYPE
#endif

#ifdef PLAYER_CAN_FIRE
            'bucle colisiones balas del player con enemigos
            for i = 0 to MAX_BULLETS-1
                if estado_bala(i) = 1 
                    cx1 = x_bala(i)
                    cy1 = y_bala(i)
                    if cx1 > (cx2-12) AND cx1 < (cx2+14) AND cy1 >= cy2-8 - ENEMY_EXTRA_TOP_BB AND cy1 <= (cy2+4)
                        enem_recibe_golpe(1)
                        estado_bala(i) = 0
                    end if
                end if
            next i
#endif           

#ifdef STOMP_ENEMIES
            'colision player pisando enemigos
            if p_vy > 0
                cx1 = gpx + 8
                cy1 = gpy + 15
        
                if cx1 >= cx2 AND cx1 <= (cx2+15) AND cy1 >= cy2 - ENEMY_EXTRA_TOP_BB AND cy1 <= (cy2+8)
                    PlaySFX(SOUND_ENEMY_STOMPED)
                    enem_recibe_golpe(1)
                    brinco = 1
                end if
            end if
#endif

#ifdef ENABLE_OBJECTS    
        end if
#endif
            if enit bAND 1 = half_life 'procesa solo la mitad de los enemigos en cada ciclo
#include "../my/custom_code/enemies_cc/enems_killable.bas"
                if enem_status < ENEM_DYING
                    if collide() = 1
#ifdef ENABLE_OBJECTS
                        'código para objetos coleccionables
                        IF ENEMY_TYPE = OBJECT_TYPE
                            NO_KILL                     'la colisión no mata al player
                            KILL_SPRITE_NO_RESPAWN      'elimina el objeto y desactiva su reaparición
                        END IF
#endif
                        #include "../my/custom_code/enemies_cc/enems_collisions.bas"
                        if no_kill = 0 AND player_status < FLICKERING_ST
                            player_damaged = 1
                            PlaySFX(SOUND_PLAYER_DAMAGED)
                        end if
                    end if
                end if
            end if
        end if

#ifdef ENABLE_PLATFORMS    

    else
    'PLATAFORMAS MóVILES'
        if gpx > cx2 - 15
        if gpx < cx2 + 15                
        if gpy >= cy2 - 17 - ABS(_en_my) 'ampliamos ventana de detección para compensar movimiento vertical de la plataforma
        if gpy < cy2 - 10
            on_ground = 1
            plataforma_vx = 0: plataforma_vy = 0
            'aplicamos la velocidad de la plataforma al player
            if half_life = 0
                plataforma_vx = _en_mx << 6
            end if
            'y "pegamos" el player a la parte superior de la plataforma
            gpy = cy2 - 16
            p_y = gpy << 6
        end if
        end if
        end if
        end if
#endif
    end if
end if
