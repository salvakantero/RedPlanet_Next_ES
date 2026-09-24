'definición de niveles
'cada array tiene los valores para cada nivel, empezando por el 0, que es el primer nivel

'número de tileset y beh que usa cada nivel // Ej. Para un valor 1, usará los archivos: "tiles_1.spr +  beh1.bin"
dim level_tileset(MAX_LEVELS-1) as ubyte => {LEVELS_TILESETS}

'fichero de sprites enemigos para cada nivel // Ej. "enemies_1.spr"
dim level_enemsprite(MAX_LEVELS-1) as ubyte => {LEVELS_ENEMIES}

'número de temas musicales
dim level_music(MAX_LEVELS-1) as ubyte => {LEVELS_MUSICS}


