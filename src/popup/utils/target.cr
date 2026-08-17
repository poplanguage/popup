module Popup::Utils::Target
  extend self

  struct Platform
    getter os : String
    getter arch : String
    getter triple : String

    def initialize(@os, @arch, @triple)
    end

    def label : String
      "#{@os}/#{@arch} (#{@triple})"
    end

    def executable_suffix : String
      @os == "windows" ? ".exe" : ""
    end
  end

  def current_arch : String
    {% if flag?(:win32) %}
      ENV.fetch("PROCESSOR_ARCHITECTURE", "unknown")
    {% else %}
      `uname -m`.strip
    {% end %}
  end

  def current_os : String
    {% if flag?(:win32) %}
      "windows"
    {% else %}
      case `uname -s`.strip.downcase
      when "linux"  then "linux"
      when "darwin" then "darwin"
      else               "unknown"
      end
    {% end %}
  end

  def aarch64? : Bool
    current_arch.downcase.in?({"aarch64", "arm64"})
  end

  def x86_64? : Bool
    current_arch.downcase.in?({"x86_64", "amd64"})
  end

  def linux? : Bool
    current_os == "linux"
  end

  def platform : Platform
    arch = case current_arch.downcase
           when "x86_64", "amd64"  then "x86_64"
           when "aarch64", "arm64" then "aarch64"
           else                         raise "unsupported architecture: #{current_arch}"
           end

    case current_os
    when "linux"   then Platform.new("linux", arch, "#{arch}-unknown-linux-gnu")
    when "darwin"  then Platform.new("darwin", arch, "#{arch}-apple-darwin")
    when "windows" then Platform.new("windows", arch, "#{arch}-pc-windows-msvc")
    else                raise "unsupported operating system"
    end
  end

  def windows? : Bool
    current_os == "windows"
  end

  def target_string : String
    platform.triple
  end
end
