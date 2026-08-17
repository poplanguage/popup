require "json"
require "digest/sha256"
require "file_utils"

module Popup
  class Installer
    getter version : String
    getter target : Utils::Target::Platform

    def initialize(version : String? = nil, @target = Utils::Target.platform)
      @requested_version = version
      @version = ""
    end

    def install : String
      manifest = resolve_manifest
      @version = manifest.tag
      asset = manifest.artifact_for(@target)

      Log.info { "fetching Pop #{@version} for #{@target.label}..." }
      tmp_dir = File.tempname("popup")
      Dir.mkdir_p(tmp_dir)
      archive = File.join(tmp_dir, asset.name)
      Downloader.new(Index.download_url(asset.url), archive).run
      verify_checksum(archive, asset.sha256)
      archive
    rescue ex
      FileUtils.rm_rf(tmp_dir) if tmp_dir
      raise ex
    end

    private def resolve_manifest : Index::Manifest
      requested = @requested_version
      if requested.nil? || requested.empty? || requested == "latest"
        Index.latest_manifest
      elsif requested.starts_with?("channel:")
        Index.channel_manifest(requested[8..])
      else
        Index.manifest(requested)
      end
    end

    private def verify_checksum(archive : String, expected_checksum : String) : Nil
      unless expected_checksum.matches?(/\A[0-9a-fA-F]{64}\z/)
        raise "invalid SHA-256 supplied by the Pop Index"
      end

      expected = expected_checksum.downcase
      actual = Digest::SHA256.new.file(archive).hexfinal
      unless actual == expected
        raise "checksum mismatch for #{File.basename(archive)}"
      end
    end
  end
end
