'bucle principal del juego; termina cuando la variable playing vale 0
    
'iniciar variables del juego
game_init ()

#include "../my/custom_code/game_cc/before_game_loop.bas"

do 'bucle del juego 
#ifdef DEBUGGING 'permite cambiar de nivel pulsando Z/X
    if MultiKeys(KEYX) then level_number = level_number +1
    if MultiKeys(KEYZ) then level_number = level_number -1
#endif
    if press_pause
        SHOW_DIALOG 'garantiza que la franja central esté visible
        PAPER 0: INK 6
        print at DIALOG_TOP_ROW+1,13;"       "
        print at DIALOG_TOP_ROW+2,13;" PAUSA "
        print at DIALOG_TOP_ROW+3,13;"       "
        WaitForNoKey()
        do
            control_vars()
            if press_pause then EXIT DO
        loop
        WaitForNoKey()
        DELETE_TEXT_AREA
    end if

    if level_completed 
        stage_clear()
        level_number = level_number + 1
        level_completed = 0
        'SALIR DEL BUCLE SI GANAMOS EL JUEGO'
        if level_number = MAX_LEVELS 'si se pasa el ultimo nivel de alguna forma, se termina el juego
            success = 1: playing = 0
            EXIT DO
        end if
    end if

    if current_level <> level_number
        ClipLayer2(0,0,0,0)
        ShowLayer2(0)
        ' DisableSFX
        #include "../engine/level_screen.bas"
        #include "../my/custom_code/game_cc/before_entering_map.bas" 
        SHOW_SPRITES 'activamos el área de juego para los sprites

        current_level = level_number
         
        if level_music(level_number) <> track AND NOT changing_floor
            track = level_music(level_number)
        end if
        
        if track <> old_track
            old_track = track
            play_music ()
            if NOT music_muted
                EnableMusic
            end if
        end if
        
#ifdef TILANIMS
        reset_tilanims ()
#endif
        draw_scr() 'dibuja la pantalla
        coloca_scroll()
        player_locate()

        ClipLayer2(16,143,SCREEN_Y_OFFSET*16,SCREEN_Y_OFFSET*16+SCREENS_H*16-1) 'x1=16 para alinear con pixel 32 del buffer 320x256
        ShowLayer2(1)
        
        if dialog_shown = 0 then DIALOG 5: dialog_shown = 1   
    end if

#ifdef TIMER_ENABLE
    if player_status < DYING_ST then run_timer() 'hace las cosas del temporizador siempre que no esté muriendo
#endif

    '1/2 TIEMPO Y 1/4 de TIEMPO
    half_life = NOT half_life
    if half_life
        half_life2 = NOT half_life2
    end if

    'animacion de tiles
#ifdef TILANIMS
    AnimateTiles()
#endif

    WaitRetrace(1) 'espera al siguiente frame o interrupcion
    
    if haz_scroll then do_x_scroll()
    haz_scroll = 0
    'saltar un frame de cada 6 en modo 60HZ para mantener la velocidad original del juego
    if contador_frecuencia60 = 6 AND VarFrec = 60 : WaitRetrace(1): end if

    'funciones enemigos
    EnemiesMove()

    'funciones proyectiles
#ifdef PLAYER_CAN_FIRE
    BulletsPlayerMove()
#endif
#ifdef ENEMY_BULLETS
    EnemyBulletsMove()
#endif

    'funciones player
    PlayerMove() 
    PlayerAnimation()
    UpdatePlayer()
    check_death() 'comprueba si ha terminado la animación de morir

    #include "../my/custom_code/game_cc/ingame_routines.bas"
    
    update_score_roll() 'anima el marcador rodante cada frame

    fin_playing_loop:
    loop until playing = 0

    PAPER 3: BRIGHT 1
    CLS

    if success = 1 
        fin()
    else
        game_over ()
    end if