task tg_bot: :environment do
  # BACKGROUND=y PIDFILE=daemon.pid LOG_LEVEL=info bundle exec rake start
  Rails.logger       = Logger.new(Rails.root.join('log', 'daemon.log'))
  Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)
  user_bot = TelegramBot.new(token: '315066645:AAGd2SdpVLnTPNgoC8CQKVBdFIubDGqriC4')
  Process.daemon(true, true) if ENV['BACKGROUND']

  File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid } if ENV['PIDFILE']

  Signal.trap('TERM') { abort }

  Rails.logger.info 'Start daemon...'

  loop do
    user_bot.get_updates(fail_silently: true) do |message|
      puts "@#{message.from.username}: #{message.text}. chat_id:#{message.chat.id}"
      Rails.logger.info "@#{message.from.username}: #{message.text}. chat_id:#{message.chat.id}"
      if message.forward_from.nil?
        @user = User.find_by_str(message.text)
        @user = User.find_by(telegram: message.from.id) if @user.nil?
      else
        @user = User.find_by(telegram: message.forward_from.id)
      end
      # command = message.get_command_for(bot)

      message.reply do |reply|
        reply.text = UsersController.change_online_status(@user)
        reply.send_with(user_bot)
      end
    end
    sleep ENV['INTERVAL'] || 1
  end
end
task vk_bot: :environment do
  # BACKGROUND=y PIDFILE=daemon.pid LOG_LEVEL=info bundle exec rake start
  Rails.logger       = Logger.new(Rails.root.join('log', 'daemon.log'))
  Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)
  vk_api = VkontakteApi::Client.new('6de30af059648a7c1107dee4d6db30026b659a21db0f693aa58656fabfe5777314300b97c9cbab85e184c')
  Process.daemon(true, true) if ENV['BACKGROUND']

  File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid } if ENV['PIDFILE']

  Signal.trap('TERM') { abort }

  Rails.logger.info 'Start daemon...'

  loop do
    message = vk_api.messages.get(count: 1)[1]
    if message[:read_state].zero?
      @user = User.find_by_str(message.body)
      @user = User.find_by(vk: message.uid) if @user.nil?
      vk_api.messages.markAsRead(message_ids: message.mid)
      reply = UsersController.change_online_status(@user)
      vk_api.messages.send(user_id: message.uid, message: reply)
    end
    sleep ENV['INTERVAL'] || 1
  end
end
