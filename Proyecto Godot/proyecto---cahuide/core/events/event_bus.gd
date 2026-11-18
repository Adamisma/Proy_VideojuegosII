extends Node

## ====================================================================
## Proyecto Cahuide - EventBus Global Desacoplado
## ====================================================================
## Centraliza eventos transversales entre jugador, enemigos, nivel y UI.

@warning_ignore("unused_signal")
signal player_damaged(current_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal player_powerup_activated(duration: float)
@warning_ignore("unused_signal")
signal player_powerup_ended
@warning_ignore("unused_signal")
signal ranged_weapon_swapped(weapon_name: String)

@warning_ignore("unused_signal")
signal score_changed(new_score: int)
@warning_ignore("unused_signal")
signal relic_collected(remaining: int, total: int)
@warning_ignore("unused_signal")
signal enemy_defeated(score_awarded: int)
@warning_ignore("unused_signal")
signal checkpoint_activated(checkpoint_id: StringName)
@warning_ignore("unused_signal")
signal level_completed(level_id: StringName)
@warning_ignore("unused_signal")
signal game_paused(is_paused: bool)
