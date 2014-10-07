#                                                         -*- coding: utf-8 -*-
#! \file    ./fmtviewer/cpascal.rb
#! \author  Jiří Kučera, <sanczes@gmail.com>
#! \stamp   2014-08-18 20:25:13 (UTC+01:00, DST+01:00)
#! \project textools: Utilities for debugging TeX/LaTeX output.
#! \license MIT
#! \version 0.1.0
#! \fdesc   Several C/Pascal data types and structures.
#

module CPascal

  class MemReadError < StandardError
  end

  class MemWriteError < StandardError
  end

  COMPUTER_BASE = 2
  CHAR_BITS = 8

  def self.min_const(nchars)
    -COMPUTER_BASE**(CHAR_BITS**nchars - 1)
  end

  def self.max_const(nchars)
    COMPUTER_BASE**(CHAR_BITS**nchars - 1) - 1
  end

  def self.umin_const(nchars)
    0
  end

  def self.umax_const(nchars)
    COMPUTER_BASE**(CHAR_BITS**nchars) - 1
  end

  # char
  class CharType
    SIZE = 1
    MIN = CPascal::min_const(SIZE)
    MAX = CPascal::max_const(SIZE)
    PACKER = "c"
    UNPACKER = "c"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # unsigned char
  class UnsignedCharType
    SIZE = 1
    MIN = CPascal::umin_const(SIZE)
    MAX = CPascal::umax_const(SIZE)
    PACKER = "C"
    UNPACKER = "C"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # short
  class ShortType
    SIZE = 2
    MIN = CPascal::min_const(SIZE)
    MAX = CPascal::max_const(SIZE)
    PACKER = "s>"
    UNPACKER = "s>"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # unsigned short
  class UnsignedShortType
    SIZE = 2
    MIN = CPascal::umin_const(SIZE)
    MAX = CPascal::umax_const(SIZE)
    PACKER = "S>"
    UNPACKER = "S>"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # int
  class IntType
    SIZE = 4
    MIN = CPascal::min_const(SIZE)
    MAX = CPascal::max_const(SIZE)
    PACKER = "l>"
    UNPACKER = "l>"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # unsigned int
  class UnsignedIntType
    SIZE = 4
    MIN = CPascal::umin_const(SIZE)
    MAX = CPascal::umax_const(SIZE)
    PACKER = "L>"
    UNPACKER = "L>"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # long
  class LongType
    SIZE = 4
    MIN = CPascal::min_const(SIZE)
    MAX = CPascal::max_const(SIZE)
    PACKER = "l>"
    UNPACKER = "l>"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # unsigned long
  class UnsignedLongType
    SIZE = 4
    MIN = CPascal::umin_const(SIZE)
    MAX = CPascal::umax_const(SIZE)
    PACKER = "L>"
    UNPACKER = "L>"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # float
  class FloatType
    SIZE = 4
    MIN = Float::MIN
    MAX = Float::MAX
    PACKER = "g"
    UNPACKER = "g"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # double
  class DoubleType
    SIZE = 8
    MIN = Float::MIN
    MAX = Float::MAX
    PACKER = "G"
    UNPACKER = "G"

    class Accessor
      def initialize(mem, offset)
        @mem = mem
        @offset = offset
      end

      def _
        @mem[@offset, SIZE].unpack(UNPACKER)[0]
      end

      def _=(x)
        @mem[@offset, SIZE] = [x].pack(PACKER)
      end
    end
  end

  # void *
  class RawMemoryBlock
    def initialize(bs, name = "<mem>")
      @data = bs
      @name = name
    end

    def [](offset, length)
      if offset < 0 or offset + length > @data.size
        raise MemReadError.new(
          "" << @name << " (" << @data.size.to_s << " B) " \
          << "[" << offset.to_s << ", " << length.to_s << "]"
        )
      end
      @data[offset, length]
    end

    def []=(offset, length, bytes)
      if bytes.class != String or offset < 0 or offset + length > @data.size \
      or length != bytes.size
        raise MemWriteError.new(
          "" << @name << " (" << @data.size.to_s << " B) " \
          << "[" << offset.to_s << ", " << length.to_s << "] = " \
          << bytes.class.to_s << " (" << bytes.size.to_s << " B)"
        )
      end
      @data[offset, length] = bytes
    end

    def name
      @name
    end

    def size
      @data.size
    end

    def empty?
      @data.empty?
    end

    def data
      @data
    end
  end

  class Pointer
    def initialize(mem, base, t)
      @mem = mem
      @base = base
      @t = t
    end

    def mem
      @mem
    end

    def base
      @base
    end

    def t
      @t
    end

    def [](offset, length = -1)
      if length < 0
        return @t::Accessor.new(@mem, (@base + offset) * @t::SIZE)
      end
      if (@base + offset) * @t::SIZE < 0 \
      or (@base + offset + length) * @t::SIZE > @mem.size
        raise MemReadError.new(
          @mem.name << " (" << @mem.size.to_s << " B) " \
          << "[" \
          << ((@base + offset) * @t::SIZE).to_s \
          << ", " \
          << (length * @t::SIZE).to_s \
          << "]"
        )
      end
      @mem.data[(@base + offset) * @t::SIZE, length * @t::SIZE]
    end

    def []=(offset, length, bytes)
      if bytes.class != String \
      or (@base + offset) * @t::SIZE < 0 \
      or (@base + offset + length) * @t::SIZE > @mem.size \
      or length * @t::SIZE != bytes.size
        raise MemWriteError.new(
          @mem.name << " (" << @mem.size.to_s << " B) " \
          << "[" \
          << ((@base + offset) * @t::SIZE).to_s \
          << ", " \
          << (length * @t::SIZE).to_s \
          << "] = " \
          << bytes.class.to_s << " (" << bytes.size.to_s << " B)"
        )
      end
      @mem.data[(@base + offset) * @t::SIZE, length * @t::SIZE] = bytes
    end

    def +(offset)
      Pointer.new(@mem, @base + offset, @t)
    end

    def -(offset)
      Pointer.new(@mem, @base - offset, @t)
    end
  end

  def self.xmalloc_array(t, sz, name = "<xmalloc_array>")
    Pointer.new(RawMemoryBlock.new("\x00" * ((sz + 1) * t::SIZE), name), 0, t)
  end

  def self.b2m(bytes, t, name = "<casted bytes>")
    Pointer.new(RawMemoryBlock.new(bytes, name), 0, t)
  end

  def self.round(r)
    if r > 2147483647.0
      return 2147483647
    elsif r < -2147483647.0
      return -2147483647
    elsif r >= 0.0
      return (r + 0.5).floor
    end
    (r - 0.5).floor
  end

end
