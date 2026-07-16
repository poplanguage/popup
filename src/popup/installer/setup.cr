require "file_utils"
require "compress/zip"

class Popup::Installer::Setup
  def initialize(@version : String, @archive_path : String, @toolchains_dir : String, @target : String)
  end

  def run : Nil
    Dir.mkdir_p(@toolchains_dir)
    version_dir = File.join(@toolchains_dir, @version)
    temp_name = File.tempname("popup-install", nil, dir: @toolchains_dir)
    backup = File.tempname("popup-previous", nil, dir: @toolchains_dir)

    Log.info { "extracting toolchain..." }

    Dir.mkdir_p(temp_name)
    begin
      unzip_file(temp_name)
      validate_toolchain(temp_name)

      if Dir.exists?(version_dir)
        File.rename(version_dir, backup)
      end

      File.rename(temp_name, version_dir)
    rescue ex
      FileUtils.rm_rf(temp_name)
      File.rename(backup, version_dir) if Dir.exists?(backup)
      raise ex
    end
    FileUtils.rm_rf(backup)
    File.delete(@archive_path)

    Log.info { "extracted to #{version_dir}" }
  end

  private def unzip_file(temp_name : String) : Nil
    extracted = Set(String).new
    Compress::Zip::File.open(@archive_path) do |file|
      file.entries.each do |entry|
        next if entry.dir?

        relative = safe_entry(entry.filename)
        unless extracted.add?(relative)
          raise "duplicate archive entry: #{relative}"
        end

        entry.open do |io|
          out_path = File.join(temp_name, relative)

          FileUtils.mkdir_p(File.dirname(out_path))
          File.write(out_path, io.gets_to_end)
          mode = executable?(relative) ? 0o755 : 0o644
          File.chmod(out_path, mode)
        end
      end
    end
  rescue ex
    FileUtils.rm_rf(temp_name)
    raise ex if ex.message.try(&.starts_with?("unsafe archive entry"))
    raise "failed to extract #{File.basename(@archive_path)}: #{ex.message}"
  end

  private def executable?(relative : String) : Bool
    relative == "pop-#{@target}" || relative == "pop-language-server-#{@target}"
  end

  private def safe_entry(filename : String) : String
    parts = filename.split('/')
    if filename.empty? || filename.starts_with?('/') || filename.includes?('\\') ||
       parts.any? { |part| part.empty? || part == "." || part == ".." }
      raise "unsafe archive entry: #{filename}"
    end
    filename
  end

  private def validate_toolchain(directory : String) : Nil
    required = [
      "pop-#{@target}",
      "pop-language-server-#{@target}",
      "libpop_standard.a",
      "libpop_runtime_native.a",
    ]
    required.each do |name|
      path = File.join(directory, name)
      unless File.file?(path)
        raise "missing required toolchain file: #{name}"
      end
    end
  end
end
