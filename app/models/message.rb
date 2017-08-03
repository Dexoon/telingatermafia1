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
    state :role
    state :load_game
    event :set_role do
      transitions to: :set_position, unless: :position_set?, success: :view
      transitions to: :role, unless: :role_set?, success: :view
      transitions to: :game, success: :touch
    end
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
    event :set_game, after: :game_define do
      transitions to: :game
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

  def game_define(query)
    update(game_id: query['game_id'])
    view
  end

    def role_set?(query)
      !query['role'].nil?
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
    game.messages.each do |msg|
      puts 'View:' + msg.id.to_s
      msg.view({}, @bot)
    end
  end

  def abandon_game
    update(game_id: nil)
    view
  end

  def edit(text, keyboard, bot = @bot)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)

    bot.api.editMessageText(text: text, chat_id: chat_id,
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
    when 'new_game', 'load_game', 'back', 'add_points', 'delete_game', 'set_game', 'set_role'
      puts 'here we are'
      send(query['task'] + '!', query)
    else
      if game_id.nil?
        view(query)
      else
        res = touch(query)
        # return false if res[:result] == 'fail'
      end
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
    puts query

  buttons = []
    range.to_a.each do |x|
      buttons += [button(x.to_s, query.merge('value' => x))]
    end
    buttons.to_2_dim(width)
  end

  def games_btns(games = Game.where.not(aasm_state: 'game_over'), width = 4)
    buttons = []
    games.each do |game|
      buttons += [button("id: #{game.id}", 'task' => 'set_game', 'game_id' => game.id)]
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

  def choose_role(query = {}, roles = %w[don mafia putain doctor maniac comissar citizen], width = 2)
    puts query
    buttons = []
    roles.each do |role|
      buttons += [button(role, query.merge('role' => role))]
    end
    buttons.to_2_dim(width)
  end

  $buttons_queries = {
    'next' => ['Далее', { 'task' => 'next' }],
    'back' => ['Назад', { 'task' => 'back' }],
    'refresh' => ['Обновить', {}],
    'score' => ['Балл', { 'task' => 'add_points', 'point_type' => 'score' }],
    'set_role' => ['Установить роль', { 'task' => 'set_role' }],
    'don' => ['Дон', { 'role' => 'don' }],
    'mafia' => ['Мафия', { 'role' => 'mafia' }],
    'putain' => ['Путана', { 'role' => 'putain' }],
    'citizen' => ['Мирный', { 'role' => 'citizen' }],
    'doctor' => ['Доктор', { 'role' => 'doctor' }],
    'maniac' => ['Маньяк', { 'role' => 'maniac' }],
    'comissar' => ['Комиссар', { 'role' => 'comissar' }],
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
    when 'choose_role'
      choose_role(@query)
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

  def view(query = {}, bot = @bot)
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
    when 'role'
      text = 'Выберите роль'
      keyboard += [['choose_role']]
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
        keyboard += [['set_role']]
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
      keyboard += [['foul']] unless query['point_type'] == 'foul' || ['game_over', 'settings', 'select_players', nil].include?(game.aasm_state)
      # keyboard += [['delete_game']] unless game.aasm_state.nil?
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
    edit(text, keys, bot)
  end
end
