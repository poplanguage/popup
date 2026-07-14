require "colorize"

class Popup::CLI::Toolchains
  def self.register(cmd)
    cmd.subcommand("toolchains", "List, install or delete toolchains") do |toolchains|
      toolchain = Toolchain.new

      toolchains.subcommand("list", "List toolchains") do |tclist|
        tclist.run do
          versions = toolchain.versions

          versions.each do |version|
            puts version.colorize.bold
          end
        end
      end
    end
  end
end
