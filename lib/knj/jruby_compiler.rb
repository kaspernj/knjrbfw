class Knj::Jruby_compiler
  def initialize(args = {})
    @args = args
    
    factory = javax.script.ScriptEngineManager.new
    engine = factory.getEngineByName("jruby")
    code = File.read(args[:path])
    @script = engine.compile(code)
  end
  
  def run
    @script.eval
  end
end