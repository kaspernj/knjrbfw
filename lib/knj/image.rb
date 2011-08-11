class Knj::Image
  def self.rounded_corners(args)
    raise "No or invalid ':img' given." if !args[:img]
    raise "No or invalid ':radius' given." if args[:radius].to_i <= 0
    
    pic = args[:img]
    
    r = args[:radius].to_i
    r2 = r * r
    d = r * 2
    
    center_x = r
    center_y = 0
    
    coords = {}
    0.upto(d) do |x|
      y = center_y + Math.sqrt(r2 - ((x - center_x) * (x - center_x)))
      coords[x] = y.to_i
    end
    
    1.upto(4) do |count|
      r.times do |x|
        case count
          when 1
            x_from = x
            
            y_from = 0
            y_to = r - coords[x].to_i
          when 2
            x_from = pic.columns - r + x
            
            y_from = 0
            y_to = r - coords[x + r].to_i
          when 3
            x_from = x
            
            y_from = pic.rows - r + coords[x].to_i
            y_to = pic.rows - y_from
          when 4
            x_from = pic.columns - r + x
            
            y_from = pic.rows - r + coords[r - x].to_i
            y_to = pic.rows - y_from
        end
        
        next if y_to <= 0
        
        pixels = pic.get_pixels(x_from, y_from, 1, y_to)
        pixels.each do |pixel|
          pixel.opacity = Magick::TransparentOpacity
        end
        
        pic.store_pixels(x_from, y_from, 1, y_to, pixels)
      end
    end
    
    pic.matte = true
  end
end