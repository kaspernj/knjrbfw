class Knj::Table_writer
  def initialize(args = {})
    @args = args
    raise "No filepath was given." if @args["filepath"].to_s.empty?
    
    if @args["format"] == "csv"
      if @args["encoding"]
        encoding = @args["encoding"]
      else
        encoding = "utf-8"
      end
      
      @fp = File.open(@args["filepath"], "w", :encoding => encoding)
    elsif @args["format"] == "excel5"
      require "spreadsheet"
      
      @wb = Spreadsheet::Workbook.new
      @ws = @wb.create_worksheet
      @row = 0
    elsif @args["format"] == "excel2007"
      require "php_process"
      
      @php = Php_process.new
      @php.func("require_once", "PHPExcel.php")
      
      if @args["date_format"]
        @date_format_excel = args["date_format"].gsub("d", "dd").gsub("m", "mm").gsub("y", "yy").gsub("Y", "yyyy").gsub("-", '\\-')
      end
      
      #Array used for identifiyng Excel-columns.
      @colarr = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
      
      #This greatly speeds up the process, since it minimizes the call to PHP by ~25%.
      @date_cache = {}
      
      #Set cache-mode to cache-in-memory-gzip.
      cache_gzip_const = @php.constant_val("PHPExcel_CachedObjectStorageFactory::cache_to_discISAM")
      cosf = @php.static("PHPExcel_CachedObjectStorageFactory", "initialize", cache_gzip_const)
      @php.static("PHPExcel_Settings", "setCacheStorageMethod", cosf)
      
      #Create PHPExcel-objects.
      @pe = @php.new("PHPExcel")
      @pe.getProperties.setCreator(args["creator"]) if args["creator"]
      @pe.getProperties.setLastModifiedBy(args["last_modified_by"]) if args["last_modified_by"]
      @pe.getProperties.setTitle(args["title"]) if args["title"]
      @pe.getProperties.setSubject(args["subject"]) if args["subject"]
      @pe.getProperties.setDescription(args["descr"]) if args["descr"]
      @pe.setActiveSheetIndex(0)
      @sheet = @pe.getActiveSheet
      @linec = 1
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
    elsif @args["format"] == "excel2007"
      col_count = 0
      arr.each do |val|
        colval = "#{@colarr[col_count]}#{@linec}"
        
        if val.is_a?(Hash) and val["type"] == "decimal"
          @sheet.setCellValue(colval, val["value"])
          @sheet.getStyle(colval).getNumberFormat.setFormatCode("#,##0.00")
        elsif val.is_a?(Hash) and val["type"] == "date"
          datet = Datet.in(val["value"])
          datet.days + 1
          
          date_val = @php.static("PHPExcel_Shared_Date", "PHPToExcel", datet.to_i)
          @sheet.setCellValue(colval, date_val)
          @sheet.getStyle(colval).getNumberFormat.setFormatCode(@date_format_excel)
        else
          @sheet.setCellValue(colval, val)
        end
        
        col_count += 1
      end
      
      @linec += 1
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
    
    return nil
  end
  
  def destroy
    @sheet = nil
    @php.destroy if @php
    @php = nil
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
    elsif @args["format"] == "excel2007"
      writer = @php.new("PHPExcel_Writer_Excel2007", @pe)
      writer.save(@args["filepath"])
      self.destroy
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
    
    return nil
  end
  
  def ext
    if @args["format"] == "csv"
      return "csv"
    elsif @args["format"] == "excel5"
      return "xls"
    elsif @args["format"] == "excel2007"
      return "xlsx"
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
  
  def ftype
    if @args["format"] == "csv"
      return "text/csv"
    elsif @args["format"] == "excel5" or @args["format"] == "excel2007"
      return "application/ms-excel"
    else
      raise "Unsupported format: '#{@args["format"]}'."
    end
  end
end