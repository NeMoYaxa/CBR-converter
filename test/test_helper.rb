# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "cbr_converter"
require "bin/console"

require "minitest/autorun"
require "webmock/minitest"
require "minitest/mock"
require "bigdecimal"
require "stringio"