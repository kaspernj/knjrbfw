class Knj::Cmd_parser
  def self.lsl(str)
    ret = []
    
    str.lines.each do |line|
      next if line.match(/^total (\d+)$/)
      match = line.match(/^(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)\s+(\d+)\s+(.+)\s+([^\W].+?)\s+(\d+)\s+((\d+)-(\d+)-(\d+)|(([A-z]{3})\s+(\d+)))\s+(\d+):(\d+)\s+(.+)$/)
      raise "Could not match: '#{line}'." if !match
      
      if match[16] and match[17] and match[18]
        time = Time.local(match[16].to_i, match[17].to_i, match[18].to_i, match[22].to_i, match[23].to_i)
      elsif match[20] and match[21]
        time = Time.local(Time.now.year, match[20], match[21], match[22], match[23])
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
        :size => match[14].to_i,
        :time => time,
        :file => match[24]
      }
    end
    
    return ret
  end
end