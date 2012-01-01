class Knj::Cmd_gen
  def self.rsync(args)
    cmd = ""
    
    if args[:bin]
      cmd << args[:bin]
    else
      cmd << "rsync"
    end
    
    cmd << " -az"
    
    if args[:verbose]
      1.upto(args[:verbose]) do
        cmd << "v"
      end
    end
    
    if args[:ssh]
      cmd << " -e ssh"
      
      if args[:port]
        cmd << " --rsh='ssh -p #{args[:port]}'"
      end
    end
    
    if args[:delete]
      cmd << " --delete"
    end
    
    if args[:exclude]
      args[:exclude].each do |dir|
        cmd << " --exclude \"#{dir}\""
      end
    end
    
    cmd << " \"#{args[:user]}@#{args[:host]}:#{args[:dir_host]}\" \"#{args[:dir_local]}\""
    
    return cmd
  end
  
  def self.tar(args)
    cmd = ""
    
    if args[:bin]
      cmd << args[:bin]
    else
      cmd << "tar"
    end
    
    cmd << " "
    cmd << "z"if args[:gzip]
    cmd << "x" if args[:extract]
    cmd << "f" if args[:file]
    cmd << "c" if args[:create]
    
    if args[:verbose]
      1.upto(args[:verbose]) do
        cmd << "v"
      end
    end
    
    cmd << " \"#{args[:archive_path]}\""
    
    args[:paths].each do |path|
      cmd << " \"#{path}\""
    end
    
    return cmd
  end
end