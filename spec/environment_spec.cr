require "./spec_helper"

describe Environment do
  it "prints fish activation without POSIX syntax" do
    output = Environment.render("fish", Toolchain.new("/tmp/popup-home"))
    output.should contain("set -gx POPUP_HOME")
    output.should contain("fish_add_path")
  end

  it "prints PowerShell activation with a semicolon PATH" do
    output = Environment.render("powershell", Toolchain.new("C:\\popup"))
    output.should contain("$env:POPUP_HOME")
    output.should contain("$env:Path")
  end

  it "rejects unknown shells" do
    expect_raises(Exception, "unsupported shell") { Environment.render("elvish") }
  end
end
