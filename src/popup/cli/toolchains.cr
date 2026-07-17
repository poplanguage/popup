require "colorize"
require "term-prompt"

class Popup::CLI::Toolchains
  def self.register(cmd)
    cmd.subcommand("toolchain", "List, install or delete toolchains") do |toolchain|
      tool_manager = Toolchain.new
      versions = tool_manager.versions

      toolchain.subcommand("list", "List toolchains") do |tclist|
        tclist.run do
          versions.each do |version|
            puts version.colorize.bold
          end
        end
      end

      toolchain.subcommand("uninstall", "Remove a toolchain from your computer") do |uninstall|
        uninstall.run do
          raise "no toolchains installed" if versions.empty?

          prompt = Term::Prompt.new
          chosen = prompt.select("Select toolchain to uninstall:", versions)

          raise "no toolchain selected" if chosen.nil?

          tool_manager.uninstall(chosen)
          Log.info { "uninstalled toolchain #{chosen}" }
        end
      end
    end
  end
end
