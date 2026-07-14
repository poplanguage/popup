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
          .to_return(headers: {"Content-Length" => "16"})

        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: InstallUtils.release_with_binary.to_json)

        WebMock.stub(:get, InstallUtils::DOWNLOAD_URL)
          .to_return(body_io: IO::Memory.new("pop binary content"))

        result = Installer.new("v0.1.0").install

        File.exists?(result).should be_true
        File.read(result).should eq("pop binary content")
      end

      it "skips sha256 files when selecting the binary" do
        WebMock.stub(:head, InstallUtils::DOWNLOAD_URL)
          .to_return(headers: {"Content-Length" => "16"})

        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: InstallUtils.release_with_binary_and_sha.to_json)

        WebMock.stub(:get, InstallUtils::DOWNLOAD_URL)
          .to_return(body_io: IO::Memory.new("pop binary content"))

        result = Installer.new("v0.1.0").install

        File.exists?(result).should be_true
      end
    end

    context "when no matching asset exists" do
      it "raises an exception" do
        WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases/tags/v0.1.0")
          .to_return(body: InstallUtils.release_for_wrong_arch.to_json)

        expect_raises(Exception, "no asset found for target") do
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
