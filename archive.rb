#!/usr/local/var/rbenv/shims/ruby

require 'date'
require 'yaml'
require_relative 'lib/camopticon'

CONFIG = YAML.load_file('config.yml')

CONFIG['cameras'].each do |camera|
  camopticon = Camopticon.new
  camopticon.date = (Date.today - 1).to_s
  camopticon.storage_path = CONFIG['storage_path']
  camopticon.camera_id = camera['id']
  camopticon.frames_to_video
  camopticon.remove_frames_dir
end
