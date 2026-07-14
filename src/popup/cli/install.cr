require "../installer"
require "../github"

class Popup::CLI::Install
  def self.register(cmd)
    cmd.subcommand("install", "Install the Pop toolchain") do |install|
      version = ""

      install.positional("version", String, required: false, description: "Version to install") do |v|
        version = v
      end

      install.run do
        current = version.empty? ? GitHub.lastest_release_tag : version
        Installer.new(current).install
        # TODO: Create the toolchain installer!
        # Toolchain.write_pop_shim
      end
    end
  end
end
