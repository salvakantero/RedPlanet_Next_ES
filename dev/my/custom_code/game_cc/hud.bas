' ETIQUETAS PERSONALIZADAS DEL HUD

LoadSD("gfx/hud.scr",$4000,6912,0)
' hud.scr ocupa toda la pantalla y sus filas bajo el HUD son negras opacas.
' Las borramos a transparente (paper 3) hasta el borde inferior de la caja de dialogo,
' para que el juego se vea en el hueco sobre la caja centrada (no solo donde va el texto).
delete_hud(HUD_HEIGHT*2)
CROP_ULA

ink 7
bright 0
paper 0

print at SCORE_Y,1;"RECORD:"
print at SCORE_Y,SCORE_X-7;"PUNTOS:"

print_ammo()
print_keys()
