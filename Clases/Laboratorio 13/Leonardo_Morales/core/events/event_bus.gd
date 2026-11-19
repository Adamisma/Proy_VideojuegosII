extends Node

## ====================================================================
## EventBus (Autoload Global Desacoplado)
## ====================================================================
## Administra eventos transversales de alcance amplio entre sistemas desacoplados
## (UI, audio, analytics, scene flow).
## Las advertencias UNUSED_SIGNAL se silencian con @warning_ignore("unused_signal")
## debido a que, por diseño del patrón EventBus, las señales son emitidas
## por otros emisores externos (Player, Checkpoint, GameState, etc.)
## y escuchadas por receptores remotos (HUD, LevelController, etc.).

@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal checkpoint_activated(checkpoint_id: StringName)
@warning_ignore("unused_signal")
signal score_changed(new_score: int)
@warning_ignore("unused_signal")
signal level_completed(level_id: StringName)
@warning_ignore("unused_signal")
signal player_damaged(current_hp: int, max_hp: int)
