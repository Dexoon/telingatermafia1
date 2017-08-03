$key_list_CONST = %w[game_id user_id value position].freeze
$query_types_CONST = {
  'task' => %w[start_game end_game set_result delete_game delete_last randomize
               add_player new_game add_points load_game change_rating next
               set_result],
  'point_type' => %w[score fouls pending_fouls],
  'sure' => [false, true]
}
