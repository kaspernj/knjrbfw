class QtWindow
  def self.doCenter(tha_window)
    qdw = Qt::DesktopWidget.new
    
    move_left = (qdw.width / 2) - (tha_window.width / 2)
    move_top = (qdw.height / 2) - (tha_window.height / 2)
    
    tha_window.move(move_left, move_top)
  end
end