class Knj::Fs::Filesystem
  def self.args
    return [
      {
        "title" => "Path",
        "name" => "texpath"
      }
    ]
  end
  
  def initialize(args)
    @args = args
  end
end