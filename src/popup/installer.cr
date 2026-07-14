require "json"
require "./github"
require "./utils/target"

class Popup::Installer
  def initialize(@version : String)
  end

  def install : String
    target = Utils::Target.target_string

    response = JSON.parse(
      GitHub.client.get("repos/poplanguage/pop/releases/tags/#{@version}").body
    )

    asset = response["assets"].as_a.find do |content|
      name = content["name"].as_s
      name.includes?(target) && !name.ends_with?(".sha256")
    end

    if asset
      url = asset["browser_download_url"].as_s
      temp_dir = File.tempname("popup")
      Dir.mkdir_p(temp_dir)

      archive = File.join(temp_dir, File.basename(url))
      download(url, archive)
      archive
    else
      raise "no asset found for target '#{target}' in release #{@version}"
    end
  end

  private def download(url : String, path : String)
    Crest.get(url) do |response|
      File.open(path, "wb") do |file|
        IO.copy(response.body_io, file)
      end
    end
  end
end
