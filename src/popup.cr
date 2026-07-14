require "./popup/version"
require "./popup/cli/main"
require "./popup/utils/logger"

require "crest"

module Popup
  Log.setup do |config|
    config.bind "*", :info, Utils::Logger::Formatter.new
  end

  CLI.setup
end
