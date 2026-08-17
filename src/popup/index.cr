require "json"
require "uri"

module Popup::Index
  DEFAULT_URL = "https://pop.squareweb.app"

  class Artifact
    include JSON::Serializable

    struct Target
      include JSON::Serializable

      getter os : String
      getter arch : String
    end

    getter id : Int64
    getter name : String
    getter size : Int64
    getter sha256 : String
    getter url : String
    getter archive_format : String?

    @[JSON::Field(key: "available")]
    getter? available : Bool

    getter target : Target

    def zip?
      @archive_format == "zip"
    end
  end

  class Manifest
    include JSON::Serializable

    getter product : String
    getter version : String
    getter tag : String
    getter channel : String
    getter artifacts : Array(Artifact)

    def artifact_for(target : Utils::Target::Platform) : Artifact
      @artifacts.find do |artifact|
        artifact.available? &&
          artifact.target.os == target.os &&
          artifact.target.arch == target.arch &&
          artifact.zip?
      end || raise "no available #{@product} archive for #{target.label} in release #{@version}"
    end
  end

  def self.base_url : String
    ENV.fetch("POP_INDEX_URL", DEFAULT_URL).rstrip('/')
  end

  def self.latest_manifest(product = "pop") : Manifest
    get_manifest("/v1/releases/latest/manifest?product=#{product}")
  end

  def self.manifest(version : String, product = "pop") : Manifest
    clean_version = version.lstrip('v')
    get_manifest("/v1/releases/#{clean_version}/manifest?product=#{product}")
  end

  def self.channel_manifest(channel : String, product = "pop") : Manifest
    get_manifest("/v1/releases/channels/#{channel}/manifest?product=#{product}")
  end

  def self.download_url(relative_url : String) : String
    if (url = URI.parse(relative_url)) && url.scheme == "https" || url.scheme == "http"
      relative_url
    else
      "#{base_url}#{relative_url.starts_with?('/') ? relative_url : "/#{relative_url}"}"
    end
  end

  private def self.get_manifest(path : String) : Manifest
    if (response = client.get(path)) && response.success?
      Manifest.from_json(response.body)
    else
      raise "Pop Index request failed (HTTP #{response.status_code}) for #{path}"
    end
  rescue ex : Crest::RequestFailed
    raise "Pop Index request failed (HTTP #{ex.http_code}) for #{path}"
  rescue ex : JSON::ParseException
    raise "Pop Index returned invalid JSON for #{path}: #{ex.message}"
  end

  private def self.client : Crest::Resource
    Crest::Resource.new("#{base_url}/", headers: {"Accept" => "application/json"})
  end
end
