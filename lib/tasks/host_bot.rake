require 'telegram/bot'
task start: :environment do
  # BACKGROUND=y PIDFILE=daemon.pid LOG_LEVEL=info bundle exec rake start
  Rails.logger       = Logger.new(Rails.root.join('log', 'daemon.log'))
  Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)

  Process.daemon(true, true) if ENV['BACKGROUND']

  File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid } if ENV['PIDFILE']

  Signal.trap('TERM') { abort }

  Rails.logger.info 'Start daemon...'
  token = '427251791:AAFrbJTOMo0pF6O4FCnXokqlLZCZhyuD5Do'

  def available_players_buttons(_game = Game.last)
    new_query = {}
    new_query ['game_id'] = @game.id
    new_query ['task'] = 'add_player'
    keyboard = [[]]
    if @game.players.count < 12
      i = 0
      until User.available(@game).limit(2).offset(2 * i).ids.empty?
        layer = []
        User.available(@game).limit(2).offset(2 * i).ids.map do |id|
          new_query['user_id'] = id
          layer += [
            Telegram::Bot::Types::InlineKeyboardButton.new(text: User.find(id).name.to_s + ' ' + User.find(id).surname.to_s, callback_data: new_query.to_json)
          ]
        end
        keyboard += [layer]
        i += 1
      end
    end
    new_query ['task'] = 'delete_last'
    keyboard += [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Удалить последнего', callback_data: new_query.to_json)] unless @game.players.count == 0
    new_query ['task'] = 'randomize'
    keyboard += [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Рандомизировать', callback_data: new_query.to_json)] if @game.players.count == 12
    new_query ['task'] = 'start_game'
    keyboard += [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Начать игру', callback_data: new_query.to_json)] if @game.players.count == 12
    keyboard
  end

  def delete_button(game)
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Удалить игру', callback_data: { 'task' => 'delete_game', 'game_id' => game.id }.to_json)]
  end

  Telegram::Bot::Client.run(token) do |bot|
    bot.listen do |message|
      case message
      when Telegram::Bot::Types::CallbackQuery
        # Here you can handle your callbacks from inline buttons
        query = JSON[message.data]
        if query['game_id'].nil?
          @game = Game.new
          @game.save
          query['game_id'] = @game.id
        else
          @game = Game.find(query['game_id'])
        end
        if query['task'] == 'delete_game'
          bot.api.deleteMessage(chat_id: message.message.chat.id, message_id: message.message.message_id)
          @game.delete
          next
        end
        @game.start_game! if query['task'] == 'start_game'
        @game.end_game! if query['task'] == 'end_game'
        case @game.aasm_state
        when 'select_players'
          case query['task']
          when 'add_player'
            @game.players.create(user_id: query['user_id'])
          when 'delete_last'
            @game.delete_last
          when 'randomize'
            new_order = Array.new(12, 0)
            base = (0..11).to_a
            for i in 0..11
              y = (rand * (12 - i)).to_i
              new_order[i] = 1 + base[y]
              base.delete_at(y)
            end
            i = 0
            @game.players.each do |player|
              player.insert_at(new_order[i])
              i += 1
            end
          end
          keyboard = available_players_buttons(@game)
          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard + delete_button(@game))
          bot.api.editMessageText(text: @game.player_list, chat_id: message.message.chat.id, message_id: message.message.message_id, reply_markup: markup)
        when 'count_result'
          case query['task']
          when 'change_score'
            new_query = {}
            new_query ['game_id'] = @game.id
            new_query ['task'] = 'add_score'
            new_query['position'] = query ['position']
            keyboard = [[]]
            (-1..1).to_a.each do |line_num|
              layer = []
              (0..2).to_a.each do |column_num|
                new_query['change'] = 3 * line_num + column_num
                layer += [
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: (3 * line_num + column_num).to_s, callback_data: new_query.to_json)
                ]
              end
              keyboard += [layer]
            end
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard + delete_button(@game))
            bot.api.editMessageText(text: @game.player_list_with_score, chat_id: message.message.chat.id, message_id: message.message.message_id, reply_markup: markup)

          else
            @game.players[query['position'] - 1].update(score: @game.players[query['position'] - 1].score + query['change']) unless query['position'].nil?
            new_query = {}
            new_query ['game_id'] = @game.id
            new_query ['task'] = 'change_score'
            keyboard = [[]]
            i = 0
            until @game.players.order(:position).limit(2).offset(2 * i).empty?
              layer = []
              @game.players.order(:position).limit(2).offset(2 * i).map do |player|
                new_query['position'] = player.position
                layer += [
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: player.position.to_s + ' ' + player.user.name.to_s + ' ' + player.user.surname.to_s, callback_data: new_query.to_json)
                ]
              end
              keyboard += [layer]
              i += 1
            end
            new_query ['task'] = 'end_game'
            keyboard += [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Подвести результаты', callback_data: new_query.to_json)]
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard + delete_button(@game))
            bot.api.editMessageText(text: @game.player_list_with_score, chat_id: message.message.chat.id, message_id: message.message.message_id, reply_markup: markup)
          end
        when 'game_over'
          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: delete_button(@game))
          bot.api.editMessageText(text: @game.player_list_with_score, chat_id: message.message.chat.id, message_id: message.message.message_id, reply_markup: markup)
        end
      when Telegram::Bot::Types::Message
        res = {}
        res['task'] = 'new_game'
        keyboard = [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: 'New game', callback_data: res.to_json)
        ]
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
        bot.api.send_message(chat_id: message.chat.id, text: 'Main menu', reply_markup: markup)
      end
    end
  end
end
