#This class is a Ruby-interface to the amixer-binary. It can read and set the volume.
class Knj::Amixer
  attr_reader :args
  
  def initialize(args = {})
    @args = {
      :amixer_bin => "/usr/bin/amixer",
      :aplay_bin => "/usr/bin/aplay"
    }.merge(args)
    
    @devices = {}
  end
  
  #Returns a hash with devices.
  def devices
    ret = %x[#{@args[:aplay_bin]} -l]
    
    ret.scan(/card (\d+): (.+?) \[(.+?)\],/) do |match|
      id = match[0]
      
      if !@devices.key?(id)
        @devices[id] = Knj::Amixer::Device.new(
          :amixer => self,
          :id => id,
          :name => match[2],
          :code => match[1]
        )
      end
    end
    
    return @devices
  end
  
  class Device
    def initialize(args)
      @args = args
      @mixers = {}
    end
    
    def id
      return @args[:id]
    end
    
    def name
      return @args[:name]
    end
    
    def code
      return @args[:code]
    end
    
    def amixer
      return @args[:amixer]
    end
    
    #Returns true if the device is active by looking in '/proc/asounc/card*/pcm*/sub*/status'.
    def active?(args = {})
      proc_path = "/proc/asound/#{@args[:code]}"
      
      Dir.foreach(proc_path) do |file|
        next if file == "." or file == ".." or !file.match(/^pcm(\d+)[a-z]+$/)
        sub_path = "#{proc_path}/#{file}"
        info_path = "#{sub_path}/info"
        info_cont = File.read(info_path)
        
        if stream_match = info_cont.match(/stream: (.+?)\s+/)
          next if args.key?(:stream) and stream_match[1] != args[:stream]
        end
        
        Dir.foreach(sub_path) do |file_sub|
          next if file_sub == "." or file_sub == ".." or !file_sub.match(/^sub(\d+)$/)
          status_path = "#{sub_path}/#{file_sub}/status"
          cont = File.read(status_path)
          return true if cont.strip != "closed"
        end
      end
      
      return false
    end
    
    #Returns a hash of the various mixers.
    def mixers
      ret = %x[#{@args[:amixer].args[:amixer_bin]} -c #{@args[:id]} scontrols]
      
      ret.scan(/Simple mixer control '(.+)',0/) do |match|
        name = match[0]
        
        if !@mixers.key?(name)
          @mixers[name] = Knj::Amixer::Mixer.new(
            :amixer => @args[:amixer],
            :device => self,
            :name => name
          )
        end
      end
      
      return @mixers
    end
  end
  
  #This class controls each mixer.
  class Mixer
    def initialize(args)
      @args = args
    end
    
    #Returns the name of the mixer (example: Master).
    def name
      return @args[:name]
    end
    
    #Returns a bool. If the mixer supports volume-operations (some mixers are just switches and doenst support volume).
    def volume?
      ret = %x[#{@args[:amixer].args[:amixer_bin]} -c #{@args[:device].id} sget "#{@args[:name]}"]
      raise "No content for mixer: '#{@args[:name]}'." if !ret
      
      match = ret.match(/(Capture|Playback) (\d+) \[(\d+%)\]/)
      return false if !match
      return true
    end
    
    #Returns the volume-value as an integer (or as the percent if {:percent => true} if given in arguments).
    def vol(args = {})
      ret = %x[#{@args[:amixer].args[:amixer_bin]} -c #{@args[:device].id} sget "#{@args[:name]}"]
      raise "No content for mixer: '#{@args[:name]}'." if !ret
      
      match = ret.match(/(Capture|Playback) (\d+) \[(\d+%)\]/)
      raise "Couldnt figure out volume for '#{@args[:name]}' from:\n'#{ret}'\n" if !match
      
      return match[3].to_i if args[:percent]
      return match[2].to_i
    end
    
    #Sets a new value for the volume.
    def vol=(newvol)
      ret = %x[#{@args[:amixer].args[:amixer_bin]} -c #{@args[:device].id} sset "#{@args[:name]}" "#{newvol}"]
      #NOTE: Do some error handeling here?
    end
    
    #Adds a number to the volume.
    def vol_add(add_vol)
      vol = self.vol
      newvol = vol + add_vol.to_i
      newvol = 0 if newvol < 0
      self.vol=(newvol)
    end
  end
end