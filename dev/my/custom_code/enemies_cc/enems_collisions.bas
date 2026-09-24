'CÓDIGO PERSONALIZADO DE COLISIONES - Objetos recogibles por tipo

#ifdef ENABLE_OBJECTS
IF ENEMY_TYPE = OBJECT_TYPE

    'HOTSPOTS DE COMIDA (puntos extra). Se identifican por su sprite, no por posición
    IF _en_sprnum = SPR_BURGER
        SOUND(OBJECTS_GET_SOUND)
        SCORE_ADD(PTS_BURGER)
    ELSEIF _en_sprnum = SPR_CAKE
        SOUND(OBJECTS_GET_SOUND)
        SCORE_ADD(PTS_CAKE)
    ELSEIF _en_sprnum = SPR_DONUT
        SOUND(OBJECTS_GET_SOUND)
        SCORE_ADD(PTS_DONUT)
    ELSE
    'Calcular zona (0-4) a partir de la posición X del objeto en tiles.
    'cada zona de 15 tiles (240 pixels) de ancho, y el desplazamiento del tile se obtiene con _en_x >> 4'
    dim obj_zone as ubyte = cast(ubyte, (_en_x >> 4) / 15)
    'Indice en la tabla: planta * 5 + zona
    dim obj_idx as ubyte = level_floor * 5 + obj_zone
    'Consultar tipo de objeto en la tabla de extra_functions.bas
    dim obj_type as ubyte = obj_table(obj_idx)
    IF obj_type = OBJ_TNT
        SOUND(OBJECTS_GET_SOUND)
        OBJECTS_NUMBER = OBJECTS_NUMBER + 1
        SCORE_ADD(20)
        #ifdef SHOW_OBJECTS
            print_objs()
        #endif
        obj_collected(enit) = 1
    ELSEIF obj_type = OBJ_OXYGEN
        SOUND(OBJECTS_GET_SOUND)
        timer_t = TIMER_INITIAL
        SCORE_ADD(40)
        #ifdef SHOW_TIMER
            print_time()
        #endif
        obj_collected(enit) = 1
    ELSEIF obj_type = OBJ_AMMO
        SOUND(OBJECTS_GET_SOUND)
        player_ammo = player_ammo + 20
        if player_ammo > MAX_AMMO then player_ammo = MAX_AMMO
        SCORE_ADD(30)
        print_ammo()
        obj_collected(enit) = 1
    ELSEIF obj_type = OBJ_KEY
        SOUND(OBJECTS_GET_SOUND)
        player_keys = player_keys + 1
        SCORE_ADD(50)
        print_keys()
        obj_collected(enit) = 1
    END IF
    END IF 'fin comida / obj_table
END IF
#endif
