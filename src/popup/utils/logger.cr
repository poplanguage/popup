require "log"
require "colorize"

module Popup::Utils::Logger
  class Formatter < Log::Backend
    def initialize
      super(:direct)
    end

    def write(entry : Log::Entry) : Nil
      severity_label = entry.severity.label.colorize.bold

      case entry.severity
      when Log::Severity::Warn
        Colorize.with.yellow.surround(STDOUT) do
          puts "#{severity_label.to_s.downcase}: #{entry.message}"
        end
      when Log::Severity::Error, Log::Severity::Fatal
        Colorize.with.red.surround(STDOUT) do
          puts "#{severity_label.to_s.downcase}: #{entry.message}"
        end
      else
        puts "#{severity_label.to_s.downcase}: #{entry.message}"
      end
    end
  end
end
