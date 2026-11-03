# minimal memory allocator for swm
class Memory
  def initialize(capacity: 4096)
    raise ArgumentError, "capacity must be a positive integer" unless capacity.is_a?(Integer) && capacity.positive?

    @capacity = capacity
    @used = 0
    @next_address = 1
    @blocks = {}
  end

  def allocate(size)
    raise ArgumentError, "size must be a positive integer" unless size.is_a?(Integer) && size.positive?
    raise NoMemoryError, "not enough memory" if size > available

    address = @next_address
    @next_address += 1
    @blocks[address] = "\0".b * size
    @used += size
    address
  end

  def free(address)
    block = @blocks.delete(address)
    raise ArgumentError, "unknown allocation: #{address}" unless block

    @used -= block.bytesize
  end

  def write(address, value, offset: 0)
    block = fetch_block(address)
    bytes = value.to_s.b
    validate_range(block, offset, bytes.bytesize)
    block[offset, bytes.bytesize] = bytes
  end

  def read(address, length: nil, offset: 0)
    block = fetch_block(address)
    length ||= block.bytesize - offset
    validate_range(block, offset, length)
    block.byteslice(offset, length) # byteslice is used to return the new string
  end

  def used
    @used
  end

  def available
    @capacity - @used
  end

  private

  def fetch_block(address)
    @blocks.fetch(address) { raise ArgumentError, "unknown allocation: #{address}" }
  end

  def validate_range(block, offset, length)
    unless offset.is_a?(Integer) && length.is_a?(Integer) && offset >= 0 && length >= 0 && offset + length <= block.bytesize
      raise RangeError, "memory access is outside the allocation"
    end
  end
end