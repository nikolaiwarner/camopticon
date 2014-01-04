# Camopticon! by Nikolai Warner in 2013

require 'date'
require 'faraday'
require 'fileutils'
require 'pushover'
require 'aws/s3'

class Camopticon
  attr_accessor :camera
  attr_accessor :date
  attr_accessor :storage_path
  attr_accessor :pushover
  attr_accessor :s3

  def initialize
    @camera = ''
    @date = Date.today.to_s
    @storage_path = ''
    @s3 = ''
  end

  def frames_path
    File.join storage_path, @camera['id'].to_s, 'frames', @date
  end

  def videos_path
    File.join storage_path, @camera['id'].to_s, 'videos'
  end

  def capture_frame
    unless @camera['url'].empty?
      filename = Time.now.to_i.to_s + '.jpg'
      response = Faraday.get(@camera['url'])
      if response && response.body
        # Local Storage
        if @camera['store_local']
          FileUtils.mkdir_p frames_path
          File.open(File.join(frames_path, filename), 'wb') do |file|
            file.write response.body
          end
        end

        # S3 Storage
        if @camera['store_s3']
          AWS::S3::Base.establish_connection!(
            access_key_id: @s3['access_key_id'],
            secret_access_key: @s3['secret_access_key']
          )
          s3_frames_path = File.join(@s3['storage_path'],
                                     @camera['id'].to_s,
                                     'frames',
                                     @date,
                                     filename)
          AWS::S3::S3Object.store(s3_frames_path, response.body, @s3['bucket'])
        end
      end
    end
  end

  def frames_to_video
    unless @storage_path.empty?
      send_message title: "Camera #{@camera['id']} - #{@date}",
                   message: "Start converting frames to video..."

      FileUtils.mkdir_p videos_path
      output_file = File.join(videos_path, @date + '.mp4')

      Dir.chdir frames_path do
        # Name frames to be sequential and
        # convert image due to invalid jpgs from camera
        # but, while we're here, let's timestamp the images!
        count = 0
        Dir['*.jpg'].sort_by{ |file| File.mtime(file) }.each do |file|
          date_string = DateTime.strptime(File.basename(file, '.*'), '%s').to_s
          new_name = File.join(File.dirname(file), "frame_#{'%05d' % count}.jpg")
          `convert -quiet #{file} -fill white -undercolor black -gravity SouthWest -annotate +1+5 "#{date_string}" #{new_name}`
          FileUtils.rm file
          count = count + 1
        end

        # make a video
        `ffmpeg -loglevel panic -y -f image2 -r 1 -i frame_%05d.jpg #{output_file}`

        send_message title: "Camera #{@camera['id']} - #{@date}",
                   message: "Finished converting frames to video."
      end
    end
  end

  def remove_frames_dir
    unless @storage_path.empty?
      FileUtils.rm_r frames_path
    end
  end

  def send_message options
    if @pushover
      Pushover.notification message: options[:message],
                            title: options[:title],
                            user: @pushover['user_token'],
                            token: @pushover['app_token']
    end
  end
end
