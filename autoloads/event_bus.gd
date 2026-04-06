extends Node

# --- Player ---
signal player_state_changed(new_state: String)       # "ground" | "air"
signal player_health_changed(new_health: int)
signal player_energy_changed(new_energy: int)
signal player_took_damage(damage: int, source_position: Vector3)
signal player_fell()
signal player_respawned()
signal player_plugged_in()
signal player_unplugged(energy_gained: float)

# --- Enemies ---
signal enemy_died(enemy_type: String, world_position: Vector3, over_pit: bool)
signal enemy_count_changed(count: int)

# --- Floor ---
signal tile_damaged(grid_pos: Vector2i, new_hp: int)
signal tile_destroyed(grid_pos: Vector2i)

# --- Waves ---
signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)

# --- Session ---
signal game_over(waves_survived: int, elapsed_seconds: float)
signal session_restarted()
