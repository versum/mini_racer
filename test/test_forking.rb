$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mini_racer'

MiniRacer::Platform.set_flags! :single_threaded

@ctx = MiniRacer::Context.new
@ctx.eval("var a = 1+1")

def trigger_gc
  puts "a"
  ctx = MiniRacer::Context.new
  puts "b"
  ctx.eval("var a = #{('x' * 100000).inspect}")
  puts "c"
  ctx.eval("a = undefined")
  puts "d"
  ctx.isolate.low_memory_notification
  puts "f"
  puts "done triggering"
end

trigger_gc
Process.wait fork { puts @ctx.eval("a"); @ctx.dispose; puts Process.pid; trigger_gc; puts "done #{Process.pid}" }


