require "option_builder"
require "./install"
require "./toolchains"

module Popup::CLI
  def self.setup
    command = OptionBuilder.command("popup", "The Pop toolchain manager tool") do |cmd|
      Install.register(cmd)
      Toolchains.register(cmd)
    end

    command.execute
  end
end
