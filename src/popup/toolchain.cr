class Popup::Toolchain
  DEFAULT_BASE_DIR = File.join(ENV["HOME"], ".popup")

  getter base_dir : String
  getter bin_dir : String
  getter toolchains_dir : String
  getter shim_path : String

  def initialize(@base_dir = ENV.fetch("POPUP_HOME", DEFAULT_BASE_DIR))
    @bin_dir = File.join(@base_dir, "bin")
    @toolchains_dir = File.join(@base_dir, "toolchains")
    @shim_path = File.join(@bin_dir, "pop")
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

  def install(version : String, target : String) : Nil
    Dir.mkdir_p(@toolchains_dir)

    if File.symlink?(default_link)
      File.delete(default_link)
    else
      File.symlink(version, default_link)
    end

    write_pop_shim(target)
  end

  private def write_pop_shim(target : String) : Nil
    Dir.mkdir_p(@bin_dir)

    content = <<-SHIM
    #!/usr/bin/env bash
    exec "$HOME/.popup/toolchains/default/pop-#{target}" "$@"
    SHIM

    File.write(@shim_path, content)
    File.chmod(@shim_path, 0o755)
  end

  private def default_link : String
    File.join(@toolchains_dir, "default")
  end
end
