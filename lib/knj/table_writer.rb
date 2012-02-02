class Knj::Table_writer
  def initialize(args = {})
    @args = args
    
    if !@args["filepath"]
      raise "No filepath was given."
    end
    
    if @args["format"] == "csv"
      @fp = File.open(@args["filepath"], "w")
    elsif @args["format"] == "excel5"
      require "spreadsheet"
      
      @wb = Spreadsheet::Workbook.new
      @ws = @wb.create_worksheet
      @row = 0
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def write_row(arr)
    if @args["format"] == "csv"
      arr.each_index do |key|
        val = arr[key]
        
        if val.is_a?(Hash) and val["type"] == "decimal"
          arr[key] = Knj::Php.number_format(val["value"], @args["amount_decimals"], @args["amount_dsep"], @args["amount_tsep"])
        elsif val.is_a?(Hash) and val["type"] == "date"
          arr[key] = Knj::Php.date(@args["date_format"], val["value"])
        end
      end
      
      line_str = Knj::Csv.arr_to_csv(arr, @args["expl"], @args["surr"])
      
      #line_str = line_str.encode("iso8859-1") if @args["encoding"] == "iso8859-1"
      
      @fp.write(line_str)
    elsif @args["format"] == "excel5"
      col_count = 0
      arr.each do |val|
        if val.is_a?(Hash) and val["type"] == "decimal"
          @ws[@row, col_count] = Knj::Php.number_format(val["value"], @args["amount_decimals"], @args["amount_dsep"], @args["amount_tsep"])
        elsif val.is_a?(Hash) and val["type"] == "date"
          @ws[@row, col_count] = Knj::Php.date(@args["date_format"], val["value"])
        else
          @ws[@row, col_count] = val
        end
        
        col_count += 1
      end
      
      @row += 1
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def close
    if @args["format"] == "csv"
      @fp.close
    elsif @args["format"] == "excel5"
      dirname = File.dirname(@args["filepath"])
      basename = File.basename(@args["filepath"], File.extname(@args["filepath"]))
      
      temp_path = "#{dirname}/#{basename}.xls"
      
      @wb.write(temp_path)
      @wb = nil
      @ws = nil
      
      FileUtils.mv(temp_path, @args["filepath"])
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def ext
    if @args["format"] == "csv"
      return "csv"
    elsif @args["format"] == "excel5"
      return "xls"
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def ftype
    if @args["format"] == "csv"
      return "text/csv"
    elsif @args["format"] == "excel5"
      return "application/ms-excel"
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
end