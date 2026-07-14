require "json"

require "./github"
require "./utils/target"

module Popup
  class Installer
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

      unless asset
        raise "no asset found for target '#{target}' in release #{@version}"
      end

      url = asset["browser_download_url"].as_s
      tmp_dir = File.tempname("popup")
      Dir.mkdir_p(tmp_dir)
      archive = File.join(tmp_dir, File.basename(url))
      Downloader.new(url, archive).run
      archive
    end
  end
end
