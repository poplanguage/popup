require "json"

module Popup::GitHub
  def self.client : Crest::Resource
    Crest::Resource.new("https://api.github.com/",
      headers: {
        "Content-Type"         => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2026-03-10",
      }
    )
  end

  def self.lastest_release_tag : String
    request = Popup::GitHub.client.get("repos/poplanguage/pop/releases")
    body = JSON.parse(request.body).as_a

    body.first["tag_name"].as_s
  end
end
