require "json"
require "crest"

# Client for the public Pop Index.  The index is the release authority for
# popup: it preserves release metadata and checksums even when upstream GitHub
# releases change or disappear.
module Popup::Index
  DEFAULT_URL = "https://pop.squareweb.app"

  class Artifact
    getter id : Int64
    getter name : String
    getter os : String
    getter arch : String
    getter archive_format : String?
    getter size : Int64
    getter sha256 : String
    getter url : String
    getter? available : Bool

    def initialize(@id, @name, @os, @arch, @archive_format, @size, @sha256, @url, @available)
    end

    def zip? : Bool
      @archive_format == "zip"
    end
  end

  class Manifest
    getter product : String
    getter version : String
    getter tag : String
    getter channel : String
    getter artifacts : Array(Artifact)

    def initialize(@product, @version, @tag, @channel, @artifacts)
    end

    def artifact_for(target : Utils::Target::Platform) : Artifact
      @artifacts.find do |artifact|
        artifact.available? && artifact.os == target.os && artifact.arch == target.arch && artifact.zip?
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
    return relative_url if relative_url.starts_with?("https://") || relative_url.starts_with?("http://")
    "#{base_url}#{relative_url.starts_with?('/') ? relative_url : "/#{relative_url}"}"
  end

  private def self.get_manifest(path : String) : Manifest
    response = client.get(path)
    raise "Pop Index request failed (HTTP #{response.status_code}) for #{path}" unless response.success?
    parse_manifest(JSON.parse(response.body))
  rescue ex : Crest::RequestFailed
    raise "Pop Index request failed (HTTP #{ex.http_code}) for #{path}"
  rescue ex : JSON::ParseException
    raise "Pop Index returned invalid JSON for #{path}: #{ex.message}"
  end

  private def self.client : Crest::Resource
    Crest::Resource.new("#{base_url}/", headers: {"Accept" => "application/json"})
  end

  private def self.parse_manifest(data : JSON::Any) : Manifest
    artifacts = data["artifacts"].as_a.map do |item|
      target = item["target"]
      Artifact.new(
        item["id"].as_i64,
        item["name"].as_s,
        target["os"].as_s,
        target["arch"].as_s,
        item["archive_format"]?.try(&.as_s?),
        item["size"].as_i64,
        item["sha256"].as_s,
        item["url"].as_s,
        item["available"].as_bool
      )
    end

    Manifest.new(
      data["product"].as_s,
      data["version"].as_s,
      data["tag"].as_s,
      data["channel"].as_s,
      artifacts
    )
  end
end
