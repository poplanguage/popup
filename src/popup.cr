require "./popup/*"
require "./popup/cli/*"
require "./popup/installer/*"
require "./popup/utils/*"

require "crest"

module Popup
  Log.setup do |config|
    config.bind "*", :info, Utils::Logger::Formatter.new
  end

  CLI.setup
end
