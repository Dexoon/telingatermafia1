require 'telegram/bot'
task start: :environment do
  # BACKGROUND=y PIDFILE=daemon.pid LOG_LEVEL=info bundle exec rake start
  Rails.logger = Logger.new(Rails.root.join('log', 'daemon.log'))
  Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)

  Process.daemon(true, true) if ENV['BACKGROUND']

  File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid } if ENV['PIDFILE']

  Signal.trap('TERM') { abort }

  Rails.logger.info 'Start daemon...'
  token = '427251791:AAFrbJTOMo0pF6O4FCnXokqlLZCZhyuD5Do'

  @key_list = %w[game_id user_id value position]
  @query_types = {
    'task' => %w(start_game end_game count_result delete_game delete_last
      randomize add_player new_game add_points load_game change_rating next),
    'point_type' => %w[score fouls pending_fouls],
    'sure' => [false, true]
  }
  @encode_hash = {}
  @query_types.each do |query_type, array_of_values|
    @key_list += [query_type]
    @encode_hash[query_type] = {}
    array_of_values.each_with_index { |value, index| @encode_hash[query_type][value] = index }
  end
  @decode_hash = {}
  @encode_hash.each { |key, value| @decode_hash[key] = value.invert }

  def decode(str)
    query = {}
    str.split(',').map { |x| x == '' ? x.squeeze! : x.to_i }.each_with_index do |value, i|
      unless value.nil?
        query[@key_list[i]] = @decode_hash[@key_list[i]].nil? ? value : @decode_hash[@key_list[i]][value]
      end
    end
    query
  end

  def encode(query)
    str = ''
    @key_list.each do |key|
      unless query[key].nil?
        str += @encode_hash[key].nil? ? query[key].to_s : @encode_hash[key][query[key]].to_s
      end
      str += ','
    end
    str.chomp(',')
  end

  def button(text, query)
    Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: encode(query))
  end

  def player_list_kbr(game = Game.last, query = {}, players_range = game.players)
    keyboard = []
    players_range.each do |player|
      keyboard += [button(player.to_s, query.merge('position' => player.position))]
    end
    keyboard.to_2_dim(2)
  end

  def add_points_kbr(range, query)
    buttons = []
    range.to_a.each do |x|
      buttons += [button(x.to_s, query.merge('value' => x))]
    end
    buttons.to_2_dim(4)
  end

  def unfinished_games_kbr
    buttons = []
    Game.where.not(aasm_state: 'game_over').each do |game|
      buttons += [button("id: #{game.id}", 'game_id' => game.id)]
    end
    buttons.to_2_dim(4)
  end

  def available_players_kbr(game = Game.last)
    new_query = { 'game_id' => game.id, 'task' => 'add_player' }
    keyboard = []
    user_buttons = []
    if game.players.count < 12
      User.available(game).order(:surname).each do |user|
        user_buttons += [button(user.to_s, new_query.merge('user_id' => user.id))]
      end
    end
    keyboard += user_buttons.to_2_dim(2)
    keyboard += [button('Удалить последнего', 'task' => 'delete_last', 'game_id' => game.id)] unless game.players.count == 0
    keyboard += [button('Рандомизировать', 'task' => 'randomize', 'game_id' => game.id)] if game.players.count == 12
    keyboard += [button('Начать игру', 'task' => 'start_game', 'game_id' => game.id)] if game.players.count == 12
    keyboard
  end

  def delete_button(game = Game.last)
    button('Удалить игру', 'task' => 'delete_game', 'game_id' => game.id, 'sure' => false)
  end

  def fouls_button(game = Game.last)
    button('Фол',  'task' => 'add_points', 'point_type' => 'fouls', 'game_id' => game.id)
  end

  def pending_fouls_button(game = Game.last)
    button('Фол на сл. игру', 'task' => 'add_points', 'point_type' => 'pending_fouls', 'game_id' => game.id)
  end

  def score_button(game = Game.last)
    button('Балл', 'task' => 'add_points', 'point_type' => 'score', 'game_id' => game.id)
  end

  def refresh_button(game = Game.last)
    button('Обновить', 'game_id' => game.id)
  end

    def next_button(game = Game.last)
      button('Далее', 'task' => 'next','game_id' => game.id)
    end

  def edit_message(text, keyboard, message, bot)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
    if text != message.message.text
      bot.api.editMessageText(text: text, chat_id: message.message.chat.id, message_id: message.message.message_id, reply_markup: markup)
    else
      bot.api.editMessageReplyMarkup(chat_id: message.message.chat.id, message_id: message.message.message_id, reply_markup: markup)
    end
  end

  Telegram::Bot::Client.run(token) do |bot|
    bot.listen do |message|
      case message
      when Telegram::Bot::Types::CallbackQuery
        # Here you can handle your callbacks from inline buttons
        next if message.message.nil?
        query = decode(message.data)
        dbg = query.merge('dbg' => true)
        Rails.logger.info dbg
        keyboard = [[]]
        if query['task'] == 'load_game'
          keyboard += unfinished_games_kbr
          text_message = 'Выберите игру'
          edit_message(text_message, keyboard, message, bot)
          next
        end
        if query['sure'] == false
          keyboard += [button('Нет', query.merge('task' => nil, 'sure' => nil)), button('Да', query.merge('sure' => true))]
          text_message = 'Вы уверены?'
          edit_message(text_message, keyboard, message, bot)
          next
        end
        if query['game_id'].nil?
          @game = Game.new
          @game.save
          query['game_id'] = @game.id
        else
          @game = Game.find(query['game_id'])
        end
        text_message = 'id игры: ' + @game.id.to_s + '. Рейтинговая: '+ @game.rating.to_s+"\n"
        case query['task']
        when 'change_rating'
          @game.change_rating
        when 'delete_game'
          text_message += 'Игра удалена'
          # bot.api.deleteMessage(chat_id: message.message.chat.id, message_id: message.message.message_id) Код удаления сообщения
          @game.delete
          edit_message(text_message, keyboard, message, bot)
          next
        when 'start_game', 'end_game', 'count_result', 'next'
          @game.next!
        when 'add_points'
          if query['position'].nil?
            keyboard = player_list_kbr(@game, query)
            text_message += @game.players.to_str
            edit_message(text_message, keyboard, message, bot)
            next
          else
            player = @game.players[query['position'] - 1]
            if query['value'].nil?
              range = (-1..2)
              range = (-3..4) if query['point_type'] == 'score'
              keyboard = add_points_kbr(range, query)
              text_message += player.to_s(query['point_type'] => true)
              edit_message(text_message, keyboard, message, bot)
              next
            else
              player.add_points(query['point_type'], query['value'])
            end
          end
        when 'add_player'
          if @game.players.map(&:user_id).include?(query['user_id']) || @game.players.count > 11
            next
          else
            @game.players.create(user_id: query['user_id'])
          end
        when 'delete_last'
          @game.delete_last
        when 'randomize'
          @game.randomize
        end
        case @game.aasm_state
        when 'settings'
          text_message += "В данный момент игра "
          text_message += "не " unless @game.rating
          text_message += "рейтинговая. Изменить?"
          keyboard = [button('Изменить', 'task' => 'change_rating', 'game_id' => @game.id)]+[next_button(@game)]
        when 'select_players'
          keyboard = available_players_kbr(@game)
          text_message += @game.players.to_str
        when 'game'
          keyboard += [fouls_button(@game)] + [button('Подсчёт очков', 'task' => 'count_result', 'game_id' => @game.id)]
          text_message += @game.players.to_str('fouls' => true)
        when 'count_result'
          keyboard += ([score_button(@game)] + [pending_fouls_button(@game)])
          keyboard += [button('Подвести результаты', 'task' => 'end_game', 'game_id' => @game.id)]
          text_message += @game.players.to_str('score' => true)
        when 'game_over'
          text_message += @game.players.to_str('score' => true)
        end
        edit_message(text_message, keyboard + [delete_button(@game)], message, bot)
      when Telegram::Bot::Types::Message
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [button('New game', 'task' => 'new_game'), button('Load game', 'task' => 'load_game')])
        bot.api.send_message(chat_id: message.chat.id, text: 'Main menu', reply_markup: markup)
      end
    end
  end
end
