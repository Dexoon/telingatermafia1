require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TelingaterMafiaBot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

module TelegramBot
  class Message
    attribute :forward_from, User
  end
end

class Array
  def to_2_dim(column_size)
    newarray = []
    (0..size - 1).step(column_size) do |x|
      layer = []
      (0..column_size - 1).to_a.each do |y|
        layer += [self[x + y]] if x + y < size
      end
      newarray += [layer]
    end
    newarray
  end
end

class Integer
  def to_roman
    roman_arr = {
      1000 => 'M',
      900 => 'CM',
      500 => 'D',
      400 => 'CD',
      100 => 'C',
      90 => 'XC',
      50 => 'L',
      40 => 'XL',
      10 => 'X',
      9 => 'IX',
      5 => 'V',
      4 => 'IV',
      1 => 'I'
    }
    num = self

    roman_arr.reduce('') do |res, (arab, roman)|
      whole_part, num = num.divmod(arab)
      res << roman * whole_part
    end
  end
end
