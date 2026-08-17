require "option_builder"
require "./install"
require "./toolchains"
require "./environment"
require "./update"

module Popup::CLI
  def self.setup
    command = OptionBuilder.command("popup", "The Pop toolchain manager tool") do |cmd|
      Install.register(cmd)
      Toolchains.register(cmd)
      Environment.register(cmd)
      Update.register(cmd)
    end

    command.execute
  end
end
