require "./spec_helper"

describe Index do
  before_each { WebMock.reset }
  after_each { WebMock.reset }

  it "resolves latest Pop through the index product route" do
    url = "https://pop.squareweb.app/v1/releases/latest/manifest?product=pop"
    WebMock.stub(:get, url).to_return(body: InstallUtils.manifest.to_json)

    manifest = Index.latest_manifest

    manifest.tag.should eq(InstallUtils::TAG)
    manifest.artifact_for(InstallUtils::TARGET).name.should eq(InstallUtils::ASSET_NAME)
  end

  it "accepts a release version with a v prefix" do
    WebMock.stub(:get, InstallUtils::MANIFEST_URL).to_return(body: InstallUtils.manifest.to_json)

    Index.manifest(InstallUtils::TAG).version.should eq(InstallUtils::VERSION)
  end

  it "resolves manifest-relative artifact URLs against the configured index" do
    Index.download_url("/v1/releases/1/artifacts/1/pop.zip")
      .should eq("https://pop.squareweb.app/v1/releases/1/artifacts/1/pop.zip")
  end
end
