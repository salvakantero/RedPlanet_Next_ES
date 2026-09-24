#ifdef SHOW_OBJECTS
sub print_objs()
#if OBJECTS_X < 32
    'rojo si < 10, verde si tiene los 10 TNT
    if num_objects < 10
        PRINT AT OBJECTS_Y,OBJECTS_X;INK 2;BRIGHT 1;"0"+str(num_objects);INK 4;"/10"
    else
        PRINT AT OBJECTS_Y,OBJECTS_X;INK 4;BRIGHT 1;str(num_objects);INK 4;"/10"
    end if
#endif
end sub
#endif


#ifdef TIMER_ENABLE
#ifdef SHOW_TIMER
sub print_time()
       'rojo si oxígeno <= 15, verde en caso contrario
       if timer_t <= 20
           PRINT AT TIMER_Y,TIMER_X;INK 2;BRIGHT 1;str(timer_t)+" "
       else
           PRINT AT TIMER_Y,TIMER_X;INK 4;BRIGHT 1;str(timer_t)+" "
       end if
end sub
#endif
#endif


#ifdef SHOW_LIVES
sub print_number_of_lives()
       'rojo si < 2 vidas, verde en caso contrario
       if lives < 2
           PRINT AT LIVES_Y,LIVES_X;INK 2;BRIGHT 1;str(lives)+" "
       else
           PRINT AT LIVES_Y,LIVES_X;INK 4;BRIGHT 1;str(lives)+" "
       end if
end sub
#endif


#ifdef SHOW_SCORE
sub print_score()
    dim s as string = str(score_shown)          'str() una sola vez
    dim x_score as ubyte = SCORE_X + 6 - LEN(s) '6 = ancho del campo; alinea a la derecha
    dim zi as ubyte
    'ceros a la izquierda (sin borrar antes: el número solo crece, no deja restos)
    if x_score > SCORE_X then
        for zi = SCORE_X to x_score - 1
            print INK 4;BRIGHT 1;at SCORE_Y,zi;"0"
        next zi
    end if
    print INK 4;BRIGHT 1;at SCORE_Y,x_score; s

	if score_shown > next_extra_life
        next_extra_life = next_extra_life + EXTRA_LIFE_SCORE
        PLAYER_LIVES = PLAYER_LIVES + 1
        #ifdef SHOW_LIVES
            print_number_of_lives() 'refrescar HUD al ganar vida extra
        #endif
        PlaySFX (SOUND_EXTRA_LIFE)
	end if
end sub
#endif


#ifdef SHOW_ENERGYBAR
sub print_energy() 
    if player_energy = 0 
        PRINT AT ENERGYBAR_Y,ENERGYBAR_X;"     "
    else
        for uit = 0 to player_energy-1
            PRINT AT ENERGYBAR_Y, uit + ENERGYBAR_X;ink 2;BRIGHT 1;"# "
        next uit
    end if	
end sub
#endif


sub print_hud()
#include "../my/custom_code/game_cc/hud.bas"
#ifdef SHOW_SCORE
    'print_score muestra score_shown, así el redibujo del HUD al
    'cambiar de planta NO salta de golpe al total; el rodaje continúa
    print_hiscore()
    print_score ()
#endif

#ifdef SHOW_ENERGYBAR
    print_energy()
#endif

#ifdef SHOW_LIVES
    print_number_of_lives()
#endif

#ifdef TIMER_ENABLE
#ifdef SHOW_TIMER
    print_time()
#endif
#endif

#ifdef SHOW_OBJECTS
    print_objs()
#endif
end sub


sub add_points (points as uinteger) 'uinteger para puntuaciones > 255
    score = score + points
#ifdef SHOW_SCORE
    print_score()
#endif
end sub


sub update_score_roll()
    'marcador rodante: +SCORE_ROLL_STEP por frame hasta alcanzar score (no bloquea el juego).
    if score_shown < score
        score_shown = score_shown + SCORE_ROLL_STEP
        if score_shown > score then score_shown = score
        print_score()
        'click 1 de cada 2 frames
        'cada disparo pisa al anterior y se corta en seco al parar el marcador
        roll_click = 1 - roll_click
        if roll_click = 0 then PlaySFX(SOUND_SCORE_CLICK)
    end if
end sub


sub delete_hud(start_y as ubyte)
    PAPER 3: BRIGHT 1
    for i=start_y to DIALOG_BOTTOM_ROW
        for j=0 to 31
            PRINT AT i,j;" "
        next j
    next i'
end sub

