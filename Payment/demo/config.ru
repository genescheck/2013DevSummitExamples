require 'rubygems'
require 'bundler'

$stdout.sync = true
$stderr.sync = true

Bundler.require

require './demo'
run Sinatra::Application
