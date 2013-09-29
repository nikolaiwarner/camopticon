#!/usr/local/var/rbenv/shims/ruby

require 'daemons'
require 'yaml'
require_relative 'lib/camopticon'

pwd = Dir.pwd
CONFIG = YAML.load_file('config.yml') unless defined? CONFIG

Daemons.run_proc('camopticon') do
  Dir.chdir pwd do
    loop do
      CONFIG['cameras'].each do |camera|
        camopticon = Camopticon.new
        camopticon.camera_id = camera['id']
        camopticon.camera_url = camera['url']
        camopticon.storage_path = CONFIG['storage_path']
        camopticon.capture_frame
      end
      sleep CONFIG['fps'] ||= 1
    end
  end
end
