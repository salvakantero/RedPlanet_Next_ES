'INSERT HERE CODE FOR GAME ENDING'

update_hiscore()
'Secuencia de explosiones
PRINT_HUD
expl_seed = 137
for expl_round = 0 to 23
    ' Cargar frame de explosión (alternar 10/11)
    asm : nextreg $50,34 : nextreg $51,35 : end asm
    direccion = (10 + (expl_round MOD 2)) * 256
    for expl_i = 0 to 4
        Test_SetSprites(1, direccion, expl_i)
    next expl_i
    asm : nextreg $50,$ff : nextreg $51,$ff : end asm
    ' Posicionar 5 explosiones simultáneas
    for expl_i = 0 to 4
        expl_seed = expl_seed * 181 + 59
        _x1 = 48 + (expl_seed MOD 192)
        expl_seed = expl_seed * 181 + 59
        _y = 72 + (expl_seed MOD 128)
        UpdateSprite(_x1, _y, expl_i, expl_i, 0, 0)
    next expl_i
    PlaySFX(16) 'trueno'
    pause 6
next expl_round
' Ocultar sprites de explosión
for expl_i = 0 to 4
    RemoveSprite(expl_i, 0)
next expl_i

clear_sprites()
PRINT_HUD
track = MUSIC_ENDING : play_music()
EnableMusic 'SILENCIO solo silencia durante la partida, no en el final
'Pantalla de estadísticas en lugar de DIALOG standard
print_stats("MISION COMPLETADA!", "HORA DE REGRESAR A CASA!")


