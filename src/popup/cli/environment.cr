class Popup::CLI::Environment
  def self.register(cmd)
    cmd.subcommand("env", "Print shell commands that activate popup") do |environment|
      shell = ""
      environment.positional("shell", String, required: false, description: "sh, bash, zsh, fish, powershell or cmd") { |v| shell = v }
      environment.run do
        selected = shell.empty? ? inferred_shell : shell
        puts Popup::Environment.render(selected)
      end
    end
  end

  private def self.inferred_shell : String
    shell = ENV["SHELL"]?.to_s
    return "powershell" if shell.empty? && Utils::Target.windows?
    name = File.basename(shell)
    name.empty? ? "sh" : name
  end
end
