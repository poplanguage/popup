require "json"
require "digest/sha256"
require "file_utils"

module Popup
  class Installer
    def initialize(@version : String)
    end

    def install : String
      target = Utils::Target.target_string
      archive_name = "pop-#{target}.zip"
      checksum_name = "#{archive_name}.sha256"

      Log.info { "fetching release #{@version}..." }
      response = JSON.parse(
        GitHub.client.get("repos/poplanguage/pop/releases/tags/#{@version}").body
      )

      assets = response["assets"].as_a
      asset = exact_asset(assets, archive_name, "toolchain")
      checksum = exact_asset(assets, checksum_name, "checksum")
      tmp_dir = File.tempname("popup")
      Dir.mkdir_p(tmp_dir)
      archive = File.join(tmp_dir, archive_name)
      checksum_path = File.join(tmp_dir, checksum_name)
      Downloader.new(asset["browser_download_url"].as_s, archive).run
      Downloader.new(checksum["browser_download_url"].as_s, checksum_path).run
      verify_checksum(archive, checksum_path, archive_name)
      File.delete(checksum_path)
      archive
    rescue ex
      FileUtils.rm_rf(tmp_dir) if tmp_dir
      raise ex
    end

    private def exact_asset(assets, name : String, kind : String)
      assets.find { |content| content["name"].as_s == name } ||
        raise "no exact #{kind} asset '#{name}' found in release #{@version}"
    end

    private def verify_checksum(archive : String, checksum_path : String, archive_name : String) : Nil
      fields = File.read(checksum_path).strip.split
      unless fields.size == 2 && fields[0].matches?(/\A[0-9a-fA-F]{64}\z/) &&
             fields[1].lstrip('*') == archive_name
        raise "invalid checksum file for #{archive_name}"
      end

      expected = fields[0].downcase
      actual = Digest::SHA256.new.file(archive).hexfinal
      unless actual == expected
        raise "checksum mismatch for #{archive_name}"
      end
    end
  end
end
