class Knj::Gtk2::StatusWindow
  def initialize(opts = {})
    @opts = opts
    
    @window = Gtk::Window.new("Status")
    @window.modal = true
    @window.border_width = 8
    @window.set_frame_dimensions(3, 3, 3, 3)
    @window.signal_connect("destroy") do
      destroy
    end
    
    if opts["transient_for"]
      @window.transient_for = @opts["transient_for"]
    end
    
    @label = Gtk::Label.new("Loading...")
    @pbar = Gtk::ProgressBar.new
    
    @vbox = Gtk::VBox.new
    @vbox.spacing = 4
    @vbox.pack_start(@label, false, true)
    @vbox.pack_start(@pbar, false, true)
    
    @window.add(@vbox)
    
    @window.show_all
  end
  
  def label=(newlabel)
    if @label
      @label.label = newlabel
    end
  end
  
  def setStatus(perc, newlabel, temp = nil)
    if !perc
      perc = 0
    end
    
    self.percent = perc
    self.label = newlabel.to_s
  end
  
  def percent=(newperc)
    if @pbar
      @pbar.fraction = newperc
    end
  end
  
  def destroy
    if @window
      @window.destroy
    end
    
    @window = nil
    @vbox = nil
    @pbar = nil
    @label = nil
    @opts = nil
  end
  
  alias closeWindow destroy
end