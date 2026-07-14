require "json"
require "term-progress"

require "./github"
require "./utils/target"

class Popup::Installer
  class Downloader
    CHUNK_SIZE = 8192

    def initialize(@url : String, @path : String)
    end

    def run : String
      bar = Term::Progress::Bar.new(
        total: file_size,
        format: "  Downloading [:bar] :percent :byte_rate ETA: :eta",
        complete_char: '#',
        incomplete_char: ' '
      )

      Crest.get(@url) do |response|
        File.open(@path, "wb") do |file|
          buffer = Bytes.new(CHUNK_SIZE)

          while (n = response.body_io.read(buffer)) && n > 0
            file.write(buffer[0, n])
            bar.advance(n.to_i64)
          end
        end
      end

      bar.finish("  Downloaded!")
      @path
    end

    private def file_size : Int64
      response = Crest.head(@url)
      content_length = response.headers["Content-Length"]?

      if content_length.is_a?(String)
        content_length.to_i64
      else
        0_i64
      end
    end
  end

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
