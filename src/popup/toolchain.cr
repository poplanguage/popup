require "file_utils"

module Popup
  class Toolchain
    DEFAULT_BASE_DIR = File.join(ENV["HOME"], ".popup")

    getter base_dir : String
    getter bin_dir : String
    getter toolchains_dir : String
    getter shim_path : String
    getter language_server_shim_path : String

    def initialize(@base_dir = ENV.fetch("POPUP_HOME", DEFAULT_BASE_DIR))
      @bin_dir = File.join(@base_dir, "bin")
      @toolchains_dir = File.join(@base_dir, "toolchains")
      @shim_path = File.join(@bin_dir, "pop")
      @language_server_shim_path = File.join(@bin_dir, "pop-language-server")
    end

    def versions : Array(String)
      if Dir.exists?(@toolchains_dir)
        Dir.children(@toolchains_dir)
          .select(&.starts_with?("v"))
          .sort!
      else
        [] of String
      end
    end

    def active_version : String
      File.basename(File.readlink(default_link))
    end

    def installed?(version : String) : Bool
      Dir.exists?(File.join(@toolchains_dir, version))
    end

    def uninstall(version : String) : Nil
      version_dir = File.join(@toolchains_dir, version)

      unless Dir.exists?(version_dir)
        raise "toolchain #{version} is not installed"
      end

      FileUtils.rm_rf(version_dir)
      Log.info { "removed toolchain directory #{version_dir}" }

      if File.symlink?(default_link) && active_version == version
        File.delete(default_link)
        File.delete(@shim_path) if File.exists?(@shim_path)
        File.delete(@language_server_shim_path) if File.exists?(@language_server_shim_path)
        Log.info { "removed active default, run `popup install` to set a new one" }
      end
    end

    def install(version : String, target : String) : Nil
      Dir.mkdir_p(@toolchains_dir)

      if File.symlink?(default_link)
        File.delete(default_link)
      end

      File.symlink(version, default_link)
      Log.info { "set default toolchain to #{version}" }

      Dir.mkdir_p(@bin_dir)

      write_shim(@shim_path, "pop-#{target}")
      write_shim(@language_server_shim_path, "pop-language-server-#{target}")
      Log.info { "wrote shim to #{@shim_path}" }
    end

    private def default_link : String
      File.join(@toolchains_dir, "default")
    end

    private def write_shim(path : String, executable : String) : Nil
      content = <<-SHIM
        #!/usr/bin/env bash
        set -euo pipefail
        exec #{shell_quote(File.join(@toolchains_dir, "default", executable))} "$@"
      SHIM
      File.write(path, content)
      File.chmod(path, 0o755)
    end

    private def shell_quote(value : String) : String
      "'#{value.gsub("'", %q('\\''))}'"
    end
  end
end
