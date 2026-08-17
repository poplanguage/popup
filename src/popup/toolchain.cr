require "file_utils"

module Popup
  class Toolchain
    getter base_dir : String
    getter bin_dir : String
    getter toolchains_dir : String
    getter shim_path : String
    getter language_server_shim_path : String

    def self.default_base_dir : String
      if configured = ENV["POPUP_HOME"]?
        return configured
      end

      home = ENV["HOME"]? || ENV["USERPROFILE"]? || "."
      File.join(home, ".popup")
    end

    def initialize(@base_dir = self.class.default_base_dir)
      @bin_dir = File.join(@base_dir, "bin")
      @toolchains_dir = File.join(@base_dir, "toolchains")
      suffix = Utils::Target.windows? ? ".bat" : ""
      @shim_path = File.join(@bin_dir, "pop#{suffix}")
      @language_server_shim_path = File.join(@bin_dir, "pop-language-server#{suffix}")
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

    def active_version : String?
      if Utils::Target.windows?
        File.read(default_version_file).strip if File.file?(default_version_file)
      elsif File.symlink?(default_link)
        File.basename(File.readlink(default_link))
      end
    end

    def installed?(version : String) : Bool
      Dir.exists?(File.join(@toolchains_dir, version))
    end

    def install(version : String, target : Utils::Target::Platform) : Nil
      Dir.mkdir_p(@toolchains_dir)

      if Utils::Target.windows?
        File.write(default_version_file, version)
      else
        File.delete(default_link) if File.symlink?(default_link) || File.exists?(default_link)
        File.symlink(version, default_link)
      end
      Log.info { "set default toolchain to #{version}" }

      Dir.mkdir_p(@bin_dir)

      write_shim(@shim_path, "pop-#{target.triple}#{target.executable_suffix}")
      write_shim(@language_server_shim_path, "pop-language-server-#{target.triple}#{target.executable_suffix}")
      Log.info { "wrote shim to #{@shim_path}" }
    end

    # Kept for callers compiled against popup before target metadata became a
    # first-class platform value. New code should pass Target.platform.
    def install(version : String, target : String) : Nil
      install(version, Utils::Target.platform)
    end

    def default=(version : String) : Nil
      raise "toolchain #{version} is not installed" unless installed?(version)

      if Utils::Target.windows?
        File.write(default_version_file, version)
      else
        File.delete(default_link) if File.symlink?(default_link) || File.exists?(default_link)
        File.symlink(version, default_link)
      end
      Log.info { "set default toolchain to #{version}" }
    end

    def uninstall(version : String) : Nil
      raise "toolchain #{version} is not installed" unless installed?(version)
      if active_version == version
        raise "cannot uninstall the active toolchain #{version}; select another default first"
      end
      FileUtils.rm_rf(File.join(@toolchains_dir, version))
      Log.info { "uninstalled toolchain #{version}" }
    end

    private def default_link : String
      File.join(@toolchains_dir, "default")
    end

    private def default_version_file : String
      File.join(@toolchains_dir, "default.txt")
    end

    private def write_shim(path : String, executable : String) : Nil
      if Utils::Target.windows?
        content = <<-SHIM
          @echo off
          setlocal
          set /p POPUP_DEFAULT=<"#{File.join(@toolchains_dir, "default.txt")}"
          "#{File.join(@toolchains_dir, "%POPUP_DEFAULT%", executable)}" %*
        SHIM
        File.write(path, content)
      else
        content = <<-SHIM
          #!/usr/bin/env bash
          set -euo pipefail
          exec #{shell_quote(File.join(@toolchains_dir, "default", executable))} "$@"
        SHIM
        File.write(path, content)
        File.chmod(path, 0o755)
      end
    end

    private def shell_quote(value : String) : String
      "'#{value.gsub("'", %q('\\''))}'"
    end
  end
end
