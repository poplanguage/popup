require "./spec_helper"

describe GitHub do
  describe "#latest_release_tag" do
    before_each do
      WebMock.reset
    end

    it "returns the first release tag" do
      WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases")
        .to_return(body: [{"tag_name" => "v0.2.0"}].to_json)

      tag = GitHub.latest_release_tag

      tag.should eq("v0.2.0")
    end

    it "returns the first item from a list of releases" do
      releases = [
        {"tag_name" => "v0.2.0"},
        {"tag_name" => "v0.1.0"},
      ]

      WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases")
        .to_return(body: releases.to_json)

      tag = GitHub.latest_release_tag

      tag.should eq("v0.2.0")
    end

    it "raises on empty releases list" do
      WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases")
        .to_return(body: "[]")

      expect_raises(Exception) do
        GitHub.latest_release_tag
      end
    end

    it "raises on malformed JSON" do
      WebMock.stub(:get, "https://api.github.com/repos/poplanguage/pop/releases")
        .to_return(body: "not json")

      expect_raises(Exception) do
        GitHub.latest_release_tag
      end
    end
  end
end
