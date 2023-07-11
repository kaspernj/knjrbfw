class Knj::Filesystem
  def self.copy(args)
    FileUtils.rm(args[:to]) if args[:replace] and File.exist?(args[:to])
    FileUtils.cp(args[:from], args[:to])
    mod = File.lstat(args[:from]).mode & 0777
    File.chmod(mod, args[:to])
  end
end