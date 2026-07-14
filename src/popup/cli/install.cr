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
        current = version.empty? ? GitHub.latest_release_tag : version
        toolchain = Toolchain.new
        archive_path = Installer.new(current).install

        Installer::Setup.new(current, archive_path, toolchain.toolchains_dir).run
        toolchain.install(current, Utils::Target.target_string)

        prompt_add_to_path(toolchain)
      end
    end
  end

  private def self.prompt_add_to_path(toolchain : Toolchain) : Nil
    return if ENV["PATH"].to_s.split(":").includes?(toolchain.bin_dir)

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
    else
      nil
    end
  end

  private def self.already_configured?(profile : String) : Bool
    return false unless File.exists?(profile)

    File.read_lines(profile).any? do |line|
      line.strip == %(export PATH="$HOME/.popup/bin:$PATH")
    end
  end
end
