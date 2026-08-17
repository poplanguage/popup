require "term-prompt"
require "colorize"

class Popup::CLI::Install
  def self.register(cmd)
    cmd.subcommand("install", "Install the Pop toolchain") do |install|
      version = ""

      install.positional("version", String, required: false, description: "Version to install") do |v|
        version = v
      end

      install.run do
        install(version.empty? ? nil : version, true)
      end
    end
  end

  def self.install(version : String? = nil, prompt_for_path = false) : Toolchain
    installer = Installer.new(version)
    archive_path = installer.install
    current_version = installer.version
    target = installer.target
    toolchain = Toolchain.new

    Installer::Setup.new(
      current_version,
      archive_path,
      toolchain.toolchains_dir,
      target.triple
    ).run
    toolchain.install(current_version, target)

    Log.info { "toolchain #{current_version} installed successfully".colorize(:green) }
    prompt_add_to_path(toolchain) if prompt_for_path
    toolchain
  end

  private def self.prompt_add_to_path(toolchain : Toolchain) : Nil
    if ENV["PATH"].split(":").includes?(toolchain.bin_dir)
      return
    end

    shell = File.basename(ENV["SHELL"]?.to_s)
    profile = detect_shell_profile(shell)
    return unless profile

    if already_configured?(profile, toolchain.bin_dir)
      Log.info { "PATH already configured in #{profile}" }
      return
    end

    prompt = Term::Prompt.new
    if prompt.yes?("Add popup to your PATH in #{profile}?")
      File.open(profile, "a") do |file|
        file.puts
        file.puts "# popup"
        file.puts Popup::Environment.render(shell, toolchain)
      end

      Log.info { "added to #{profile}" }
    else
      Log.info { "run 'popup env #{shell}' or add its output to #{profile}" }
    end
  end

  private def self.detect_shell_profile(shell : String) : String?
    case shell
    when "zsh"
      File.join(ENV["HOME"], ".zshrc")
    when "bash"
      File.join(ENV["HOME"], ".bashrc")
    when "fish"
      File.join(ENV["HOME"], ".config", "fish", "config.fish")
    end
  end

  private def self.already_configured?(profile : String, bin_dir : String) : Bool
    if File.exists?(profile)
      File.read_lines(profile).any? do |line|
        line.includes?(bin_dir)
      end
    else
      false
    end
  end
end
