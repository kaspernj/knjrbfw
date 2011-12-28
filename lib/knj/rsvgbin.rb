class Knj::RSVGBIN
  def self.test_version
    test_version = %x[rsvg-convert -v]
    if !test_version.match(/^rsvg-convert version [0-9\.]+$/)
      raise "No valid version of rsvg-bin was found."
    end
  end
  
  def self.png_content_from_file(file_from)
    RSVGBIN.test_version
    return %x[rsvg-convert #{Strings.unixsafe(file_from)}]
  end
  
  def self.convert_file(file_from, file_to)
    RSVGBIN.test_version
    
    png_content = RSVGBIN.png_content_from_file(file_from)
    Php.file_put_contents(file_to, png_content)
  end
end