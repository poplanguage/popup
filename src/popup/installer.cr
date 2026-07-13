require "json"
require "./github"
require "./utils/target"

class Popup::Installer
  def initialize(@version : String)
  end

  def install
    target = if Utils::Target.linux?
      if Utils::Target.aarch64?
        "aarch64-unknown-linux-gnu"
      elsif Utils::Target.x86_64?
        "x86_64-unknown-linux-gnu"
      end
    end

    unless target
      raise "This platform is not supported by Pop: #{`uname -m -o`}"
    end

    response = JSON.parse(
      GitHub.client.get("repos/poplanguage/pop/releases/tags/#{@version}").body
    )

    asset = response["assets"].as_a.find do |content|
      name = content["name"].as_s
      name.includes?(target) && !name.ends_with?(".sha256")
    end

    if asset
      url = asset["browser_download_url"].as_s
      puts "Downloading: #{url}"
      download(url)
    else
      STDERR.puts "No asset was found for this target: #{target}"
    end
  end

  private def download(url : String)
    filename = File.basename(url)

    Crest.get(url) do |response|
      File.open(filename, "wb") do |file|
        IO.copy(response.body_io, file)
      end
    end
  end
end
