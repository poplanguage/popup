require "option_builder"
require "./install"

module Popup::CLI
  def self.setup
    command = OptionBuilder.command("popup", "The Pop toolchain manager tool") do |cmd|
      Install.register(cmd)
    end

    command.execute
  end
end
