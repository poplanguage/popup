require "term-prompt"
require "../installer"
require "../installer/setup"
require "../github"
require "../toolchain"
require "../utils/target"

class Popup::CLI::Install
  def self.register(cmd)
    cmd.subcommand("install", "Install the Pop toolchain") do |install|
      version = ""

      install.positional("version", String, required: false, description: "Version to install") do |v|
        version = v
      end

      install.run do
        current_version = version.empty? ? GitHub.latest_release_tag : version
        archive_path = Installer.new(current_version).install
        toolchain = Toolchain.new

        Installer::Setup.new(current_version, archive_path, toolchain.toolchains_dir).run
        toolchain.install(current_version, Utils::Target.target_string)

        prompt_add_to_path(toolchain)
      end
    end
  end

  private def self.prompt_add_to_path(toolchain : Toolchain) : Nil
    if ENV["PATH"].split(":").includes?(toolchain.bin_dir)
      return
    end

    profile = detect_shell_profile
    return unless profile

    if already_configured?(profile)
      puts "=> PATH already configured in #{profile}"
      return
    end

    prompt = Term::Prompt.new
    if prompt.yes?("Add popup to your PATH in #{profile}?")
      File.open(profile, "a") do |file|
        file.puts
        file.puts "# popup"
        file.puts %(export PATH="$HOME/.popup/bin:$PATH")
      end

      prompt.ok("Added to #{profile}")
    else
      puts "=> Add this line to #{profile}:"
      puts %(   export PATH="$HOME/.popup/bin:$PATH")
    end
  end

  private def self.detect_shell_profile : String?
    shell = ENV["SHELL"]?.to_s

    case File.basename(shell)
    when "zsh"
      File.join(ENV["HOME"], ".zshrc")
    when "bash"
      File.join(ENV["HOME"], ".bashrc")
    when "fish"
      File.join(ENV["HOME"], ".config", "fish", "config.fish")
    end
  end

  private def self.already_configured?(profile : String) : Bool
    if File.exists?(profile)
      true
    else
      File.read_lines(profile).any? do |line|
        line.strip == %(export PATH="$HOME/.popup/bin:$PATH")
      end
    end
  end
end
