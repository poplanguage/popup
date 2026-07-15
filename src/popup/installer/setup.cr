require "file_utils"
require "compress/zip"

class Popup::Installer::Setup
  def initialize(@version : String, @archive_path : String, @toolchains_dir : String)
  end

  def run
    version_dir = File.join(@toolchains_dir, @version)
    temp_name = File.tempname("popup")

    Dir.mkdir_p(temp_name)
    unzip_file(temp_name)

    if Dir.exists?(version_dir)
      FileUtils.rm_rf(version_dir)
    end

    File.rename(temp_name, version_dir)
    File.delete(@archive_path)
  end

  private def unzip_file(temp_name : String)
    Compress::Zip::File.open(@archive_path) do |file|
      file.entries.each do |entry|
        next if entry.dir?

        entry.open do |io|
          out_path = File.join(temp_name, entry.filename)

          FileUtils.mkdir_p(File.dirname(out_path))
          File.write(out_path, io.gets_to_end)
          File.chmod(out_path, 0o755)
        end
      end
    end
  rescue ex : Compress::Zip::Error
    FileUtils.rm_rf(temp_name)
    raise "failed to extract #{File.basename(@archive_path)}: #{ex.message}"
  end
end
