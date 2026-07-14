require "file_utils"

class Popup::Installer::Setup
  def initialize(@version : String, @archive_path : String, @toolchains_dir : String)
  end

  def run : Nil
    version_dir = File.join(@toolchains_dir, @version)
    tmp = File.tempname("popup")
    Dir.mkdir_p(tmp)

    result = Process.run("unzip", {"-q", "-o", @archive_path, "-d", tmp})
    unless result.success?
      File.delete(@archive_path)
      Dir.delete(tmp)
      raise "failed to extract #{File.basename(@archive_path)}"
    end

    if Dir.exists?(version_dir)
      FileUtils.rm_rf(version_dir)
    end

    File.rename(tmp, version_dir)
    File.delete(@archive_path)
  end
end
