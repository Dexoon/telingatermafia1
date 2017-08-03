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

  Telegram::Bot::Client.run(token) do |bot|
    bot.listen do |message|
      if ENV['NEXT']
        next
        puts 'try'
      end
      # begin
      case message
      when Telegram::Bot::Types::CallbackQuery
        # Here you can handle your callbacks from inline buttons
        next if message.message.nil? # may be useful when original message have already been deleted and user cannot influense on situation
        puts message.data
        query = message.data.decode
        puts message.message.chat.id.to_s+' '+message.message.message_id.to_s
        @message = Message.find_by(chat_id: message.message.chat.id,
                                   message_id: message.message.message_id)
        puts query
       @message.process_query(query, bot)
      when Telegram::Bot::Types::Message
        new_message = bot.api.send_message(chat_id: message.chat.id, text: 'hey')
        puts new_message
        @message = Message.create(chat_id: new_message["result"]["chat"]["id"], message_id: new_message["result"]["message_id"])
        @message.save
        @message.process_query({}, bot)
      end
      # rescue
      #  next
      # end
    end
  end
end

# bot.api.deleteMessage(chat_id: message.message.chat.id, message_id: message.message.message_id) Код удаления сообщения
