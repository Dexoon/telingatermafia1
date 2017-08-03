class Message < ApplicationRecord
  belongs_to :game, optional: true
  include AASM
  aasm whiny_transitions: false do
    state :main_menu, initial: true
    state :game
    state :foul
    state :remove_foul
    state :set_position
    state :set_value
    state :load_game
    event :add_points do
      transitions to: :set_position, unless: :position_set?, success: :view
      transitions to: :set_value, unless: :value_set?, success: :view
      transitions to: :game, success: :touch
    end
    event :exit_game do
      transitions from: :game, to: :main_menu, success: :abandon_game
    end
    event :delete_game do
      transitions to: :main_menu, success: :touch
    end
    event :new_game do
      transitions from: :main_menu, to: :game, success: :create_game
    end
    event :load_game, success: :view do
      transitions from: :main_menu, to: :load_game
    end
    event :back, success: :view do
      transitions from: :load_game, to: :main_menu
      transitions to: :game,  guard: :game_set?
      transitions to: :main_menu
    end
  end

  def game_set?
    !game_id.nil?
  end

  def position_set?(query)
    !query['position'].nil?
  end

  def value_set?(query)
    !query['value'].nil?
  end

  def touch(query)
    res = game.touch(query)
    puts 'result: ' + res[:result]
    return false if res[:result] == 'fail'
    view
  end

  def abandon_game
    update(game_id: nil)
    view
  end

  def edit(text, keyboard)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)

    @bot.api.editMessageText(text: text, chat_id: chat_id,
                             message_id: message_id, reply_markup: markup,
                             parse_mode: 'Markdown')
  end

  def process_query(query = {}, bot = @bot)
    @bot = bot
    @query = query
    if query['sure'] == false
      keyboard = [button('Нет', {}), button('Да', query.except('sure'))]
      text = 'Вы уверены?'
      edit(text, keyboard)
      return
    end
    puts 'f' + query['task'] unless query['task'].nil?
    case query['task']
    when 'new_game', 'load_game', 'back', 'add_points', 'delete_game'
      puts 'here we are'
      send(query['task'] + '!', query)
    else
      unless game_id.nil?
        res = game.touch(query)
        puts 'result: ' + res[:result]
        puts 'description: ' + res[:descripton] if res[:result] == 'fail'
        return false if res[:result] == 'fail'
      end
      view(query)
    end
    puts 'we\'re here'
  end

  def create_game(query = {})
    @game = Game.new
    @game.save
    puts 'hey'
    update(game_id: @game.id)

    puts @game.id.to_s + 'tried to update' + game_id.to_s
    view(query)
  end

  def button(text, query = {})
    Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: query.encode)
  end

  def position_btns(query, players_range = game.players, width = 2)
    keyboard = []
    players_range.each do |player|
      keyboard += [button(player.to_s, query.merge('position' => player.position))]
    end
    keyboard.to_2_dim(width)
  end

  def points_btns(query, range = (-1..4), width = 4)
    buttons = []
    range.to_a.each do |x|
      buttons += [button(x.to_s, query.merge('value' => x))]
    end
    buttons.to_2_dim(width)
  end

  def games_btns(games = Game.where.not(aasm_state: 'game_over'), width = 4)
    buttons = []
    games.each do |game|
      buttons += [button("id: #{game.id}", 'game_id' => game.id)]
    end
    buttons.to_2_dim(width)
  end

  def users_btns(query, users = User.available(game), width = 2)
    query['task'] = 'add_player'
    buttons = []
    users.each do |user|
      buttons += [button(user.to_s, query.merge('user_id' => user.id))]
    end
    buttons.to_2_dim(width)
  end

  $buttons_queries = {
    'next' => ['Далее', { 'task' => 'next' }],
    'back' => ['Назад', { 'task' => 'back' }],
    'refresh' => ['Обновить', {}],
    'score' => ['Балл', { 'task' => 'add_points', 'point_type' => 'score' }],
    'foul' => ['Фол', { 'task' => 'add_points', 'point_type' => 'fouls', 'value' => 1 }],
    'remove_foul' => ['Убрать фол', { 'task' => 'add_points', 'point_type' => 'fouls', 'value' => -1 }],
    'delete_game' => ['Удалить игру', { 'task' => 'delete_game', 'sure' => false }],
    'randomize' => ['Рандомизировать', { 'task' => 'randomize' }],
    'end_game' => ['Подвести результаты', { 'task' => 'end_game', 'sure' => 'no' }],
    'new_game' => ['Новая игра', { 'task' => 'new_game' }],
    'start_game' => ['Начать игру', { 'task' => 'start_game' }],
    'load_game' => ['Продолжить игру', { 'task' => 'load_game' }],
    'game_over' => ['Окончить игру', { 'task' => 'game_over' }],
    'delete_last' => ['Удалить последнего', { 'task' => 'delete_last' }],
    'red' => ['Победили мирные', { 'task' => 'set_result', 'value' => 1 }],
    'black' => ['Победила мафия', { 'task' => 'set_result', 'value' => -1 }],
    'draw' => ['Ничья', { 'task' => 'set_result', 'value' => 0 }],
    'change_rating' => ['Изменить рейтинговость', { 'task' => 'change_rating' }]

  }
  def button_by_name(name, query = {})
    puts name
    case name
    when 'availiable_users'
      users_btns(query)
    when 'unfinished_games'
      games_btns
    when 'add_score'
      points_btns(@query, (-3..4))
    when 'set_position'
      position_btns(@query)
    else
      puts name
      if $buttons_queries[name].nil?
        return [button('!!' + name, { 'task' => name }.merge(query))]
      else
        if $buttons_queries[name][1].nil?
          return [button('!' + $buttons_queries[name][0], { 'task' => name }.merge(query))]
        else
          return [button($buttons_queries[name][0], $buttons_queries[name][1].merge(query))]
        end
      end
    end
  end

  def view(query = {})
    keyboard = []
    puts 'state:' + aasm_state
    case aasm_state
    when 'main_menu'
      text = 'choose wisely'
      keyboard += [['new_game']] + [['load_game']]
    when 'load_game'
      text = 'Выберите игру'
      keyboard += [['unfinished_games']]
    when 'set_position'
      text = game.to_s
      keyboard += [['set_position']]
      keyboard += [['remove_foul']] if query['point_type'] == 'fouls' && query['value'] == 1
    when 'set_value'
      text = game.players[query['position'] - 1].to_s
      keyboard += [['add_score']]
    else
      puts 'game_id:' + game_id.to_s unless game_id.nil?
      case game.aasm_state
      when nil
        text = 'Игра удалена'
      when 'settings'
        text = game.to_s
        keyboard += [['change_rating'], ['next']]
      when 'select_players'
        keyboard += [['availiable_users']] if game.players.count < 12
        keyboard += [['delete_last']] if game.players.count > 0
        keyboard += [['start_game'], ['randomize']] if game.players.count == 12
        text = game.to_s
      when 'game'
        keyboard += [['game_over']]
        text = game.to_s('fouls' => true)
      when 'set_result'
        keyboard += [['next']] unless game.result.nil?
        keyboard += [['red'], ['black'], ['draw']]
        text = game.to_s('result' => true)
      when 'set_score'
        keyboard += [['score'], ['end_game']]
        text = game.to_s('score' => true)
      when 'game_over'
        text = game.to_s('score' => true)
      end
      keyboard += [['foul']] unless query['point_type'] == 'foul' || game.aasm_state == 'settings' || game.aasm_state == 'select_players' || game.aasm_state.nil?
      keyboard += [['delete_game']] unless game.aasm_state.nil?
    end
    keys = [[]]
    keyboard.each do |line|
      puts line
      line.each { |btn| keys += button_by_name(btn) }
    end
    #
    # keyboard.map do |line|
    #  keys += [button_by_name(line)] unless line.nil? ||line==''
    # end
    edit(text, keys)
  end
end
