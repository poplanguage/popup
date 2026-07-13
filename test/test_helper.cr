require "minitest/autorun"
require "webmock"
require "json"
require "crest"
require "file_utils"

require "../src/popup/version"
require "../src/popup/github"
require "../src/popup/utils/target"
require "../src/popup/installer"

include Popup
