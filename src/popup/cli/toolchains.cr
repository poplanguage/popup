require "colorize"

class Popup::CLI::Toolchains
  def self.register(cmd)
    cmd.subcommand("toolchains", "List, install or delete toolchains") do |toolchains|
      toolchain = Toolchain.new

      toolchains.subcommand("list", "List toolchains") do |tclist|
        tclist.run do
          versions = toolchain.versions
          active = toolchain.active_version

          versions.each do |version|
            prefix = version == active ? "* " : "  "
            puts "#{prefix}#{version.colorize.bold}"
          end
        end
      end

      toolchains.subcommand("default", "Select the default toolchain") do |default|
        version = ""
        default.positional("version", String, required: true, description: "Installed version") { |v| version = v }
        default.run { toolchain.default = version }
      end

      toolchains.subcommand("uninstall", "Remove an inactive toolchain") do |uninstall|
        version = ""
        uninstall.positional("version", String, required: true, description: "Installed version") { |v| version = v }
        uninstall.run { toolchain.uninstall(version) }
      end
    end
  end
end
