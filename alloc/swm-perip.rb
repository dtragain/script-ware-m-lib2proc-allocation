class SWMPerip
  def initialize(memory, size: 16)
    @memory = memory
    @address = memory.allocate(size)
    @closed = false
  end

  def write_register(offset, value)
    ensure_open
    raise RangeError, "register value must fit in one byte (ty showerhead)" unless value.is_a?(Integer) && value.between?(0, 255)

    @memory.write(@address, [value].pack("C"), offset: offset)
  end

  def read_register(offset)
    ensure_open
# reads from user-space
    @memory.read(@address, length: 1, offset: offset).unpack1("C")
  end

  def close
    return if @closed

    @memory.free(@address)
    @closed = true
  end

  private

  def ensure_open
    raise IOError, "peripheral is closed" if @closed
  end
end