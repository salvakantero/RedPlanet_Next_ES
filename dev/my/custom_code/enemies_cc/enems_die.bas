'****************'
'ENEMIES DIE CODE'
'****************'
'ESTE CODIGO SE EJECUTA CUANDO UN ENEMIGO MUERE'

'ASIGNAR ANIMACION AL MORIR Y PUNTOS POR SUBTIPO'
IF ENEMY_TYPE = 1 THEN                   'PATROLLERS'
    ENEMY_ANIMATION(2,3, 10-_en_sprnum, 11-_en_sprnum)
    'Puntuación. Subtipo por sprite base
    IF _en_sprnum = 0 THEN
        SCORE_ADD(20) 'INFECTADO
    ELSEIF _en_sprnum = 2 THEN
        SCORE_ADD(40) 'PELUSOIDE
    ELSE
        SCORE_ADD(30) 'ARACNOVIRUS
    END IF

ELSEIF ENEMY_TYPE = 2 THEN               'FANTYS'
    ENEMY_ANIMATION(2,3, 10-_en_sprnum, 11-_en_sprnum)
    SCORE_ADD(50)

ELSEIF ENEMY_TYPE = 3 THEN               'JUMPERS'
    ENEMY_ANIMATION(2,3, 10-_en_sprnum, 11-_en_sprnum)
    SCORE_ADD(30)

'ELSEIF ENEMY_TYPE = 4 THEN               'OSCILLATORS'
'    ENEMY_ANIMATION(1,99,2)
'    SCORE_ADD(20)

END IF


