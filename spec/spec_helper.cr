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

  VERSION         = "0.1.0"
  TAG             = "v#{VERSION}"
  TARGET          = Utils::Target.platform
  ASSET_NAME      = "pop-#{TARGET.triple}.zip"
  DOWNLOAD_URL    = "https://pop.squareweb.app/v1/releases/#{VERSION}/artifacts/42/#{ASSET_NAME}"
  MANIFEST_URL    = "https://pop.squareweb.app/v1/releases/#{VERSION}/manifest?product=pop"
  ARCHIVE_CONTENT = "verified pop archive"
  ARCHIVE_SHA256  = Digest::SHA256.hexdigest(ARCHIVE_CONTENT)

  def manifest(artifacts = [artifact])
    {
      "schema_version" => "1",
      "product"        => "pop",
      "version"        => VERSION,
      "tag"            => TAG,
      "channel"        => "stable",
      "artifacts"      => artifacts,
    }
  end

  def artifact(sha256 = ARCHIVE_SHA256, available = true)
    {
      "id"             => 42_i64,
      "name"           => ASSET_NAME,
      "target"         => {"os" => TARGET.os, "arch" => TARGET.arch},
      "archive_format" => "zip",
      "size"           => ARCHIVE_CONTENT.bytesize,
      "sha256"         => sha256,
      "url"            => "/v1/releases/#{VERSION}/artifacts/42/#{ASSET_NAME}",
      "available"      => available,
    }
  end

  def other_target_artifact
    {
      "id"             => 43_i64,
      "name"           => "pop-other.zip",
      "target"         => {"os" => TARGET.os, "arch" => "other"},
      "archive_format" => "zip",
      "size"           => 1,
      "sha256"         => ARCHIVE_SHA256,
      "url"            => "/v1/releases/#{VERSION}/artifacts/43/pop-other.zip",
      "available"      => true,
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
