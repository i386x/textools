#                                                         -*- coding: utf-8 -*-
#! \file    ./fmtviewer/textypes.rb
#! \author  Jiří Kučera, <sanczes@gmail.com>
#! \stamp   2014-08-20 22:59:37 (UTC+01:00, DST+01:00)
#! \project textools: Utilities for debugging TeX/LaTeX output.
#! \license MIT
#! \version 0.1.0
#! \fdesc   TeX/pdfTeX types definitions.
#

require './cpascal'

module PdfTeX

  module Types
    # {131}:
    # From ${TEXLIVE_SOURCE}/texk/web2c/texmfmem.h:
    class TwoHalvesType
      SIZE = 8

      class Accessor
        def initialize(mem, offset)
          @mem = mem
          @offset = offset
        end

        def _
          @mem[@offset, SIZE]
        end

        def _=(x)
          @mem[@offset, SIZE] = x
        end

        def lh
          CPascal::IntType::Accessor.new @mem, @offset + 4
        end

        def rh
          CPascal::IntType::Accessor.new @mem, @offset
        end

        def b0
          CPascal::UnsignedCharType::Accessor.new @mem, @offset + 5
        end

        def b1
          CPascal::UnsignedCharType::Accessor.new @mem, @offset + 7
        end
      end
    end

    class FourQuartersType
      SIZE = 4

      class Accessor
        def initialize(mem, offset)
          @mem = mem
          @offset = offset
        end

        def _
          @mem[@offset, SIZE]
        end

        def _=(x)
          @mem[@offset, SIZE] = x
        end

        def b0
          CPascal::UnsignedCharType::Accessor.new @mem, @offset
        end

        def b1
          CPascal::UnsignedCharType::Accessor.new @mem, @offset + 1
        end

        def b2
          CPascal::UnsignedCharType::Accessor.new @mem, @offset + 2
        end

        def b3
          CPascal::UnsignedCharType::Accessor.new @mem, @offset + 3
        end
      end
    end

    class MemoryWordType
      SIZE = 8

      # Accessor == MemoryWord
      class Accessor
        def initialize(mem, offset)
          @mem = mem
          @offset = offset
        end

        def _
          @mem[@offset, SIZE]
        end

        def _=(x)
          @mem[@offset, SIZE] = x
        end

        def gr
          CPascal::DoubleType::Accessor.new @mem, @offset
        end

        def hh
          TwoHalvesType::Accessor.new @mem, @offset
        end

        def int
          CPascal::IntType::Accessor.new @mem, @offset
        end

        def sc
          CPascal::IntType::Accessor.new @mem, @offset
        end

        def qqqq
          FourQuartersType::Accessor.new @mem, @offset
        end
      end
    end

    class FMemoryWordType
      SIZE = CPascal::IntType::SIZE

      class Accessor
        def initialize(mem, offset)
          @mem = mem
          @offset = offset
        end

        def _
          @mem[@offset, SIZE]
        end

        def _=(x)
          @mem[@offset, SIZE] = x
        end

        def int
          CPascal::IntType::Accessor.new @mem, @offset
        end

        def qqqq
          FourQuartersType::Accessor.new @mem, @offset
        end
      end
    end

    class CharUsedArrayType
      SIZE = 32 * CPascal::UnsignedCharType::SIZE

      class Accessor
        def initialize(mem, offset)
          @mem = mem
          @offset = offset
        end

        def _
          @mem[@offset, SIZE]
        end

        def _=(x)
          @mem[@offset, SIZE] = x
        end

        def [](i)
          CPascal::UnsignedCharType::Accessor.new(
            @mem, @offset + i*CPascal::UnsignedCharType::SIZE
          )
        end
      end
    end

    # {230}:
    class ListStateRecordType
      SIZE = CPascal::CharType::SIZE + # mode_field
             CPascal::IntType::SIZE  + # head_field
             CPascal::IntType::SIZE  + # tail_field
             CPascal::IntType::SIZE  + # eTeX_aux_field
             CPascal::IntType::SIZE  + # pg_field
             CPascal::IntType::SIZE  + # ml_field
             MemoryWordType::SIZE      # aux_field

      class Accessor
        def initialize(mem, offset)
          @mem = mem
          @offset = offset
        end

        def _
          @mem[@offset, SIZE]
        end

        def _=(x)
          @mem[@offset, SIZE] = x
        end

        def mode_field
          CPascal::CharType::Accessor.new(@mem, @offset)
        end

        def head_field
          CPascal::IntType::Accessor.new(
            @mem, @offset + CPascal::CharType::SIZE
          )
        end

        def tail_field
          CPascal::IntType::Accessor.new(
            @mem, @offset + CPascal::CharType::SIZE \
                          + CPascal::IntType::SIZE
          )
        end

        def eTeX_aux_field
          CPascal::IntType::Accessor.new(
            @mem, @offset + CPascal::CharType::SIZE \
                          + 2 * CPascal::IntType::SIZE
          )
        end

        def pg_field
          CPascal::IntType::Accessor.new(
            @mem, @offset + CPascal::CharType::SIZE \
                          + 3 * CPascal::IntType::SIZE
          )
        end

        def ml_field
          CPascal::IntType::Accessor.new(
            @mem, @offset + CPascal::CharType::SIZE \
                          + 4 * CPascal::IntType::SIZE
          )
        end

        def aux_field
          MemoryWordType::Accessor.new(
            @mem, @offset + CPascal::CharType::SIZE \
                          + 5 * CPascal::IntType::SIZE
          )
        end
      end
    end

    class ObjEntryType
      SIZE = 5 * CPascal::IntType::SIZE

      class Accessor
        def initialize(mem, offset)
          @mem = mem
          @offset = offset
        end

        def _
          @mem[@offset, SIZE]
        end

        def _=(x)
          @mem[@offset, SIZE] = x
        end

        def int0
          CPascal::IntType::Accessor.new(@mem, @offset)
        end

        def int1
          CPascal::IntType::Accessor.new(
            @mem, @offset + CPascal::IntType::SIZE
          )
        end

        def int2
          CPascal::IntType::Accessor.new(
            @mem, @offset + 2*CPascal::IntType::SIZE
          )
        end

        def int3
          CPascal::IntType::Accessor.new(
            @mem, @offset + 3*CPascal::IntType::SIZE
          )
        end

        def int4
          CPascal::IntType::Accessor.new(
            @mem, @offset + 4*CPascal::IntType::SIZE
          )
        end
      end
    end

    class ImageStructType
      attr_accessor :image_name
      attr_accessor :image_type, :color_type
      attr_accessor :width, :height
      attr_accessor :x_res, :y_res
      attr_accessor :num_pages
      attr_accessor :colorspace_ref, :group_ref
      attr_accessor :page_box, :selected_page

      def initialize
      end
    end

  end

end
