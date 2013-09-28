#!/usr/local/var/rbenv/shims/ruby

require 'fallen'
require 'yaml'
require_relative 'lib/camopticon'

CONFIG = YAML.load_file('config.yml') unless defined? CONFIG

module Capture
  extend Fallen

  def self.run
    while running?
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

#Capture.pid_file "/var/run/camopticon_capture.pid"
#Capture.daemonize!
Capture.start!
