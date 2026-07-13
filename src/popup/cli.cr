require "option_builder"
require "term-progress"

class Popup::CLI
  def self.setup
    command = OptionBuilder.command("popup", "The Pop toolchain manager tool") do |cmd|
      cmd.subcommand("install", "Install the Pop toolchain") do |install|
        version = ""

        install.positional("version", String, required: false, description: "Version to install") do |v|
          version = v
        end

        install.run do
          current_version = version.empty? ? GitHub.lastest_release_tag : version
          Installer.new(current_version).install
        end
      end
    end

    command.execute
  end
end
