# don't touch you'll break smth :sob:

require_relative "../alloc/memory"
require_relative "../alloc/swm-perip"

memory = Memory.new(capacity: 256)
peripheral = SWMPerip.new(memory, size: 4)

peripheral.write_register(0, 42)
puts "register 0: #{peripheral.read_register(0)}"
puts "memory used: #{memory.used} bytes"

peripheral.close
puts "memory use produced issssss: #{memory.used} bytes" # **VERY HIGH** chance of mem leaks