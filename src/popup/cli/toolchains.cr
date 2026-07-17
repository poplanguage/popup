require "colorize"

class Popup::CLI::Toolchains
  def self.register(cmd)
    cmd.subcommand("toolchain", "List, install or delete toolchains") do |toolchain|
      tool_manager = Toolchain.new

      toolchain.subcommand("list", "List toolchains") do |tclist|
        tclist.run do
          versions = tool_manager.versions

          versions.each do |version|
            puts version.colorize.bold
          end
        end
      end
    end
  end
end
