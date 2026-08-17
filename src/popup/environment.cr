module Popup
  # Prints shell-specific activation snippets.  Keeping this in popup rather
  # than mutating profiles lets users decide how their shell is configured.
  module Environment
    extend self

    def render(shell : String, toolchain = Toolchain.new) : String
      home = shell_quote(toolchain.base_dir, shell)
      bin = shell_quote(toolchain.bin_dir, shell)

      case shell.downcase
      when "sh", "bash", "zsh"
        "export POPUP_HOME=#{home}\nexport PATH=#{bin}:\"$PATH\""
      when "fish"
        "set -gx POPUP_HOME #{home}\nfish_add_path #{bin}"
      when "powershell", "pwsh", "ps1"
        "$env:POPUP_HOME = #{home}\n$env:Path = #{bin} + ';' + $env:Path"
      when "cmd", "cmd.exe"
        "set \"POPUP_HOME=#{toolchain.base_dir}\"\r\nset \"PATH=#{toolchain.bin_dir};%PATH%\""
      else
        raise "unsupported shell '#{shell}'. Supported shells: sh, bash, zsh, fish, powershell, cmd"
      end
    end

    private def shell_quote(value : String, shell : String) : String
      if shell.downcase.in?({"powershell", "pwsh", "ps1"})
        "'#{value.gsub("'", "''")}'"
      else
        "'#{value.gsub("'", %q('\\''))}'"
      end
    end
  end
end
