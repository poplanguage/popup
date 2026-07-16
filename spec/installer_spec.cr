require "./spec_helper"

describe Installer do
  describe "#install" do
    before_each do
      WebMock.reset
    end

    after_each do
      WebMock.reset
    end

    context "when a matching asset exists" do
      it "downloads the correct binary for the current platform" do
        WebMock.stub(:head, InstallUtils::DOWNLOAD_URL)
          .to_return(headers: {"Content-Length" => InstallUtils::ARCHIVE_CONTENT.bytesize.to_s})
        WebMock.stub(:head, InstallUtils::CHECKSUM_URL)
          .to_return(headers: {"Content-Length" => "96"})

        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: InstallUtils.release_with_binary.to_json)

        WebMock.stub(:get, InstallUtils::DOWNLOAD_URL)
          .to_return(body_io: IO::Memory.new(InstallUtils::ARCHIVE_CONTENT))
        WebMock.stub(:get, InstallUtils::CHECKSUM_URL)
          .to_return(body_io: IO::Memory.new("#{InstallUtils::ARCHIVE_SHA256}  #{InstallUtils::ASSET_NAME}\n"))

        result = Installer.new("v0.1.0").install

        File.exists?(result).should be_true
        File.read(result).should eq(InstallUtils::ARCHIVE_CONTENT)
      end

      it "requires and verifies the exact matching sha256 asset" do
        WebMock.stub(:head, InstallUtils::DOWNLOAD_URL)
          .to_return(headers: {"Content-Length" => InstallUtils::ARCHIVE_CONTENT.bytesize.to_s})
        WebMock.stub(:head, InstallUtils::CHECKSUM_URL)
          .to_return(headers: {"Content-Length" => "96"})

        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: InstallUtils.release_with_binary_and_sha.to_json)

        WebMock.stub(:get, InstallUtils::DOWNLOAD_URL)
          .to_return(body_io: IO::Memory.new(InstallUtils::ARCHIVE_CONTENT))
        WebMock.stub(:get, InstallUtils::CHECKSUM_URL)
          .to_return(body_io: IO::Memory.new("#{InstallUtils::ARCHIVE_SHA256}  #{InstallUtils::ASSET_NAME}\n"))

        result = Installer.new("v0.1.0").install

        File.exists?(result).should be_true
      end

      it "rejects an archive whose digest does not match" do
        WebMock.stub(:head, InstallUtils::DOWNLOAD_URL)
          .to_return(headers: {"Content-Length" => InstallUtils::ARCHIVE_CONTENT.bytesize.to_s})
        WebMock.stub(:head, InstallUtils::CHECKSUM_URL)
          .to_return(headers: {"Content-Length" => "96"})
        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: InstallUtils.release_with_binary.to_json)
        WebMock.stub(:get, InstallUtils::DOWNLOAD_URL)
          .to_return(body_io: IO::Memory.new(InstallUtils::ARCHIVE_CONTENT))
        WebMock.stub(:get, InstallUtils::CHECKSUM_URL)
          .to_return(body_io: IO::Memory.new("#{"0" * 64}  #{InstallUtils::ASSET_NAME}\n"))

        expect_raises(Exception, "checksum mismatch") do
          Installer.new("v0.1.0").install
        end
      end
    end

    context "when no matching asset exists" do
      it "raises an exception" do
        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: InstallUtils.release_for_wrong_arch.to_json)

        expect_raises(Exception, "no exact toolchain asset") do
          Installer.new("v0.1.0").install
        end
      end

      it "rejects a release without an exact checksum asset" do
        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: InstallUtils.release_with_binary_and_sha.tap { |release| release["assets"].as(Array).pop }.to_json)

        expect_raises(Exception, "checksum asset") do
          Installer.new("v0.1.0").install
        end
      end
    end

    context "when the GitHub API returns an error" do
      it "raises on 404" do
        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: "not found", status: 404)

        expect_raises(Exception) do
          Installer.new("v0.1.0").install
        end
      end
    end
  end
end
