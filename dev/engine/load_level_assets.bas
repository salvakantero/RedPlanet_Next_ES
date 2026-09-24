'sprites del player
LoadSDBank ("spr/player.spr",0,0,0,32)

'carga el mapa en los bancos 90,91
fichero = "bin/maps/level_"+str(level_number)+"_tiles.bin"
LoadSDBank (fichero,0,0,0,90)

'carga los sprites enemigos del subnivel actual
fichero = "spr/enemies_"+str(level_enemsprite(level_number))+".spr"
LoadSDBank (fichero,0,0,0,34)

'carga los tilesets
fichero = "spr/tiles_"+str(level_tileset(level_number))+".spr"
LoadSDBank (fichero,0,0,0,36)

'carga los archivos beh para el tileset
fichero = "bin/beh/beh"+str(level_tileset(level_number))+".bin"
LoadSD(fichero,@behs(0),128,0)

'carga los datos de los enemigos en ENEMIES_BUFFER
fichero = "bin/maps/level_"+str(level_number)+"_enemies.bin"
'calcula el tamaño del archivo de enemigos a cargar basado en el número de enemigos por pantalla
size = 12*MAX_ENEMS
LoadSD(fichero, ENEMIES_BUFFER, size, 0)

reset_enems() 'resetea los enemigos, pone todo a tipo 0
total_enemies = peek(ENEMIES_BUFFER) 'leemos el número de sprites del mapa actual
if total_enemies then enems_load () 'copia los datos de los enemigos a la estructura de enemigos en memoria

reset_bullets() 'resetea las balas




