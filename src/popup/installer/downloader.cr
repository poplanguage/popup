require "term-progress"
require "crest"

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
end
