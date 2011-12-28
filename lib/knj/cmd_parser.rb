class Knj::Cmd_parser
  def self.lsl(str, args = {})
    ret = []
    
    str.lines.each do |line|
      next if line.match(/^total ([\d\.,]+)(M|k|G|)$/)
      match = line.match(/^(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)\s+(\d+)\s+(.+)\s+([^\W].+?)\s+([\d\.,]+)(M|k|G|K|)\s+((\d+)-(\d+)-(\d+)|(([A-z]{3})\s+(\d+)))\s+(\d+):(\d+)\s+(.+)$/)
      raise "Could not match: '#{line}'." if !match
      
      if match[17] and match[18] and match[19]
        time = Time.local(match[17].to_i, match[18].to_i, match[19].to_i, match[23].to_i, match[24].to_i)
      elsif match[20] and match[21] and match[22]
        time = Time.local(Time.now.year, match[21], match[22].to_i, match[23].to_i, match[24].to_i)
      end
      
      bytes = match[14].gsub(",", ".").to_f
      
      size_match = match[15]
      if size_match == ""
        #bytes - dont touch
      elsif size_match.downcase == "k"
        bytes = bytes * 1024
      elsif size_match == "M"
        bytes = bytes * 1024 * 1024
      elsif size_match == "G"
        bytes = bytes * 1024 * 1024 * 1024
      else
        raise "Unknown size match: '#{size_match}'."
      end
      
      ret << {
        :mod => {
          :usr => {
            :read => match[2],
            :write => match[3],
            :exec => match[4]
          },
          :grp => {
            :read => match[5],
            :write => match[6],
            :exec => match[7]
          },
          :all => {
            :read => match[8],
            :write => match[9],
            :exec => match[10]
          }
        },
        :usr => match[12],
        :grp => match[13],
        :size => bytes.to_i,
        :time => time,
        :file => match[25]
      }
    end
    
    return ret
  end
end