require "term-progress"
require "crest"

class Popup::Installer
  class Downloader
    CHUNK_SIZE = 8192

    def initialize(@url : String, @path : String)
    end

    def run : String
      Crest.get(@url) do |response|
        headers = response.headers["Content-Length"]?
        total = case headers
                when Array(String) then headers.first?.try &.to_i64 || 0_i64
                when String        then headers.to_i64
                else
                  0_i64
                end

        @bar = Term::Progress::Bar.new(
          total: total,
          format: "  Downloading [:bar] :percent :byte_rate",
          complete_char: '#',
          incomplete_char: ' '
        )

        File.open(@path, "wb") do |file|
          buffer = Bytes.new(CHUNK_SIZE)

          while (n = response.body_io.read(buffer)) && n > 0
            file.write(buffer[0, n])
            @bar.try &.advance(n.to_i64)
          end
        end
      end

      @bar.try &.finish("  Downloaded!")
      @path
    end
  end
end
