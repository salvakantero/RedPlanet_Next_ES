'******************'
'ENEMIES START CODE'
'******************'
'ESTE CODIGO SE EJECUTA AL CREARSE EL ENEMIGO POR PRIMERA VEZ Y AL HACER RESPAWN'

'ASIGNAR ANIMACION INICIAL'
IF ENEMY_TYPE = 1 THEN                   'PATROLLERS'
    ENEMY_ANIMATION(2,8,    0,1) 'valor 1: numero de fotogramas, valor 2: intervalo entre fotogramas, el resto: secuencia de imágenes
ELSEIF ENEMY_TYPE = 2 THEN               'FANTYS'
    ENEMY_ANIMATION(2,6,    0,1)
ELSEIF ENEMY_TYPE = 3 THEN               'JUMPERS'
    ENEMY_ANIMATION(2,4,    0,1)
ELSEIF ENEMY_TYPE = 4 THEN               'OSCILLATORS'
    ENEMY_ANIMATION(2,4,    0,1)
ELSEIF ENEMY_TYPE = PLATFORM_TYPE THEN   'PLATFORMS'
    ENEMY_ANIMATION(2,8,    0,1)
#ifdef ENABLE_OBJECTS
ELSEIF ENEMY_TYPE = OBJECT_TYPE THEN     'OBJETOS RECOGIBLES (rebote vertical)'
    enemies_y1(enit) = enemies_y(enit)   'ancla del rebote = posicion de reposo del objeto'
    enem_counter2(enit) = enit AND 15    'fase inicial distinta por objeto (desincroniza el rebote)'
#endif
END IF