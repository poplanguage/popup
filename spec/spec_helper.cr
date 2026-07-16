require "spec"
require "webmock"
require "json"
require "crest"
require "file_utils"
require "compress/zip"
require "digest/sha256"

require "../src/popup/**"

include Popup

module InstallUtils
  extend self

  ASSET_NAME      = "pop-#{Utils::Target.target_string}.zip"
  DOWNLOAD_URL    = "https://github.com/poplanguage/pop/releases/download/v0.1.0/#{ASSET_NAME}"
  CHECKSUM_URL    = DOWNLOAD_URL + ".sha256"
  ARCHIVE_CONTENT = "verified pop archive"
  ARCHIVE_SHA256  = Digest::SHA256.hexdigest(ARCHIVE_CONTENT)

  def release_with_binary
    {
      "tag_name" => "v0.1.0",
      "assets"   => [
        {
          "name"                 => ASSET_NAME,
          "browser_download_url" => DOWNLOAD_URL,
        },
        {
          "name"                 => ASSET_NAME + ".sha256",
          "browser_download_url" => CHECKSUM_URL,
        },
      ],
    }
  end

  def release_with_binary_and_sha
    {
      "tag_name" => "v0.1.0",
      "assets"   => [
        {
          "name"                 => ASSET_NAME,
          "browser_download_url" => DOWNLOAD_URL,
        },
        {
          "name"                 => ASSET_NAME + ".sha256",
          "browser_download_url" => CHECKSUM_URL,
        },
      ],
    }
  end

  def release_for_wrong_arch
    {
      "tag_name" => "v0.1.0",
      "assets"   => [
        {
          "name"                 => "pop-aarch64-unknown-linux-gnu.tar.gz",
          "browser_download_url" => "https://github.com/nothing",
        },
      ],
    }
  end

  def write_toolchain_archive(path : String, entries : Hash(String, String))
    Compress::Zip::Writer.open(path) do |zip|
      entries.each do |name, contents|
        zip.add(name, contents)
      end
    end
  end
end
