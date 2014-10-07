#                                                         -*- coding: utf-8 -*-
#! \file    ./fmtviewer/texlib.rb
#! \author  Jiří Kučera, <sanczes@gmail.com>
#! \stamp   2014-08-15 01:08:13 (UTC+01:00, DST+01:00)
#! \project textools: Utilities for debugging TeX/LaTeX output.
#! \license MIT
#! \version 0.1.0
#! \fdesc   Library containing some parts of TeX/pdfTeX.
#

require './cpascal'
require './texdefs'
require './textypes'
require './texcfg'

module PdfTeX

  class ArithError < StandardError
  end

  class OverflowError < StandardError
  end

  class BadFmtError < StandardError
  end

  class Data
    attr_accessor :ptexbanner, :versionstring, :kpathsea_version_string
    attr_accessor :pool_checksum
    attr_accessor :xord, :xchr, :xprn
    attr_accessor :hash_high, :hash_extra, :hash_top, :hash_used
    attr_accessor :eqtb_top
    attr_accessor :hash, :eqtb
    attr_accessor :eTeX_mode
    attr_accessor :max_reg_num, :max_reg_help_line
    attr_accessor :mem_bot, :mem_top, :main_memory
    attr_accessor :extra_mem_top, :extra_mem_bot
    attr_accessor :mem_min, :mem_max
    attr_accessor :cur_list, :page_tail
    attr_accessor :mem
    attr_accessor :mltex_enabled_p
    attr_accessor :enctex_enabled_p
    attr_accessor :mubyte_read, :mubyte_write, :mubyte_cswrite
    attr_accessor :pool_free, :pool_ptr, :pool_size
    attr_accessor :strings_free, :str_ptr, :max_strings
    attr_accessor :str_start, :str_pool, :init_str_ptr, :init_pool_ptr
    attr_accessor :lo_mem_max, :rover
    attr_accessor :sa_root
    attr_accessor :hi_mem_min, :avail, :mem_end, :var_used, :dyn_used
    attr_accessor :par_loc, :par_token, :write_loc
    attr_accessor :prim, :prim_eqtb
    attr_accessor :cs_count
    attr_accessor :fmem_ptr, :font_mem_size
    attr_accessor :font_info, :font_ptr
    attr_accessor :font_max
    attr_accessor :font_check, :font_size, :font_dsize, :font_params
    attr_accessor :font_name, :font_area, :font_bc, :font_ec, :font_glue
    attr_accessor :hyphen_char, :skew_char, :bchar_label
    attr_accessor :font_bchar, :font_false_bchar, :char_base
    attr_accessor :width_base, :height_base, :depth_base
    attr_accessor :italic_base, :lig_kern_base, :kern_base
    attr_accessor :exten_base, :param_base
    attr_accessor :pdf_char_used, :pdf_font_size, :pdf_font_num, :pdf_font_map
    attr_accessor :pdf_font_type, :pdf_font_attr
    attr_accessor :pdf_font_blink, :pdf_font_elink
    attr_accessor :pdf_font_stretch, :pdf_font_shrink, :pdf_font_step
    attr_accessor :pdf_font_expand_ratio, :pdf_font_auto_expand
    attr_accessor :pdf_font_lp_base, :pdf_font_rp_base, :pdf_font_ef_base
    attr_accessor :pdf_font_kn_bs_base, :pdf_font_st_bs_base
    attr_accessor :pdf_font_sh_bs_base, :pdf_font_kn_bc_base
    attr_accessor :pdf_font_kn_ac_base
    attr_accessor :vf_packet_base, :vf_default_font, :vf_local_font_num
    attr_accessor :vf_e_fnts, :vf_i_fnts
    attr_accessor :pdf_font_nobuiltin_tounicode
    attr_accessor :hyph_size, :hyph_count, :hyph_next
    attr_accessor :hyph_link, :hyph_word, :hyph_list
    attr_accessor :trie_size, :trie_max, :hyph_start
    attr_accessor :trie_trl, :trie_tro, :trie_trc
    attr_accessor :trie_op_ptr
    attr_accessor :hyf_distance, :hyf_num, :hyf_next
    attr_accessor :trie_used, :op_start, :trie_not_ready
    attr_accessor :image_limit, :image_array, :cur_image
    attr_accessor :pdf_mem_size, :pdf_mem, :pdf_mem_ptr
    attr_accessor :obj_tab_size, :obj_ptr, :sys_obj_ptr, :obj_tab
    attr_accessor :pdf_obj_count, :pdf_xform_count, :pdf_ximage_count
    attr_accessor :head_tab
    attr_accessor :pdf_last_obj, :pdf_last_xform, :pdf_last_ximage
    attr_accessor :interaction, :format_ident

    def initialize(owner)
      @owner = owner
      reinitialize
    end

    def reinitialize
      @ptexbanner = Defs::S_BANNER
      @versionstring = Defs::S_WEB2CVERSION
      @kpathsea_version_string = Defs::S_KPSEVERSION
      # Initialize variables (PHASE 1):
      @mem_bot = TeXLiveConfig::setvar(:mem_bot, 0)
      @main_memory = TeXLiveConfig::setvar(:main_memory, 250000)
      @extra_mem_top = TeXLiveConfig::setvar(:extra_mem_top, 0)
      @extra_mem_bot = TeXLiveConfig::setvar(:extra_mem_bot, 0)
      @pool_size = TeXLiveConfig::setvar(:pool_size, 200000)
      @pool_free = TeXLiveConfig::setvar(:pool_free, 5000)
      @max_strings = TeXLiveConfig::setvar(:max_strings, 15000)
      @strings_free = TeXLiveConfig::setvar(:strings_free, 100)
      @font_mem_size = TeXLiveConfig::setvar(:font_mem_size, 100000)
      @font_max = TeXLiveConfig::setvar(:font_max, 500)
      @trie_size = TeXLiveConfig::setvar(:trie_size, 20000)
      @hyph_size = TeXLiveConfig::setvar(:hyph_size, 659)
      @hash_extra = TeXLiveConfig::setvar(:hash_extra, 0)
      zaux = CPascal::xmalloc_array(Types::ListStateRecordType, 1, 'cur_list')
      @cur_list = zaux[0]
      # Saturate initialized variables:
      # - mem_bot:
      if @mem_bot < Defs::INF_MEM_BOT then
        @mem_bot = Defs::INF_MEM_BOT
      elsif @mem_bot > Defs::SUP_MEM_BOT then
        @mem_bot = Defs::SUP_MEM_BOT
      end
      # - main_memory:
      if @main_memory < Defs::INF_MAIN_MEMORY then
        @main_memory = Defs::INF_MAIN_MEMORY
      elsif @main_memory > Defs::SUP_MAIN_MEMORY then
        @main_memory = Defs::SUP_MAIN_MEMORY
      end
      # - extra_mem_bot:
      if @extra_mem_bot > Defs::SUP_MAIN_MEMORY then
        @extra_mem_bot = Defs::SUP_MAIN_MEMORY
      end
      # - extra_mem_top:
      if @extra_mem_top > Defs::SUP_MAIN_MEMORY then
        @extra_mem_top = Defs::SUP_MAIN_MEMORY
      end
      # - setup mem_top, mem_min, mem_max:
      @mem_top = @mem_bot + @main_memory - 1
      @mem_min = @mem_bot
      @mem_max = @mem_top
      # - pool_size:
      if @pool_size < Defs::INF_POOL_SIZE then
        @pool_size = Defs::INF_POOL_SIZE
      elsif @pool_size > Defs::SUP_POOL_SIZE then
        @pool_size = Defs::SUP_POOL_SIZE
      end
      # - pool_free:
      if @pool_free < Defs::INF_POOL_FREE then
        @pool_free = Defs::INF_POOL_FREE
      elsif @pool_free > Defs::SUP_POOL_FREE then
        @pool_free = Defs::SUP_POOL_FREE
      end
      # - max_strings:
      if @max_strings < Defs::INF_MAX_STRINGS then
        @max_strings = Defs::INF_MAX_STRINGS
      elsif @max_strings > Defs::SUP_MAX_STRINGS then
        @max_strings = Defs::SUP_MAX_STRINGS
      end
      # - strings_free:
      if @strings_free < Defs::INF_STRINGS_FREE then
        @strings_free = Defs::INF_STRINGS_FREE
      elsif @strings_free > Defs::SUP_STRINGS_FREE then
        @strings_free = Defs::SUP_STRINGS_FREE
      end
      # - font_mem_size:
      if @font_mem_size < Defs::INF_FONT_MEM_SIZE then
        @font_mem_size = Defs::INF_FONT_MEM_SIZE
      elsif @font_mem_size > Defs::SUP_FONT_MEM_SIZE then
        @font_mem_size = Defs::SUP_FONT_MEM_SIZE
      end
      # - font_max:
      if @font_max < Defs::INF_FONT_MAX then
        @font_max = Defs::INF_FONT_MAX
      elsif @font_max > Defs::SUP_FONT_MAX then
        @font_max = Defs::SUP_FONT_MAX
      end
      # - trie_size:
      if @trie_size < Defs::INF_TRIE_SIZE then
        @trie_size = Defs::INF_TRIE_SIZE
      elsif @trie_size > Defs::SUP_TRIE_SIZE then
        @trie_size = Defs::SUP_TRIE_SIZE
      end
      # - hyph_size:
      if @hyph_size < Defs::INF_HYPH_SIZE then
        @hyph_size = Defs::INF_HYPH_SIZE
      elsif @hyph_size > Defs::SUP_HYPH_SIZE then
        @hyph_size = Defs::SUP_HYPH_SIZE
      end
      # - hash_extra:
      if @hash_extra < Defs::INF_HASH_EXTRA then
        @hash_extra = Defs::INF_HASH_EXTRA
      elsif @hash_extra > Defs::SUP_HASH_EXTRA then
        @hash_extra = Defs::SUP_HASH_EXTRA
      end
      # - hyph_word, hyph_link, hyph_list:
      @hyph_word = CPascal::xmalloc_array(
        CPascal::IntType, @hyph_size, 'hyph_word'
      )
      @hyph_list = CPascal::xmalloc_array(
        CPascal::IntType, @hyph_size, 'hyph_list'
      )
      @hyph_link = CPascal::xmalloc_array(
        CPascal::UnsignedShortType, @hyph_size, 'hyph_link'
      )
      # - hyf_distance, hyf_num, hyf_next:
      @hyf_distance = CPascal::xmalloc_array(
        CPascal::UnsignedCharType, Defs::TRIE_OP_SIZE + 1, 'hyf_distance'
      )
      @hyf_num = CPascal::xmalloc_array(
        CPascal::UnsignedCharType, Defs::TRIE_OP_SIZE + 1, 'hyf_num'
      )
      @hyf_next = CPascal::xmalloc_array(
        CPascal::UnsignedShortType, Defs::TRIE_OP_SIZE + 1, 'hyf_next'
      )
      # - op_start:
      @op_start = CPascal::xmalloc_array(
        CPascal::IntType, 256, 'op_start'
      )
      # - trie_used:
      @trie_used = CPascal::xmalloc_array(
        CPascal::UnsignedShortType, 256, 'trie_used'
      )
      # - obj_tab:
      @obj_tab = CPascal::xmalloc_array(
        Types::ObjEntryType, Defs::INF_OBJ_TAB_SIZE, 'obj_tab'
      )
      # - head_tab:
      @head_tab = CPascal::xmalloc_array(
        CPascal::IntType, Defs::HEAD_TAB_MAX + 1, 'head_tab'
      )
      # Initialize variables (PHASE 2):
      # - mubyte_read, mubyte_write, mubyte_cswrite
      @mubyte_read = CPascal::xmalloc_array(
        CPascal::IntType, 256, 'mubyte_read'
      )
      (0..255).each {|i| @mubyte_read[i]._ = Defs::NULL}
      @mubyte_write = CPascal::xmalloc_array(
        CPascal::IntType, 256, 'mubyte_write'
      )
      (0..255).each {|i| @mubyte_write[i]._ = 0}
      @mubyte_cswrite = CPascal::xmalloc_array(
        CPascal::IntType, 128, 'mubyte_cswrite'
      )
      (0..127).each {|i| @mubyte_cswrite[i]._ = Defs::NULL}
      # - cur_list:
      mode._ = Defs::VMODE
      head._ = contrib_head
      tail._ = contrib_head
      eTeX_aux._ = Defs::NULL
      prev_depth._ = Defs::IGNORE_DEPTH
      mode_line._ = 0
      prev_graf._ = 0
      # - hyph_word, hyph_link, hyph_list:
      (0..@hyph_size).each do |z|
        @hyph_word[z]._ = 0
        @hyph_list[z]._ = Defs::NULL
        @hyph_link[z]._ = 0
      end
      # - sa_root:
      @sa_root = CPascal::xmalloc_array(
        CPascal::IntType, Defs::MARK_VAL + 1, 'sa_root'
      )
      sa_mark._ = Defs::NULL
      (Defs::INT_VAL..Defs::TOK_VAL).each {|i| @sa_root[i]._ = Defs::NULL}
      # - mltex_enabled_p:
      @mltex_enabled_p = false
      # - enctex_enabled_p:
      @enctex_enabled_p = false
    end

    # -------------------------------------------------------------------------
    # -- Cleaning things up
    # --
    def cleanup
      @ptexbanner = @versionstring = @kpathsea_version_string = \
      @pool_checksum = \
      @xord = @xchr = @xprn = \
      @hash_high = @hash_extra = @hash_top = @hash_used = \
      @eqtb_top = \
      @hash = @eqtb = \
      @eTeX_mode = \
      @max_reg_num = @max_reg_help_line = \
      @mem_bot = @mem_top = @main_memory = \
      @extra_mem_top = @extra_mem_bot = \
      @mem_min = @mem_max = \
      @cur_list = @page_tail = \
      @mem = \
      @mltex_enabled_p = \
      @enctex_enabled_p = \
      @mubyte_read = @mubyte_write = @mubyte_cswrite = \
      @pool_free = @pool_ptr = @pool_size = \
      @strings_free = @str_ptr = @max_strings = \
      @str_start = @str_pool = @init_str_ptr = @init_pool_ptr = \
      @lo_mem_max = @rover = \
      @sa_root = \
      @hi_mem_min = @avail = @mem_end = @var_used = @dyn_used = \
      @par_loc = @par_token = @write_loc = \
      @prim = @prim_eqtb = \
      @cs_count = \
      @fmem_ptr = @font_mem_size = \
      @font_info = @font_ptr = \
      @font_max = \
      @font_check = @font_size = @font_dsize = @font_params = \
      @font_name = @font_area = @font_bc = @font_ec = @font_glue = \
      @hyphen_char = @skew_char = @bchar_label = \
      @font_bchar = @font_false_bchar = @char_base = \
      @width_base = @height_base = @depth_base = \
      @italic_base = @lig_kern_base = @kern_base = \
      @exten_base = @param_base = \
      @pdf_char_used = @pdf_font_size = @pdf_font_num = @pdf_font_map = \
      @pdf_font_type = @pdf_font_attr = \
      @pdf_font_blink = @pdf_font_elink = \
      @pdf_font_stretch = @pdf_font_shrink = @pdf_font_step = \
      @pdf_font_expand_ratio = @pdf_font_auto_expand = \
      @pdf_font_lp_base = @pdf_font_rp_base = @pdf_font_ef_base = \
      @pdf_font_kn_bs_base = @pdf_font_st_bs_base = \
      @pdf_font_sh_bs_base = @pdf_font_kn_bc_base = \
      @pdf_font_kn_ac_base = \
      @vf_packet_base = @vf_default_font = @vf_local_font_num = \
      @vf_e_fnts = @vf_i_fnts = \
      @pdf_font_nobuiltin_tounicode = \
      @hyph_size = @hyph_count = @hyph_next = \
      @hyph_link = @hyph_word = @hyph_list = \
      @trie_size = @trie_max = @hyph_start = \
      @trie_trl = @trie_tro = @trie_trc = \
      @trie_op_ptr = \
      @hyf_distance = @hyf_num = @hyf_next = \
      @trie_used = @op_start = @trie_not_ready = \
      @image_limit = @image_array = @cur_image = \
      @pdf_mem_size = @pdf_mem = @pdf_mem_ptr = \
      @obj_tab_size = @obj_ptr = @sys_obj_ptr = @obj_tab = \
      @pdf_obj_count = @pdf_xform_count = @pdf_ximage_count = \
      @head_tab = \
      @pdf_last_obj = @pdf_last_xform = @pdf_last_ximage = \
      @interaction = @format_ident = nil
      GC.start
      reinitialize
      GC.start
    end

    # -------------------------------------------------------------------------
    # -- pdfTeX .fmt file loading
    # --
    def load_fmt_file(fd)
      begin
        @percentil = 0
        @oldperc = -1
        @percmax = @owner.signal :get_max_perc
        @fsize = fd.stat.size?
        wake_up_terminal
        wterm_ln("Loading \"#{fd.path}\" ...")
        status("Undumping constants ...")
        #hexdump("Test", "Test")
        #return true
        undump_constants(fd)
        status("Undumping MLTeX specific data ...")
        undump_MLTeX_specific_data(fd)
        status("Undumping encTeX specific data ...")
        undump_encTeX_specific_data(fd)
        status("Undumping string pool ...")
        undump_string_pool(fd)
        status("Undumping dynamic memory ...")
        undump_dynamic_memory(fd)
        status("Undumping the table of equivalents ...")
        undump_table_of_equivalents(fd)
        status("Undumping font informations ...")
        undump_font_info(fd)
        status("Undumping hyphenation tables ...")
        undump_hyphen_tables(fd)
        status("Undumping pdfTeX specific data ...")
        undump_pdftex_data(fd)
        status("Undumping the couple of last things ...")
        undump_last_things(fd)
        prev_depth._ = pdf_ignored_dimen._
        inform("cur_list.mode_field", @cur_list.mode_field._.to_s)
        inform("cur_list.head_field", @cur_list.head_field._.to_s)
        inform("cur_list.tail_field", @cur_list.tail_field._.to_s)
        inform("cur_list.eTeX_aux_field", @cur_list.eTeX_aux_field._.to_s)
        inform("cur_list.pg_field", @cur_list.pg_field._.to_s)
        inform("cur_list.ml_field", @cur_list.ml_field._.to_s)
        inform("cur_list.aux_field", @cur_list.aux_field.int._.to_s)
        wterm_ln("... succeed.")
        update_terminal
        status("Format file \"#{fd.path}\" was successfuly loaded.")
        return true
      rescue IOError => err
        alert fd, \
          :reason => "Failed to perform I/O operation.", \
          :detail => err.message
        wterm_ln("... failed.")
        update_terminal
        return false
      rescue IndexError => err
        alert fd, \
          :reason => "Failed to access the inaccessible place.", \
          :detail => err.message
        wterm_ln("... failed.")
        update_terminal
        return false
      rescue ArithError => err
        alert fd, \
          :reason => "Arithmetic error.", \
          :detail => err.message
        wterm_ln("... failed.")
        update_terminal
        return false
      rescue OverflowError => err
        alert fd, \
          :reason => "Failed to store the data.", \
          :detail => err.message
        wterm_ln("... failed.")
        update_terminal
        return false
      rescue BadFmtError => err
        alert fd, \
          :reason => "pdfTeX format file is corrupted.", \
          :detail => err.message
        wterm_ln("... failed.")
        update_terminal
        return false
      end
    end

    def undump_constants(fd)
      # Check the format file signature:
      x = undump_int(fd)
      if x != 0x57325458 then
        raise BadFmtError.new "Bad .fmt file signature."
      end
      inform("format file signature", i2b(x).dump)
      hexdump("Format file signature", i2b(x))
      # Check the engine name:
      x = undump_int(fd)
      if (x < 0) or (x > 256) then
        raise BadFmtError.new "TeX engine name size is out of range [0..256]."
      end
      hexdump("Engine name length", i2b(x))
      x = undump_bytes(fd, x)
      if x.rstrip != Defs::ENGINE_NAME then
        raise BadFmtError.new \
          "This .fmt file creator is not " << Defs::ENGINE_NAME << "."
      end
      inform("engine name", x.rstrip.dump)
      hexdump("Engine name", x)
      # Undump the pool checksum:
      @pool_checksum = undump_int(fd)
      inform("string pool checksum", @pool_checksum.to_s)
      hexdump("String pool checksum", i2b(@pool_checksum))
      # Undump xord, xchr, xprn:
      undump_xord_xchr_xprn(fd)
      # Check max_halfword:
      x = undump_int(fd)
      if x != Defs::MAX_HALFWORD then
        raise BadFmtError.new "Bad MAX_HALFWORD value (#{x})."
      end
      inform("'MAX_HALFWORD' constant value", Defs::MAX_HALFWORD.to_s)
      hexdump("'MAX_HALFWORD' constant", i2b(x))
      # Undump and check hash_high:
      @hash_high = undump_int(fd)
      if (@hash_high < 0) or (@hash_high > Defs::SUP_HASH_EXTRA) then
        raise BadFmtError.new \
          "'hash_high' value out of range [" << 0..Defs::SUP_HASH_EXTRA << "]."
      end
      inform("'hash_high' value", @hash_high.to_s)
      hexdump("'hash_high' value", i2b(@hash_high))
      if @hash_extra < @hash_high then
        @hash_extra = @hash_high
      end
      inform("'hash_extra' value", @hash_extra.to_s)
      @eqtb_top = Defs::EQTB_SIZE + @hash_extra
      inform("'eqtb_top' value", @eqtb_top.to_s)
      if @hash_extra == 0 then
        @hash_top = Defs::UNDEFINED_CONTROL_SEQUENCE
      else
        @hash_top = @eqtb_top
      end
      inform("'hash_top' value", @hash_top.to_s)
      # Allocate and erase hash:
      yhash = CPascal::xmalloc_array(
        Types::TwoHalvesType, 1 + @hash_top - Defs::HASH_OFFSET, "hash"
      )
      @hash = yhash - Defs::HASH_OFFSET
      next_(Defs::HASH_BASE)._ = 0
      text(Defs::HASH_BASE)._ = 0
      ((Defs::HASH_BASE + 1)..@hash_top).each do |x|
        @hash[x]._ = @hash[Defs::HASH_BASE]._
      end
      memstats(@hash)
      # Allocate eqtb and erase hash_extra part:
      zeqtb = CPascal::xmalloc_array(
        Types::MemoryWordType, @eqtb_top + 1, "eqtb"
      )
      @eqtb = zeqtb
      eq_type(Defs::UNDEFINED_CONTROL_SEQUENCE)._ = Defs::UNDEFINED_CS
      equiv(Defs::UNDEFINED_CONTROL_SEQUENCE)._ = Defs::NULL
      eq_level(Defs::UNDEFINED_CONTROL_SEQUENCE)._ = Defs::LEVEL_ZERO
      ((Defs::EQTB_SIZE + 1)..@eqtb_top).each do |x|
        @eqtb[x]._ = @eqtb[Defs::UNDEFINED_CONTROL_SEQUENCE]._
      end
      memstats(@eqtb)
      # Undump epsilon-TeX state:
      undump_eTeX_state(fd)
      # Check mem_bot:
      x = undump_int(fd)
      if x != @mem_bot then
        raise BadFmtError.new "mem_bot != #{@mem_bot} (#{x})."
      end
      inform("'mem_bot' value", @mem_bot.to_s)
      hexdump("'mem_bot' value", i2b(x))
      # Undump and check mem_top:
      @mem_top = undump_int(fd)
      if @mem_bot + 1100 > @mem_top then
        raise BadFmtError.new \
          "mem_bot + 1100 > mem_top (#{@mem_bot} + 1100 > #{@mem_top})."
      end
      inform("'mem_top' value", @mem_top.to_s)
      hexdump("'mem_top' value", i2b(@mem_top))
      # Initialize page:
      head._ = contrib_head
      tail._ = contrib_head
      @page_tail = page_head
      inform("'page_tail' value", @page_tail.to_s)
      # Allocate main memory:
      inform("'extra_mem_bot' value", @extra_mem_bot.to_s)
      inform("'extra_mem_top' value", @extra_mem_top.to_s)
      @mem_min = @mem_bot - @extra_mem_bot
      inform("'mem_min' value", @mem_min.to_s)
      @mem_max = @mem_top + @extra_mem_top
      inform("'mem_max' value", @mem_max.to_s)
      inform("'main_memory' value", @main_memory.to_s)
      yzmem = CPascal::xmalloc_array(
        Types::MemoryWordType, @mem_max - @mem_min + 1, "mem"
      )
      zmem = yzmem - @mem_min
      @mem = zmem
      memstats(@mem)
      # Check eqtb size:
      x = undump_int(fd)
      if x != Defs::EQTB_SIZE then
        raise BadFmtError.new "EQTB_SIZE != #{Defs::EQTB_SIZE} (#{x})."
      end
      inform("'EQTB_SIZE' constant value", Defs::EQTB_SIZE.to_s)
      hexdump("'EQTB_SIZE' constant", i2b(x))
      # Check hash prime:
      x = undump_int(fd)
      if x != Defs::HASH_PRIME then
        raise BadFmtError.new "HASH_PRIME != #{Defs::HASH_PRIME} (#{x})."
      end
      inform("'HASH_PRIME' constant value", Defs::HASH_PRIME.to_s)
      hexdump("'HASH_PRIME' constant", i2b(x))
      # Check hyph prime:
      x = undump_int(fd)
      if x != Defs::HYPH_PRIME then
        raise BadFmtError.new "HYPH_PRIME != #{Defs::HYPH_PRIME} (#{x})."
      end
      inform("'HYPH_PRIME' constant value", Defs::HYPH_PRIME.to_s)
      hexdump("'HYPH_PRIME' constant", i2b(x))
    end
    private :undump_constants

    def undump_xord_xchr_xprn(fd)
      @xord = undump_bytes(fd, 256)
      hexdump("'xord' array", @xord)
      @xchr = undump_bytes(fd, 256)
      hexdump("'xchr' array", @xchr)
      @xprn = undump_bytes(fd, 256)
      hexdump("'xprn' array", @xprn)
    end
    private :undump_xord_xchr_xprn

    def undump_eTeX_state(fd)
      x = undump_int(fd)
      if (x < 0) or (x > 1) then
        raise BadFmtError.new "Bad eTeX mode value (must be 0 or 1)."
      end
      @eTeX_mode = x
      inform("eTeX mode", @eTeX_mode.to_s)
      hexdump("eTeX mode", i2b(@eTeX_mode))
      if eTeX_ex then
        @max_reg_num = 32767
        @max_reg_help_line = "A register number must be between 0 and 32767."
      else
        @max_reg_num = 255
        @max_reg_help_line = "A register number must be between 0 and 255."
      end
      inform("'max_reg_num' value", @max_reg_num.to_s)
    end
    private :undump_eTeX_state

    def undump_MLTeX_specific_data(fd)
      x = undump_int(fd)
      if x != 0x4D4C5458 then
        raise BadFmtError.new "MLTeX signature expected."
      end
      inform("MLTeX signature", i2b(x).dump)
      hexdump("MLTeX signature", i2b(x))
      x = undump_int(fd)
      if x == 1 then
        @mltex_enabled_p = true
      elsif x != 0 then
        raise BadFmtError.new \
          "'mltex_enabled_p' value is not in [0, 1] (#{x})."
      end
      inform("'mltex_enabled_p' value", @mltex_enabled_p.to_s)
      hexdump("'MLTeX enabled' flag", i2b(x))
    end
    private :undump_MLTeX_specific_data

    def undump_encTeX_specific_data(fd)
      x = undump_int(fd)
      if x != 0x45435458 then
        raise BadFmtError.new "encTeX signature expected."
      end
      inform("encTeX signature", i2b(x).dump)
      hexdump("encTeX signature", i2b(x))
      x = undump_int(fd)
      if x == 0 then
        @enctex_enabled_p = false
        inform("'enctex_enabled_p' value", @mltex_enabled_p.to_s)
        hexdump("'encTeX enabled' flag", i2b(x))
      elsif x != 1 then
        raise BadFmtError.new \
          "'enctex_enabled_p' value is not in [0, 1] (#{x})."
      else
        @enctex_enabled_p = true
        inform("'enctex_enabled_p' value", @mltex_enabled_p.to_s)
        hexdump("'encTeX enabled' flag", i2b(x))
        zaux = undump_bytes(fd, 256*CPascal::IntType::SIZE)
        @mubyte_read = CPascal::b2m(zaux, CPascal::IntType, 'mubyte_read')
        hexdump("'mubyte_read' array", zaux)
        zaux = undump_bytes(fd, 256*CPascal::IntType::SIZE)
        @mubyte_write = CPascal::b2m(zaux, CPascal::IntType, 'mubyte_write')
        hexdump("'mubyte_write' array", zaux)
        zaux = undump_bytes(fd, 128*CPascal::IntType::SIZE)
        @mubyte_cswrite = CPascal::b2m(
          zaux, CPascal::IntType, 'mubyte_cswrite'
        )
        hexdump("'mubyte_cswrite' array", zaux)
      end
    end
    private :undump_encTeX_specific_data

    def undump_string_pool(fd)
      # Undump and check pool_ptr:
      x = undump_int(fd)
      if x < 0 then
        raise BadFmtError.new "pool_ptr < 0 (#{x})."
      end
      if x > Defs::SUP_POOL_SIZE - @pool_free
        raise BadFmtError.new(
          "String pool size 'SUP_POOL_SIZE' is too small (" \
            "#{Defs::SUP_POOL_SIZE}" \
          "). 'SUP_POOL_SIZE' should be at least " \
            "#{x + @pool_free}" \
          "."
        )
      end
      @pool_ptr = x
      inform("'pool_free' value", @pool_free.to_s)
      inform("'pool_ptr' value", @pool_ptr.to_s)
      hexdump("'pool_ptr' value", i2b(x))
      if @pool_size < @pool_ptr + @pool_free then
        @pool_size = @pool_ptr + @pool_free
      end
      inform("'pool_size' value", @pool_size.to_s)
      # Undump and check str_ptr:
      x = undump_int(fd)
      if x < 0 then
        raise BadFmtError.new "str_ptr < 0 (#{x})."
      end
      if x > Defs::SUP_MAX_STRINGS - @strings_free then
        raise BadFmtError.new(
          "Maximal number of strings 'SUP_MAX_STRINGS' is too small (" \
          "#{Defs::SUP_MAX_STRINGS}" \
          "). 'SUP_MAX_STRINGS' should be at least " \
          "#{x + @strings_free}" \
          "."
        )
      end
      @str_ptr = x
      inform("'strings_free' value", @strings_free.to_s)
      inform("'str_ptr' value", @str_ptr.to_s)
      hexdump("'str_ptr' value", i2b(x))
      if @max_strings < @str_ptr + @strings_free then
        @max_strings = @str_ptr + @strings_free
      end
      inform("'max_strings' value", @max_strings.to_s)
      # Undump str_start:
      @str_start = CPascal::xmalloc_array(
        CPascal::IntType, @max_strings, 'str_start'
      )
      (0..@str_ptr).each do |i|
        x = undump_int(fd)
        if x < 0 or x > @pool_ptr then
          raise BadFmtError.new \
            "'str_start[#{i}]' (#{x}) not in [0, #{@pool_ptr}]."
        end
        @str_start[i]._ = x
      end
      memstats(@str_start)
      hexdump("'str_start' array", @str_start[0, @str_ptr + 1])
      # Undump str_pool:
      @str_pool = CPascal::xmalloc_array(
        CPascal::UnsignedCharType, @pool_size, 'str_pool'
      )
      @str_pool[0, @pool_ptr] = \
        undump_bytes(fd, @pool_ptr * @str_pool.t::SIZE)
      memstats(@str_pool)
      hexdump("'str_pool' array", @str_pool[0, @pool_ptr])
      @init_str_ptr = @str_ptr
      inform("'init_str_ptr' value", @init_str_ptr.to_s)
      @init_pool_ptr = @pool_ptr
      inform("'init_pool_ptr' value", @init_pool_ptr.to_s)
      # Make a helper hash [str] => strnum:
      @str_str_num_hash = {}
      (0..(@str_ptr - 1)).each do |i|
        o = @str_start[i]._
        s = @str_pool[o, length(i)]
        if @str_str_num_hash[s] != nil then
          inform(
            "warning: " \
            "Duplicit string at #{i} (#{o.to_s(16)}) in 'str_pool' array",
            s.dump
          )
        end
        @str_str_num_hash[s] = i
      end
    end
    private :undump_string_pool

    def undump_dynamic_memory(fd)
      # Undump and check lo_mem_max:
      x = undump_int(fd)
      if x < lo_mem_stat_max + 1000 or x > hi_mem_stat_min - 1 then
        raise BadFmtError.new(
          "'lo_mem_max' (#{x}) is not in [" \
          "#{lo_mem_stat_max + 1000}" \
          ", " \
          "#{hi_mem_stat_min - 1}" \
          "]."
        )
      end
      @lo_mem_max = x
      inform("'lo_mem_max' value", @lo_mem_max.to_s)
      hexdump("'lo_mem_max' value", i2b(x))
      # Undump and check rover:
      x = undump_int(fd)
      if x < lo_mem_stat_max + 1 or x > @lo_mem_max then
        raise BadFmtError.new(
          "'rover' (#{x}) is not in [" \
          "#{lo_mem_stat_max + 1}" \
          ", " \
          "#{@lo_mem_max}" \
          "]."
        )
      end
      @rover = x
      inform("'rover' value", @rover.to_s)
      hexdump("'rover' value", i2b(x))
      # Undump sa_root if extended mode is enabled:
      if eTeX_ex
        (Defs::INT_VAL..Defs::TOK_VAL).each do |k|
          x = undump_int(fd)
          if x < Defs::NULL or x > @lo_mem_max then
            raise BadFmtError.new(
              "'sa_root[#{k}]' (#{x}) is not in [" \
              "#{Defs::NULL}" \
              ", " \
              "#{@lo_mem_max}" \
              "]."
            )
          end
          @sa_root[k]._ = x
        end
        hexdump("'sa_root' array", @sa_root[0, Defs::TOK_VAL + 1])
      end
      # Undump memory area #1:
      p = @mem_bot
      q = @rover
      i = 1
      loop do
        @mem[p, q + 2 - p] = \
          undump_bytes(fd, (q + 2 - p) * @mem.t::SIZE)
        hexdump(
          "'mem' array, area #1, chunk #{i} [#{p}, #{q + 2})",
          @mem[p, q + 2 - p]
        )
        p = q + node_size(q)._
        if p > @lo_mem_max or (q >= rlink(q)._ and rlink(q)._ != @rover) then
          raise BadFmtError.new(
            "Main memory is corrupted after area #1, chunk #{i} (failed at " \
            "condition p (= #{p}) > lo_mem_max (= #{@lo_mem_max}) or (" \
            "q (= #{q}) >= rlink(q) (= #{rlink(q)._}) and " \
            "rlink(q) (= #{rlink(q)._}) != rover (= #{@rover}))."
          )
        end
        q = rlink(q)._
        i += 1
        break if q == @rover
      end
      # Undump memory area #2:
      @mem[p, @lo_mem_max + 1 - p] = \
        undump_bytes(fd, (@lo_mem_max + 1 - p) * @mem.t::SIZE)
      hexdump(
        "'mem' array, area #2 [#{p}, #{@lo_mem_max + 1})",
        @mem[p, @lo_mem_max + 1 - p]
      )
      # Make more low memory available:
      if @mem_min < @mem_bot - 2 then
        inform("making more low memory available", "...")
        p = llink(@rover)._
        q = @mem_min + 1
        link(@mem_min)._ = Defs::NULL
        info(@mem_min)._ = Defs::NULL
        rlink(p)._ = q
        llink(@rover)._ = q
        rlink(q)._ = @rover
        llink(q)._ = p
        link(q)._ = Defs::EMPTY_FLAG
        node_size(q)._ = @mem_bot - q
      end
      # Undump and check hi_mem_min:
      x = undump_int(fd)
      if x < @lo_mem_max + 1 or x > hi_mem_stat_min then
        raise BadFmtError.new(
          "'hi_mem_min' (#{x}) not in " \
          "[#{@lo_mem_max + 1}, #{hi_mem_stat_min}]."
        )
      end
      @hi_mem_min = x
      inform("'hi_mem_min' value", @hi_mem_min.to_s)
      hexdump("'hi_mem_min' value", i2b(x))
      # Undump and check avail:
      x = undump_int(fd)
      if x < Defs::NULL or x > @mem_top then
        raise BadFmtError.new \
          "'avail' (#{x}) not in [#{Defs::NULL}, #{@mem_top}]."
      end
      @avail = x
      inform("'avail' value", @avail.to_s)
      hexdump("'avail' value", i2b(x))
      @mem_end = @mem_top
      inform("'mem_end' value", @mem_end.to_s)
      # Undump memory area #3:
      @mem[@hi_mem_min, @mem_end + 1 - @hi_mem_min] = \
        undump_bytes(fd, (@mem_end + 1 - @hi_mem_min) * @mem.t::SIZE)
      hexdump(
        "'mem' array, area #3 [#{@hi_mem_min}, #{@mem_end + 1})",
        @mem[@hi_mem_min, @mem_end + 1 - @hi_mem_min]
      )
      # Undump var_used:
      @var_used = undump_int(fd)
      inform("'var_used' value", @var_used.to_s)
      hexdump("'var_used' value", i2b(@var_used))
      # Undump dyn_used:
      @dyn_used = undump_int(fd)
      inform("'dyn_used' value", @dyn_used.to_s)
      hexdump("'dyn_used' value", i2b(@dyn_used))
    end
    private :undump_dynamic_memory

    def undump_table_of_equivalents(fd)
      # Undump regions 1 to 6 of eqtb:
      k = Defs::ACTIVE_BASE
      i = 1
      loop do
        x = undump_int(fd)
        if x < 1 or k + x > Defs::EQTB_SIZE + 1 then
          raise BadFmtError.new(
            "'eqtb' undumping (iteration No. #{i}) failed at condition: " \
            "x (= #{x}) < 1 or " \
            "k (= #{x}) + x (= #{k + x}) > #{Defs::EQTB_SIZE + 1}"
          )
        end
        hexdump("Compressed block size", i2b(x))
        @eqtb[k, x] = undump_bytes(fd, x*@eqtb.t::SIZE)
        hexdump(
          "Compressed 'eqtb' array, part #{i} [#{k}, #{k + x})", @eqtb[k, x]
        )
        k = k + x
        x = undump_int(fd)
        if x < 0 or k + x > Defs::EQTB_SIZE + 1 then
          raise BadFmtError.new(
            "'eqtb' unpacking (iteration No. #{i}) failed at condition: " \
            "x (= #{x}) < 0 or " \
            "k (= #{x}) + x (= #{k + x}) > #{Defs::EQTB_SIZE + 1}"
          )
        end
        inform(
          "unpacking #{x} items of 'eqtb'",
          "eqtb[#{k}, #{k + x - 1}] <- eqtb[#{k - 1}]"
        )
        hexdump("Packed items", i2b(x))
        (k..(k + x - 1)).each {|j| @eqtb[j]._ = @eqtb[k - 1]._}
        k = k + x
        i += 1
        break if k > Defs::EQTB_SIZE
      end
      # Undumping hash_extra part (if exists):
      if @hash_high > 0 then
        @eqtb[Defs::EQTB_SIZE + 1, @hash_high] = \
          undump_bytes(fd, @hash_high*@eqtb.t::SIZE)
        hexdump("'eqtb' hash extra", @eqtb[Defs::EQTB_SIZE + 1, @hash_high])
      end
      # Undump and check par_loc:
      x = undump_int(fd)
      if x < Defs::HASH_BASE or x > @hash_top then
        raise BadFmtError.new \
          "'par_loc' (#{x}) is not in [#{Defs::HASH_BASE}, #{@hash_top}]"
      end
      @par_loc = x
      inform("'par_loc' value", @par_loc.to_s)
      hexdump("'par_loc' value", i2b(x))
      @par_token = Defs::CS_TOKEN_FLAG + @par_loc
      inform("'par_token' value", @par_token.to_s)
      # Undump and check write_loc:
      x = undump_int(fd)
      if x < Defs::HASH_BASE or x > @hash_top then
        raise BadFmtError.new \
          "'write_loc' (#{x}) is not in [#{Defs::HASH_BASE}, #{@hash_top}]"
      end
      @write_loc = x
      inform("'write_loc' value", @write_loc.to_s)
      hexdump("'write_loc' value", i2b(x))
      # Undump the hash table:
      @prim = CPascal::xmalloc_array(
        Types::TwoHalvesType, Defs::PRIM_SIZE + 1, 'prim'
      )
      @prim[0, Defs::PRIM_SIZE + 1] = \
        undump_bytes(fd, (Defs::PRIM_SIZE + 1) * @prim.t::SIZE)
      memstats(@prim)
      hexdump("'prim' array", @prim[0, Defs::PRIM_SIZE + 1])
      @prim_eqtb = CPascal::xmalloc_array(
        Types::MemoryWordType, Defs::PRIM_SIZE + 1, 'prim_eqtb'
      )
      @prim_eqtb[0, Defs::PRIM_SIZE + 1] = \
        undump_bytes(fd, (Defs::PRIM_SIZE + 1) * @prim.t::SIZE)
      memstats(@prim_eqtb)
      hexdump("'prim_eqtb' array", @prim_eqtb[0, Defs::PRIM_SIZE + 1])
      # Undump and check hash_used:
      x = undump_int(fd)
      if x < Defs::HASH_BASE or x > Defs::FROZEN_CONTROL_SEQUENCE then
        raise BadFmtError.new(
          "'hash_used' (#{x}) not in [#{Defs::HASH_BASE}, " \
          "#{Defs::FROZEN_CONTROL_SEQUENCE}]"
        )
      end
      @hash_used = x
      inform("'hash_used' value", @hash_used.to_s)
      hexdump("'hash_used' value", i2b(x))
      # Undump hash table data (#1):
      p = Defs::HASH_BASE - 1
      i = 1
      loop do
        x = undump_int(fd)
        if x < p + 1 or x > @hash_used then
          raise BadFmtError.new(
            "Invalid index to 'hash' array: #{x} not in [" \
              "#{p + 1}, #{@hash_used}" \
            "]"
          )
        end
        p = x
        hexdump("Index to 'hash' array", i2b(x))
        @hash[p, 1] = undump_bytes(fd, @hash.t::SIZE)
        hexdump("Hash item at #{p}", @hash[p, 1])
        i += 1
        break if p == @hash_used
      end
      inform("number of hash items undumped (#1)", i.to_s)
      # Undump hash table data (#2):
      @hash[
        @hash_used + 1, Defs::UNDEFINED_CONTROL_SEQUENCE - 1 - @hash_used
      ] = undump_bytes(
        fd, (Defs::UNDEFINED_CONTROL_SEQUENCE - 1 - @hash_used) * @hash.t::SIZE
      )
      inform(
        "number of hash items undumped (#2)",
        (Defs::UNDEFINED_CONTROL_SEQUENCE - 1 - @hash_used).to_s
      )
      hexdump("Rest of 'hash' array", @hash[
        @hash_used + 1, Defs::UNDEFINED_CONTROL_SEQUENCE - 1 - @hash_used
      ])
      # Undump hash extra data:
      if @hash_high > 0 then
        @hash[Defs::EQTB_SIZE + 1, @hash_high] = undump_bytes(
          fd, @hash_high * @hash.t::SIZE
        )
        hexdump(
          "Extra items of 'hash' array", @hash[Defs::EQTB_SIZE + 1, @hash_high]
        )
      end
      # Undump cs_count:
      @cs_count = undump_int(fd)
      inform("'cs_count' value", @cs_count.to_s)
      hexdump("'cs_count' value", i2b(@cs_count))
    end
    private :undump_table_of_equivalents

    def undump_font_info(fd)
      # Undump and check fmem_ptr:
      x = undump_int(fd)
      if x < 7 then
        raise BadFmtError.new("'fmem_ptr' < 7 (#{x}).")
      end
      if x > Defs::SUP_FONT_MEM_SIZE then
        raise BadFmtError.new(
          "Font mem size is too low. Set 'SUP_FONT_MEM_SIZE' to at least #{x}."
        )
      end
      @fmem_ptr = x
      inform("'fmem_ptr' value", @fmem_ptr.to_s)
      hexdump("'fmem_ptr' value", i2b(x))
      if @fmem_ptr > @font_mem_size then
        @font_mem_size = @fmem_ptr
      end
      # Undump font_info:
      @font_info = CPascal::xmalloc_array(
        Types::FMemoryWordType, @font_mem_size, 'font_info'
      )
      @font_info[0, @fmem_ptr] = undump_bytes(
        fd, @fmem_ptr * @font_info.t::SIZE
      )
      memstats(@font_info)
      hexdump("'font_info' array", @font_info[0, @fmem_ptr])
      # Undump and check font_ptr:
      x = undump_int(fd)
      if x < Defs::FONT_BASE then
        raise BadFmtError.new "'font_ptr' < #{Defs::FONT_BASE} (#{x})."
      end
      if x > Defs::FONT_BASE + Defs::MAX_FONT_MAX then
        raise BadFmtError.new(
          "'MAX_FONT_MAX' is too low. Set 'MAX_FONT_MAX' to at least " \
          "#{x - Defs::FONT_BASE}."
        )
      end
      @font_ptr = x
      inform("'font_ptr' value", @font_ptr.to_s)
      hexdump("'font_ptr' value", i2b(x))
      # Undump all font informations:
      # - allocate font arrays:
      @font_check = CPascal::xmalloc_array(
        Types::FourQuartersType, @font_max, 'font_check'
      )
      @font_size = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'font_size'
      )
      @font_dsize = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'font_dsize'
      )
      @font_params = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'font_params'
      )
      @font_name = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'font_name'
      )
      @font_area = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'font_area'
      )
      @font_bc = CPascal::xmalloc_array(
        CPascal::UnsignedCharType, @font_max, 'font_bc'
      )
      @font_ec = CPascal::xmalloc_array(
        CPascal::UnsignedCharType, @font_max, 'font_ec'
      )
      @font_glue = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'font_glue'
      )
      @hyphen_char = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'hyphen_char'
      )
      @skew_char = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'skew_char'
      )
      @bchar_label = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'bchar_label'
      )
      @font_bchar = CPascal::xmalloc_array(
        CPascal::ShortType, @font_max, 'font_bchar'
      )
      @font_false_bchar = CPascal::xmalloc_array(
        CPascal::ShortType, @font_max, 'font_false_bchar'
      )
      @char_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'char_base'
      )
      @width_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'width_base'
      )
      @height_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'height_base'
      )
      @depth_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'depth_base'
      )
      @italic_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'italic_base'
      )
      @lig_kern_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'lig_kern_base'
      )
      @kern_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'kern_base'
      )
      @exten_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'exten_base'
      )
      @param_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'param_base'
      )
      @pdf_char_used = CPascal::xmalloc_array(
        Types::CharUsedArrayType, @font_max, 'pdf_char_used'
      )
      @pdf_font_size = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_size'
      )
      @pdf_font_num = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_num'
      )
      @pdf_font_map = CPascal::xmalloc_array(
        CPascal::UnsignedIntType, @font_max, 'pdf_font_map'
      )
      @pdf_font_type = CPascal::xmalloc_array(
        CPascal::UnsignedCharType, @font_max, 'pdf_font_type'
      )
      @pdf_font_attr = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_attr'
      )
      @pdf_font_blink = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_blink'
      )
      @pdf_font_elink = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_elink'
      )
      @pdf_font_stretch = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_stretch'
      )
      @pdf_font_shrink = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_shrink'
      )
      @pdf_font_step = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_step'
      )
      @pdf_font_expand_ratio = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_expand_ratio'
      )
      @pdf_font_auto_expand = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_auto_expand'
      )
      @pdf_font_lp_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_lp_base'
      )
      @pdf_font_rp_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_rp_base'
      )
      @pdf_font_ef_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_ef_base'
      )
      @pdf_font_kn_bs_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_kn_bs_base'
      )
      @pdf_font_st_bs_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_st_bs_base'
      )
      @pdf_font_sh_bs_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_sh_bs_base'
      )
      @pdf_font_kn_bc_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_kn_bc_base'
      )
      @pdf_font_kn_ac_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_kn_ac_base'
      )
      @vf_packet_base = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'vf_packet_base'
      )
      @vf_default_font = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'vf_default_font'
      )
      @vf_local_font_num = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'vf_local_font_num'
      )
      @vf_e_fnts = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'vf_e_fnts'
      )
      @vf_i_fnts = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'vf_i_fnts'
      )
      @pdf_font_nobuiltin_tounicode = CPascal::xmalloc_array(
        CPascal::IntType, @font_max, 'pdf_font_nobuiltin_tounicode'
      )
      (Defs::FONT_BASE..@font_max).each do |font_k|
        (0..31).each {|k| @pdf_char_used[font_k][k]._ = 0}
        @pdf_font_size[font_k]._ = 0
        @pdf_font_num[font_k]._ = 0
        @pdf_font_map[font_k]._ = 0
        @pdf_font_type[font_k]._ = Defs::NEW_FONT_TYPE
        @pdf_font_attr[font_k]._ = s2i("")
        @pdf_font_blink[font_k]._ = Defs::NULL_FONT
        @pdf_font_elink[font_k]._ = Defs::NULL_FONT
        @pdf_font_stretch[font_k]._ = Defs::NULL_FONT
        @pdf_font_shrink[font_k]._ = Defs::NULL_FONT
        @pdf_font_step[font_k]._ = 0
        @pdf_font_expand_ratio[font_k]._ = 0
        @pdf_font_auto_expand[font_k]._ = 0
        @pdf_font_lp_base[font_k]._ = 0
        @pdf_font_rp_base[font_k]._ = 0
        @pdf_font_ef_base[font_k]._ = 0
        @pdf_font_kn_bs_base[font_k]._ = 0
        @pdf_font_st_bs_base[font_k]._ = 0
        @pdf_font_sh_bs_base[font_k]._ = 0
        @pdf_font_kn_bc_base[font_k]._ = 0
        @pdf_font_kn_ac_base[font_k]._ = 0
        @pdf_font_nobuiltin_tounicode[font_k]._ = 0
      end
      make_pdftex_banner
      # - do undump:
      @font_check[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_check.t::SIZE
        )
      memstats(@font_check)
      hexdump("'font_check' array",
        @font_check[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_size[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_size.t::SIZE
        )
      memstats(@font_size)
      hexdump("'font_size' array",
        @font_size[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_dsize[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_dsize.t::SIZE
        )
      memstats(@font_dsize)
      hexdump("'font_dsize' array",
        @font_dsize[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_params[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_params.t::SIZE
        )
      (Defs::NULL_FONT..@font_ptr).each do |i|
        x = @font_params[i]._
        if x < Defs::MIN_HALFWORD or x > Defs::MAX_HALFWORD then
          raise BadFmtError.new(
            "'font_params[#{i}]' is not in [" \
              "#{Defs::MIN_HALFWORD}" \
            ", " \
              "#{Defs::MAX_HALFWORD}" \
            "]."
          )
        end
      end
      memstats(@font_params)
      hexdump("'font_params' array",
        @font_params[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @hyphen_char[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @hyphen_char.t::SIZE
        )
      memstats(@hyphen_char)
      hexdump("'hyphen_char' array",
        @hyphen_char[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @skew_char[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @skew_char.t::SIZE
        )
      memstats(@skew_char)
      hexdump("'skew_char' array",
        @skew_char[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_name[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_name.t::SIZE
        )
      (Defs::NULL_FONT..@font_ptr).each do |i|
        x = @font_name[i]._
        if x > @str_ptr then
          raise BadFmtError.new(
            "'font_name[#{i}]' > #{@str_ptr} (#{x})."
          )
        end
      end
      memstats(@font_name)
      hexdump("'font_name' array",
        @font_name[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_area[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_area.t::SIZE
        )
      (Defs::NULL_FONT..@font_ptr).each do |i|
        x = @font_area[i]._
        if x > @str_ptr then
          raise BadFmtError.new(
            "'font_area[#{i}]' > #{@str_ptr} (#{x})."
          )
        end
      end
      memstats(@font_area)
      hexdump("'font_area' array",
        @font_area[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_bc[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_bc.t::SIZE
        )
      memstats(@font_bc)
      hexdump("'font_bc' array",
        @font_bc[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_ec[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_ec.t::SIZE
        )
      memstats(@font_ec)
      hexdump("'font_ec' array",
        @font_ec[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @char_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @char_base.t::SIZE
        )
      memstats(@char_base)
      hexdump("'char_base' array",
        @char_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @width_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @width_base.t::SIZE
        )
      memstats(@width_base)
      hexdump("'width_base' array",
        @width_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @height_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @height_base.t::SIZE
        )
      memstats(@height_base)
      hexdump("'height_base' array",
        @height_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @depth_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @depth_base.t::SIZE
        )
      memstats(@depth_base)
      hexdump("'depth_base' array",
        @depth_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @italic_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @italic_base.t::SIZE
        )
      memstats(@italic_base)
      hexdump("'italic_base' array",
        @italic_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @lig_kern_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @lig_kern_base.t::SIZE
        )
      memstats(@lig_kern_base)
      hexdump("'lig_kern_base' array",
        @lig_kern_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @kern_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @kern_base.t::SIZE
        )
      memstats(@kern_base)
      hexdump("'kern_base' array",
        @kern_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @exten_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @exten_base.t::SIZE
        )
      memstats(@exten_base)
      hexdump("'exten_base' array",
        @exten_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @param_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @param_base.t::SIZE
        )
      memstats(@param_base)
      hexdump("'param_base' array",
        @param_base[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_glue[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_glue.t::SIZE
        )
      (Defs::NULL_FONT..@font_ptr).each do |i|
        x = @font_glue[i]._
        if x < Defs::MIN_HALFWORD or x > @lo_mem_max then
          raise BadFmtError.new(
            "'font_glue[#{i}]' (#{x}) is not in [" \
              "#{Defs::MIN_HALFWORD}, #{@lo_mem_max}" \
            "]."
          )
        end
      end
      memstats(@font_glue)
      hexdump("'font_glue' array",
        @font_glue[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @bchar_label[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @bchar_label.t::SIZE
        )
      (Defs::NULL_FONT..@font_ptr).each do |i|
        x = @bchar_label[i]._
        if x < 0 or x > @fmem_ptr - 1 then
          raise BadFmtError.new(
            "'bchar_label[#{i}]' (#{x}) is not in [" \
              "0, #{@fmem_ptr - 1}" \
            "]."
          )
        end
      end
      memstats(@bchar_label)
      hexdump("'bchar_label' array",
        @bchar_label[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_bchar[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_bchar.t::SIZE
        )
      (Defs::NULL_FONT..@font_ptr).each do |i|
        x = @font_bchar[i]._
        if x < Defs::MIN_QUARTERWORD or x > non_char then
          raise BadFmtError.new(
            "'font_bchar[#{i}]' (#{x}) is not in [" \
              "#{Defs::MIN_QUARTERWORD}, #{non_char}" \
            "]."
          )
        end
      end
      memstats(@font_bchar)
      hexdump("'font_bchar' array",
        @font_bchar[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
      @font_false_bchar[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT] = \
        undump_bytes(
          fd, (@font_ptr + 1 - Defs::NULL_FONT) * @font_false_bchar.t::SIZE
        )
      (Defs::NULL_FONT..@font_ptr).each do |i|
        x = @font_false_bchar[i]._
        if x < Defs::MIN_QUARTERWORD or x > non_char then
          raise BadFmtError.new(
            "'font_false_bchar[#{i}]' (#{x}) is not in [" \
              "#{Defs::MIN_QUARTERWORD}, #{non_char}" \
            "]."
          )
        end
      end
      memstats(@font_false_bchar)
      hexdump("'font_false_bchar' array",
        @font_false_bchar[Defs::NULL_FONT, @font_ptr + 1 - Defs::NULL_FONT]
      )
    end
    private :undump_font_info

    def undump_hyphen_tables(fd)
      # Undump and check hyph_count:
      x = undump_int(fd)
      if x < 0 then
        raise BadFmtError.new "'hyph_count' (#{x}) < 0."
      end
      if x > @hyph_size then
        raise BadFmtError.new(
          "'hyph_size' is too small. It should be at least #{x}."
        )
      end
      @hyph_count = x
      inform("'hyph_count' value", @hyph_count.to_s)
      hexdump("'hyph_count' value", i2b(x))
      # Undump and check hyph_next:
      x = undump_int(fd)
      if x < Defs::HYPH_PRIME then
        raise BadFmtError.new "'hyph_next' (#{x}) < #{Defs::HYPH_PRIME}."
      end
      if x > @hyph_size then
        raise BadFmtError.new(
          "'hyph_size' is too small. It should be at least #{x}."
        )
      end
      @hyph_next = x
      inform("'hyph_next' value", @hyph_next.to_s)
      hexdump("'hyph_next' value", i2b(x))
      # Undump hyph_word, hyph_link, hyph_list:
      j = 0
      (1..@hyph_count).each do |k|
        j = undump_int(fd)
        if j < 0 then
          raise BadFmtError.new(
            "Hyphenation tables, phase #1, loop #{k}: j < 0 (#{j})."
          )
        end
        hexdump("Hyphenation tables, phase #1, loop #{k}, index 'j'", i2b(j))
        # if j > 65535 then
        #   @hyph_next = j/65536
        #   j = j - @hyph_next*65536
        # else
        #   @hyph_next = 0
        # end
        @hyph_next = j >> 16
        j &= 0xFFFF
        if j >= @hyph_size or @hyph_next > @hyph_size then
          raise BadFmtError.new(
            "Hyphenation tables, phase #1, loop #{k}: " \
            "j >= hyph_size (#{j}) or hyph_next > hyph_size (#{@hyph_next}) " \
            "(hyph_size = #{@hyph_size})."
          )
        end
        @hyph_link[j]._ = @hyph_next
        x = undump_int(fd)
        if x < 0 or x > @str_ptr then
          raise BadFmtError.new(
            "Hyphenation tables, phase #1, loop #{k}: " \
            "hyph_word[#{j}] (#{x}) is not in [" \
              "0, #{@str_ptr}" \
            "]."
          )
        end
        @hyph_word[j]._ = x
        hexdump("'hyph_word[#{j}]' value", i2b(x))
        x = undump_int(fd)
        if x < Defs::MIN_HALFWORD or x > Defs::MAX_HALFWORD then
          raise BadFmtError.new(
            "Hyphenation tables, phase #1, loop #{k}: " \
            "hyph_list[#{j}] (#{x}) is not in [" \
              "#{Defs::MIN_HALFWORD}, #{Defs::MAX_HALFWORD}" \
            "]."
          )
        end
        @hyph_list[j]._ = x
        hexdump("'hyph_list[#{j}]' value", i2b(x))
      end
      j += 1
      # Adjust hyph_next:
      if j < Defs::HYPH_PRIME then
        j = Defs::HYPH_PRIME
      end
      @hyph_next = j
      if @hyph_next >= @hyph_size then
        @hyph_next = Defs::HYPH_PRIME
      elsif @hyph_next >= Defs::HYPH_PRIME then
        @hyph_next += 1
      end
      # Undump and check next size j:
      x = undump_int(fd)
      if x < 0 then
        raise BadFmtError.new(
          "j < 0 (#{x})."
        )
      end
      if x > @trie_size then
        raise BadFmtError.new(
          "'trie_size' is too small. It should be at least #{x}."
        )
      end
      j = x
      hexdump("Hyphenation tables, phase #2 - size 'j'", i2b(x))
      @trie_max = j
      # Undump and check hyph_start:
      x = undump_int(fd)
      if x < 0 or x > j then
        raise BadFmtError.new(
          "'hyph_start' (#{x}) is not in [0, #{j}]."
        )
      end
      @hyph_start = x
      inform("'hyph_start' value", @hyph_start.to_s)
      hexdump("'hyph_start' value", i2b(x))
      # Allocate and undump trie_trl, trie_tro, trie_trc:
      @trie_trl = CPascal::xmalloc_array(
        CPascal::IntType, j + 1, 'trie_trl'
      )
      @trie_trl[0, j + 1] = undump_bytes(
        fd, (j + 1)*@trie_trl.t::SIZE
      )
      memstats(@trie_trl)
      hexdump("'trie_trl' array", @trie_trl[0, j + 1])
      @trie_tro = CPascal::xmalloc_array(
        CPascal::IntType, j + 1, 'trie_tro'
      )
      @trie_tro[0, j + 1] = undump_bytes(
        fd, (j + 1)*@trie_tro.t::SIZE
      )
      memstats(@trie_tro)
      hexdump("'trie_tro' array", @trie_tro[0, j + 1])
      @trie_trc = CPascal::xmalloc_array(
        CPascal::UnsignedCharType, j + 1, 'trie_trc'
      )
      @trie_trc[0, j + 1] = undump_bytes(
        fd, (j + 1)*@trie_trc.t::SIZE
      )
      memstats(@trie_trc)
      hexdump("'trie_trc' array", @trie_trc[0, j + 1])
      # Undump and check last size j:
      x = undump_int(fd)
      if x < 0 then
        raise BadFmtError.new(
          "j < 0 (#{x})."
        )
      end
      if x > Defs::TRIE_OP_SIZE then
        raise BadFmtError.new(
          "'TRIE_OP_SIZE' is too small. It should be at least #{x}."
        )
      end
      j = x
      hexdump("Hyphenation tables, phase #3 - size 'j'", i2b(x))
      @trie_op_ptr = j
      # Undump hyf_distance, hyf_num, hyf_next:
      @hyf_distance[1, j] = undump_bytes(fd, j*@hyf_distance.t::SIZE)
      hexdump("'hyf_distance' array", @hyf_distance[1, j])
      @hyf_num[1, j] = undump_bytes(fd, j*@hyf_num.t::SIZE)
      hexdump("'hyf_num' array", @hyf_num[1, j])
      @hyf_next[1, j] = undump_bytes(fd, j*@hyf_next.t::SIZE)
      (1..j).each do |i|
        x = @hyf_next[i]._
        if x > Defs::MAX_TRIE_OP then
          raise BadFmtError.new(
            "'hyf_next[#{i}]' (#{x}) > MAX_TRIE_OP."
          )
        end
      end
      hexdump("'hyf_next' array", @hyf_next[1, j])
      # Initialize trie_used and op_start:
      (0..255).each do |k|
        @trie_used[k]._ = Defs::MIN_QUARTERWORD
      end
      @op_start[0]._ = -Defs::MIN_TRIE_OP
      (1..255).each do |j|
        @op_start[j]._ = @op_start[j - 1]._ + qo(@trie_used[j - 1]._)
      end
      k = 256
      while j > 0 do
        x = undump_int(fd)
        if x < 0 or x > k - 1 then
          raise BadFmtError.new(
            "Hyphenation tables, phase #4 (trie_used, op_start), j = #{j}: " \
            "k (#{x}) is not in [0, #{k - 1}]."
          )
        end
        k = x
        hexdump("Hyphenation tables, phase #4, j = #{j}, index 'k'", i2b(x))
        x = undump_int(fd)
        if x < 1 or x > j then
          raise BadFmtError.new(
            "Hyphenation tables, phase #4 (trie_used, op_start), j = #{j}: " \
            "x (#{x}) is not in [1, #{j}]."
          )
        end
        hexdump("Hyphenation tables, phase #4, j = #{j}, value 'x'", i2b(x))
        @trie_used[k]._ = qi(x)
        j -= x
        @op_start[k]._ = qo(j)
      end
      @trie_not_ready = false
    end
    private :undump_hyphen_tables

    def undump_pdftex_data(fd)
      # Undump image metadata:
      undump_image_meta(fd, pdf_minor_version._, pdf_inclusion_errorlevel._)
      # Undump pdf memory size:
      @pdf_mem_size = undump_int(fd)
      inform("'pdf_mem_size' value", @pdf_mem_size.to_s)
      hexdump("'pdf_mem_size' value", i2b(@pdf_mem_size))
      # Allocate pdf memory
      @pdf_mem = CPascal::xmalloc_array(
        CPascal::IntType, @pdf_mem_size, 'pdf_mem'
      )
      # Undump pointer to the pdf memory:
      @pdf_mem_ptr = undump_int(fd)
      inform("'pdf_mem_ptr' value", @pdf_mem_ptr.to_s)
      hexdump("'pdf_mem_ptr' value", i2b(@pdf_mem_ptr))
      # Undump pdf memory content:
      (1..(@pdf_mem_ptr - 1)).each do |k|
        @pdf_mem[k]._ = undump_int(fd)
        inform("'pdf_mem[#{k}]' value", @pdf_mem[k]._.to_s)
        hexdump("'pdf_mem[#{k}]' value", i2b(@pdf_mem[k]._))
      end
      memstats(@pdf_mem)
      # Undump object table size:
      @obj_tab_size = undump_int(fd)
      inform("'obj_tab_size' value", @obj_tab_size.to_s)
      hexdump("'obj_tab_size' value", i2b(@obj_tab_size))
      # Undump object pointer:
      @obj_ptr = undump_int(fd)
      inform("'obj_ptr' value", @obj_ptr.to_s)
      hexdump("'obj_ptr' value", i2b(@obj_ptr))
      # Undump system object pointer:
      @sys_obj_ptr = undump_int(fd)
      inform("'sys_obj_ptr' value", @sys_obj_ptr.to_s)
      hexdump("'sys_obj_ptr' value", i2b(@sys_obj_ptr))
      # Undump object table:
      (1..@sys_obj_ptr).each do |k|
        @obj_tab[k].int0._ = undump_int(fd)
        hexdump("'obj_tab[#{k}].int0' value", i2b(@obj_tab[k].int0._))
        @obj_tab[k].int1._ = undump_int(fd)
        hexdump("'obj_tab[#{k}].int1' value", i2b(@obj_tab[k].int1._))
        @obj_tab[k].int2._ = -1
        @obj_tab[k].int3._ = undump_int(fd)
        hexdump("'obj_tab[#{k}].int3' value", i2b(@obj_tab[k].int3._))
        @obj_tab[k].int4._ = undump_int(fd)
        hexdump("'obj_tab[#{k}].int4' value", i2b(@obj_tab[k].int4._))
      end
      memstats(@obj_tab)
      # Undump PDF object count:
      @pdf_obj_count = undump_int(fd)
      inform("'pdf_obj_count' value", @pdf_obj_count.to_s)
      hexdump("'pdf_obj_count' value", i2b(@pdf_obj_count))
      # Undump PDF x-form count:
      @pdf_xform_count = undump_int(fd)
      inform("'pdf_xform_count' value", @pdf_xform_count.to_s)
      hexdump("'pdf_xform_count' value", i2b(@pdf_xform_count))
      # Undump PDF x-image count:
      @pdf_ximage_count = undump_int(fd)
      inform("'pdf_ximage_count' value", @pdf_ximage_count.to_s)
      hexdump("'pdf_ximage_count' value", i2b(@pdf_ximage_count))
      # Undump header table items:
      @head_tab[Defs::OBJ_TYPE_OBJ]._ = undump_int(fd)
      inform(
        "'head_tab[OBJ_TYPE_OBJ]' value", @head_tab[Defs::OBJ_TYPE_OBJ]._.to_s
      )
      hexdump(
        "'head_tab[OBJ_TYPE_OBJ]' value", i2b(@head_tab[Defs::OBJ_TYPE_OBJ]._)
      )
      @head_tab[Defs::OBJ_TYPE_XFORM]._ = undump_int(fd)
      inform(
        "'head_tab[OBJ_TYPE_XFORM]' value",
        @head_tab[Defs::OBJ_TYPE_XFORM]._.to_s
      )
      hexdump(
        "'head_tab[OBJ_TYPE_XFORM]' value",
        i2b(@head_tab[Defs::OBJ_TYPE_XFORM]._)
      )
      @head_tab[Defs::OBJ_TYPE_XIMAGE]._ = undump_int(fd)
      inform(
        "'head_tab[OBJ_TYPE_XIMAGE]' value",
        @head_tab[Defs::OBJ_TYPE_XIMAGE]._.to_s
      )
      hexdump(
        "'head_tab[OBJ_TYPE_XIMAGE]' value",
        i2b(@head_tab[Defs::OBJ_TYPE_XIMAGE]._)
      )
      memstats(@head_tab)
      # Undump PDF last object:
      @pdf_last_obj = undump_int(fd)
      inform("'pdf_last_obj' value", @pdf_last_obj.to_s)
      hexdump("'pdf_last_obj' value", i2b(@pdf_last_obj))
      # Undump PDF last x-form:
      @pdf_last_xform = undump_int(fd)
      inform("'pdf_last_xform' value", @pdf_last_xform.to_s)
      hexdump("'pdf_last_xform' value", i2b(@pdf_last_xform))
      # Undump PDF last x-image:
      @pdf_last_ximage = undump_int(fd)
      inform("'pdf_last_ximage' value", @pdf_last_ximage.to_s)
      hexdump("'pdf_last_ximage' value", i2b(@pdf_last_ximage))
    end
    private :undump_pdftex_data

    def undump_image_meta(fd, pdfversion, pdfinclusionerrorlevel)
      # Undump image limit:
      @image_limit = undump_int(fd)
      inform("'image_limit' value", @image_limit.to_s)
      hexdump("'image_limit' value", i2b(@image_limit))
      @image_array = []
      # Undump current image:
      @cur_image = undump_int(fd)
      inform("'cur_image' value", @cur_image.to_s)
      hexdump("'cur_image' value", i2b(@cur_image))
      # Undump informations for each image:
      (0..(@cur_image - 1)).each do |img|
        @image_array[img] = Types::ImageStructType.new
        # - undump image name:
        nchars = undump_int(fd)
        hexdump("Image {#img} name length", i2b(nchars))
        s = undump_bytes(fd, nchars)
        hexdump("Image {#img} name", s)
        @image_array[img].image_name = s.chomp "\x00"
        inform("image {#img} name", @image_array[img].image_name)
        # - undump image type:
        @image_array[img].image_type = undump_int(fd)
        inform("image {#img} type", @image_array[img].image_type.to_s)
        hexdump("Image {#img} type", i2b(@image_array[img].image_type))
        # - undump color type:
        @image_array[img].color_type = undump_int(fd)
        inform("image {#img} color type", @image_array[img].color_type.to_s)
        hexdump("Image {#img} color type", i2b(@image_array[img].color_type))
        # - undump image width:
        @image_array[img].width = undump_int(fd)
        inform("image {#img} width", @image_array[img].width.to_s)
        hexdump("Image {#img} width", i2b(@image_array[img].width))
        # - undump image height:
        @image_array[img].height = undump_int(fd)
        inform("image {#img} height", @image_array[img].height.to_s)
        hexdump("Image {#img} height", i2b(@image_array[img].height))
        # - undump x resolution:
        @image_array[img].x_res = undump_int(fd)
        inform("image {#img} x-res", @image_array[img].x_res.to_s)
        hexdump("Image {#img} x-res", i2b(@image_array[img].x_res))
        # - undump y resolution:
        @image_array[img].y_res = undump_int(fd)
        inform("image {#img} y-res", @image_array[img].y_res.to_s)
        hexdump("Image {#img} y-res", i2b(@image_array[img].y_res))
        # - undump the number of pages:
        @image_array[img].num_pages = undump_int(fd)
        inform(
          "image {#img} number of pages",
          @image_array[img].num_pages.to_s
        )
        hexdump(
          "Image {#img} number of pages",
          i2b(@image_array[img].num_pages)
        )
        # - undump color space reference:
        @image_array[img].colorspace_ref = undump_int(fd)
        inform(
          "image {#img} color space reference",
          @image_array[img].colorspace_ref.to_s
        )
        hexdump(
          "Image {#img} color space reference",
          i2b(@image_array[img].colorspace_ref)
        )
        # - undump group reference:
        @image_array[img].group_ref = undump_int(fd)
        inform(
          "image {#img} group reference",
          @image_array[img].group_ref.to_s
        )
        hexdump(
          "Image {#img} group reference",
          i2b(@image_array[img].group_ref)
        )
        case @image_array[img].image_type
          when Defs::IMAGE_TYPE_PDF
            # - undump page box if image is PDF:
            @image_array[img].page_box = undump_int(fd)
            inform(
              "(PDF) image {#img} page box",
              @image_array[img].page_box.to_s
            )
            hexdump(
              "(PDF) image {#img} page box",
              i2b(@image_array[img].page_box)
            )
            # - undump selected page:
            @image_array[img].selected_page = undump_int(fd)
            inform(
              "(PDF) image {#img} selected page",
              @image_array[img].selected_page.to_s
            )
            hexdump(
              "(PDF) image {#img} selected page",
              i2b(@image_array[img].selected_page)
            )
          when Defs::IMAGE_TYPE_PNG, Defs::IMAGE_TYPE_JPG
            nil
          when Defs::IMAGE_TYPE_JBIG2
            # - undump selected page if image is JBIG2:
            @image_array[img].selected_page = undump_int(fd)
            inform(
              "(JBIG2) image {#img} selected page",
              @image_array[img].selected_page.to_s
            )
            hexdump(
              "(JBIG2) image {#img} selected page",
              i2b(@image_array[img].selected_page)
            )
        else
          raise BadFmtError.new(
            "Image #{img}: " \
            "Unsupported image type #{@image_array[img].image_type}."
          )
        end
      end
    end
    private :undump_image_meta

    def undump_last_things(fd)
      # Undump and check interaction:
      x = undump_int(fd)
      if x < Defs::BATCH_MODE or x > Defs::ERROR_STOP_MODE then
        raise BadFmtError.new(
          "'interaction' (#{x}) is not in [" \
            "#{Defs::BATCH_MODE}, #{Defs::ERROR_STOP_MODE}" \
          "]."
        )
      end
      @interaction = x
      inform("'interaction' value", @interaction.to_s)
      hexdump("'interaction' value", i2b(x))
      # Undump and check format_ident:
      x = undump_int(fd)
      if x < 0 or x > @str_ptr then
        raise BadFmtError.new(
          "'format_ident' (#{x}) is not in [0, #{@str_ptr}]."
        )
      end
      @format_ident = x
      inform("'format_ident' value", @format_ident.to_s)
      hexdump("'format_ident' value", i2b(x))
      # Undump and check .fmt file trailer:
      x = undump_int(fd)
      if x != 69069 then
        raise BadFmtError.new(
          "Bad .fmt file trailer value (#{x})."
        )
      end
      hexdump("Trailer", i2b(x))
    end
    private :undump_last_things

    def undump_int(fd)
      nread(fd, 4).unpack(CPascal::IntType::UNPACKER)[0]
    end
    private :undump_int

    def undump_bytes(fd, n)
      nread(fd, n)
    end
    private :undump_bytes

    def nread(fd, n)
      begin
        bs = fd.sysread(n)
        if bs.size != n
          raise
        end
        @percentil = (fd.tell * @percmax)/@fsize
        if @percentil > @oldperc
          @oldperc = @percentil
          @owner.signal :progress, @percentil
        end
        return bs
      rescue
        raise IOError.new "read #{n} bytes."
      end
    end
    private :nread

    # -------------------------------------------------------------------------
    # -- Reporting interface
    # --
    def alert(fmtfd, details)
      msg = "Loading pdfTeX format file \""
      msg << fmtfd.path
      msg << "\" failed near offset "
      msg << ("%08X" % fmtfd.tell)
      msg << "."
      if details[:reason]
        msg << "\nReason: " << details[:reason]
      end
      if details[:detail]
        msg << "\nDetail: " << details[:detail]
      end
      @owner.alert msg
    end
    private :alert

    def inform(l, x)
      wterm_ln("- #{l}: #{x}")
    end
    private :inform

    def memstats(p)
      wterm_ln("- '#{p.mem.name}' statistics:")
      wterm_ln("  + cell type: #{p.t.to_s}")
      wterm_ln("  + cell size (bytes): #{p.t::SIZE}")
      wterm_ln("  + allocated space (cells): #{p.mem.size/p.t::SIZE}")
      wterm_ln("  + allocated space (bytes): #{p.mem.size}")
      wterm_ln("  + base offset (cells): #{p.base}")
      wterm_ln("  + base offset (bytes): #{p.base*p.t::SIZE}")
    end
    private :memstats

    def hexdump(l, x)
      @owner.signal :xv_label, ""
      @owner.signal :xv_label, (l << ":")
      @owner.signal :xv_send, x
      @owner.signal :xv_flush
    end
    private :hexdump

    # {34}:
    def update_terminal
      @owner.signal :log_end
      @owner.signal :log_refresh
    end
    private :update_terminal

    def clear_terminal
    end
    private :clear_terminal

    def wake_up_terminal
      @owner.signal :log_start
    end
    private :wake_up_terminal

    # {56}:
    def wterm(x)
      @owner.signal :log_write, x
    end
    #private :wterm

    def wterm_ln(x)
      @owner.signal :log_write, x
      @owner.signal :log_write, "\n"
    end
    #private :wterm_ln

    def wterm_cr
      @owner.signal :log_write, "\n"
    end
    #private :wterm_cr

    def wlog(x)
      @owner.signal :log_write, x
    end
    private :wlog

    def wlog_ln(x)
      @owner.signal :log_write, x
      @owner.signal :log_write, "\n"
    end
    private :wlog_ln

    def wlog_cr
      @owner.signal :log_write, "\n"
    end
    private :wlog_cr

    def status(msg)
      @owner.signal :status, msg
      @owner.signal :update
    end
    private :status

    # -------------------------------------------------------------------------
    # -- Printing
    # --
    def print_ln
      wterm_cr
    end
    #private :print_ln

    def print_char(s)
      if s == new_line_char._ then
        print_ln
        return
      end
      wterm(@xchr[s])
    end
    #private :print_char

    def print(s, use_print_char = true)
      if s >= @str_ptr then
        @owner.alert "print(s): s (#{s}) >= str_ptr (#{@str_ptr})."
        return
      end
      if s < 0 then
        @owner.alert "print(s): s (#{s}) < 0."
        return
      end
      if s < 256 then
        if use_print_char then
          print_char(s)
          return
        end
        j = @str_start[s]._
        while j < @str_start[s + 1]._ do
          print_char(so(@str_pool[j]._))
          j += 1
        end
        return
      end
      j = @str_start[s]._
      while j < @str_start[s + 1]._ do
        print_char(so(@str_pool[j]._))
        j += 1
      end
    end
    #private :print

    # {60}:
    def slow_print(s, use_print_char = true)
      if s >= @str_ptr or s < 256 then
        print(s, use_print_char)
        return
      end
      j = @str_start[s]._
      while j < @str_start[s + 1]._ do
        print(so(@str_pool[j]._), use_print_char)
        j += 1
      end
    end
    #private :slow_print

    # {62}:
    def print_nl(s, use_print_char = true)
      print_ln
      print(s, use_print_char)
    end
    #private :print_nl

    # {63}:
    def print_esc(s, use_print_char = true)
      print(92, use_print_char)
      slow_print(s, use_print_char)
    end
    #private :print_esc

    # {64}:
    def print_the_digs(k, digs)
      while k > 0 do
        k -= 1
        if digs[k] < 10 then
          print_char("0".ord + digs[k])
        else
          print_char("A".ord - 10 + digs[k])
        end
      end
    end
    private :print_the_digs

    # {65}:
    def print_int(n)
      k = 0
      digs = []
      if n < 0
        print_char("-".ord)
        if n > -100000000
          n = negate(n)
        else
          m = -1 - n
          n = m / 10
          m = m % 10 + 1
          k = 1
          if m < 10
            digs[0] = m
          else
            digs[0] = 0
            n += 1
          end
        end
      end
      loop do
        digs[k] = n % 10
        n = n / 10
        k += 1
        break if n == 0
      end
      print_the_digs(k, digs)
    end
    #private :print_int

    # {66}:
    def print_two(n)
      n = n.abs % 100
      print_char("0".ord + n / 10)
      print_char("0".ord + n % 10)
    end
    private :print_two

    # {67}:
    def print_hex(n)
      k = 0
      digs = []
      print_char("\"".ord)
      loop do
        digs[k] = n % 16
        n = n / 16
        k += 1
        break if n == 0
      end
      print_the_digs(k, digs)
    end
    #private :print_hex

    # {68}:
    def print_ASCII(s, use_print_char = true)
      print(s, use_print_char)
    end
    #private :print_ASCII

    # {69}:
    def print_roman_int(n)
      j = @str_start[s2i("m2d5c2l5x2v5i")]._
      v = 1000
      loop do
        while n >= v do
          print_char(so(@str_pool[j]._))
          n -= v
        end
        if n <= 0 then
          return
        end
        k = j + 2
        u = v / (so(@str_pool[k - 1]._) - "0".ord)
        if @str_pool[k - 1]._ == si("2".ord) then
          k += 2
          u /= so(@str_pool[k - 1]._) - "0".ord
        end
        if n + u >= v then
          print_char(so(@str_pool[k]._))
          n += u
        else
          j += 2
          v /= so(@str_pool[j - 1]._) - "0".ord
        end
      end
    end
    #private :print_roman_int

    # {103}:
    def print_scaled(s)
      if s < 0 then
        print_char("-".ord)
        s = negate(s)
      end
      print_int(s / Defs::UNITY)
      print_char(".".ord)
      s = 10*(s % Defs::UNITY) + 5
      delta = 10
      loop do
        if delta > Defs::UNITY then
          s += 0100000 - 50000
        end
        print_char("0".ord + s / Defs::UNITY)
        s = 10*(s % Defs::UNITY)
        delta *= 10
        break if s <= delta
      end
    end
    #private :print_scaled

    # {192}:
    def print_font_identifier(f, indent = "")
      # id_text
      wterm(indent)
      if @pdf_font_blink[f]._ == Defs::NULL_FONT then
        wterm("id_text(#{f}): \"")
        print(font_id_text(f)._, false)
      else
        wterm("id_text(pdf_font_blink[#{f}] = #{@pdf_font_blink[f]._}): \"")
        print(font_id_text(@pdf_font_blink[f]._)._, false)
      end
      wterm_ln("\"")
      # name
      wterm(indent + "name(#{f}): \"")
      print(@font_name[f]._, false)
      wterm_ln("\"")
      # area
      area = @font_area[f]._
      wterm(indent + "area(#{f}): ")
      if area > 0 and area < @str_ptr then
        wterm("\"")
        print(area, false)
        wterm("\"")
      else
        wterm("#{area}")
      end
      wterm_cr
      # "at" size
      wterm(indent + "at_size(#{f}): ")
      print_scaled(@font_size[f]._)
      wterm_ln("pt")
      # "design" size
      wterm(indent + "design_size(#{f}): ")
      print_scaled(@font_dsize[f]._)
      wterm_ln("pt")
      # expand ratio
      wterm(indent + "pdf_font_expand_ratio(#{f}): ")
      if @pdf_font_expand_ratio[f]._ > 0 then
        wterm("+")
      end
      print_int(@pdf_font_expand_ratio[f]._)
      wterm_cr
    end
    #private :print_font_identifier

    # {194}:
    def print_font_and_char(p, indent = "")
      if p > @mem_end then
        wterm_ln(indent + "CLOBBERED.")
      elsif font(p)._ > @font_max then
        wterm_ln(indent + "*** BAD FONT LOCATION (#{p}) ***")
      else
        wterm_ln(indent + "Font {")
        print_font_identifier(font(p)._, indent + "  ")
        wterm_ln(indent + "}")
        wterm(indent + "Character: '")
        print_ASCII(qo(character(p)._), false)
        wterm_ln("'")
      end
    end
    #private :print_font_and_char

    def print_rule_dimen(d)
      if is_running(d) then
        wterm("<running dimension>")
      else
        print_scaled(d)
      end
    end
    #private :print_rule_dimen

    # {195}:
    def print_glue(d, order, s)
      print_scaled(d)
      if order < Defs::NORMAL or order > Defs::FILLL then
        print(s2i("foul"), false)
      elsif order > Defs::NORMAL then
        print(s2i("fil"), false)
        while order > Defs::FIL do
          print_char("l".ord)
          order -= 1
        end
      elsif s != 0 then
        print(s, false)
      end
    end
    #private :print_glue

    # {196}:
    def print_spec(p, s)
      if p < @mem_min or p >= @lo_mem_max then
        print_char("*".ord)
      else
        #puts "width(#{p.to_s(16)}) = #{width(p)._.to_s(16)}"
        #puts "stretch(#{p.to_s(16)}) = #{stretch(p)._.to_s(16)}"
        #puts "shrink(#{p.to_s(16)}) = #{shrink(p)._.to_s(16)}"
        print_scaled(width(p)._)
        if s != 0 then
          print(s, false)
        end
        if stretch(p)._ != 0 then
          print(s2i(" plus "), false)
          print_glue(stretch(p)._, stretch_order(p)._, s)
        end
        if shrink(p)._ != 0 then
          print(s2i(" minus "), false)
          print_glue(shrink(p)._, shrink_order(p)._, s)
        end
      end
    end
    #private :print_spec

    # {243}:
    def print_skip_param(n)
      case n
        when Defs::LINE_SKIP_CODE
          print_esc(s2i("lineskip"))
        when Defs::BASELINE_SKIP_CODE
          print_esc(s2i("baselineskip"))
        when Defs::PAR_SKIP_CODE
          print_esc(s2i("parskip"))
        when Defs::ABOVE_DISPLAY_SKIP_CODE
          print_esc(s2i("abovedisplayskip"))
        when Defs::BELOW_DISPLAY_SKIP_CODE
          print_esc(s2i("belowdisplayskip"))
        when Defs::ABOVE_DISPLAY_SHORT_SKIP_CODE
          print_esc(s2i("abovedisplayshortskip"))
        when Defs::BELOW_DISPLAY_SHORT_SKIP_CODE
          print_esc(s2i("belowdisplayshortskip"))
        when Defs::LEFT_SKIP_CODE
          print_esc(s2i("leftskip"))
        when Defs::RIGHT_SKIP_CODE
          print_esc(s2i("rightskip"))
        when Defs::TOP_SKIP_CODE
          print_esc(s2i("topskip"))
        when Defs::SPLIT_TOP_SKIP_CODE
          print_esc(s2i("splittopskip"))
        when Defs::TAB_SKIP_CODE
          print_esc(s2i("tabskip"))
        when Defs::SPACE_SKIP_CODE
          print_esc(s2i("spaceskip"))
        when Defs::XSPACE_SKIP_CODE
          print_esc(s2i("xspaceskip"))
        when Defs::PAR_FILL_SKIP_CODE
          print_esc(s2i("parfillskip"))
        when Defs::THIN_MU_SKIP_CODE
          print_esc(s2i("thinmuskip"))
        when Defs::MED_MU_SKIP_CODE
          print_esc(s2i("medmuskip"))
        when Defs::THICK_MU_SKIP_CODE
          print_esc(s2i("thickmuskip"))
        else
          print(s2i("[unknown glue parameter!]"), false)
      end
    end
    #private :print_skip_param

    # {255}:
    def print_param(n)
      case n
        when Defs::PRETOLERANCE_CODE
          print_esc(s2i("pretolerance"), false)
        when Defs::TOLERANCE_CODE
          print_esc(s2i("tolerance"), false)
        when Defs::LINE_PENALTY_CODE
          print_esc(s2i("linepenalty"), false)
        when Defs::HYPHEN_PENALTY_CODE
          print_esc(s2i("hyphenpenalty"), false)
        when Defs::EX_HYPHEN_PENALTY_CODE
          print_esc(s2i("exhyphenpenalty"), false)
        when Defs::CLUB_PENALTY_CODE
          print_esc(s2i("clubpenalty"), false)
        when Defs::WIDOW_PENALTY_CODE
          print_esc(s2i("widowpenalty"), false)
        when Defs::DISPLAY_WIDOW_PENALTY_CODE
          print_esc(s2i("displaywidowpenalty"), false)
        when Defs::BROKEN_PENALTY_CODE
          print_esc(s2i("brokenpenalty"), false)
        when Defs::BIN_OP_PENALTY_CODE
          print_esc(s2i("binoppenalty"), false)
        when Defs::REL_PENALTY_CODE
          print_esc(s2i("relpenalty"), false)
        when Defs::PRE_DISPLAY_PENALTY_CODE
          print_esc(s2i("predisplaypenalty"), false)
        when Defs::POST_DISPLAY_PENALTY_CODE
          print_esc(s2i("postdisplaypenalty"), false)
        when Defs::INTER_LINE_PENALTY_CODE
          print_esc(s2i("interlinepenalty"), false)
        when Defs::DOUBLE_HYPHEN_DEMERITS_CODE
          print_esc(s2i("doublehyphendemerits"), false)
        when Defs::FINAL_HYPHEN_DEMERITS_CODE
          print_esc(s2i("finalhyphendemerits"), false)
        when Defs::ADJ_DEMERITS_CODE
          print_esc(s2i("adjdemerits"), false)
        when Defs::MAG_CODE
          print_esc(s2i("mag"), false)
        when Defs::DELIMITER_FACTOR_CODE
          print_esc(s2i("delimiterfactor"), false)
        when Defs::LOOSENESS_CODE
          print_esc(s2i("looseness"), false)
        when Defs::TIME_CODE
          print_esc(s2i("time"), false)
        when Defs::DAY_CODE
          print_esc(s2i("day"), false)
        when Defs::MONTH_CODE
          print_esc(s2i("month"), false)
        when Defs::YEAR_CODE
          print_esc(s2i("year"), false)
        when Defs::SHOW_BOX_BREADTH_CODE
          print_esc(s2i("showboxbreadth"), false)
        when Defs::SHOW_BOX_DEPTH_CODE
          print_esc(s2i("showboxdepth"), false)
        when Defs::HBADNESS_CODE
          print_esc(s2i("hbadness"), false)
        when Defs::VBADNESS_CODE
          print_esc(s2i("vbadness"), false)
        when Defs::PAUSING_CODE
          print_esc(s2i("pausing"), false)
        when Defs::TRACING_ONLINE_CODE
          print_esc(s2i("tracingonline"), false)
        when Defs::TRACING_MACROS_CODE
          print_esc(s2i("tracingmacros"), false)
        when Defs::TRACING_STATS_CODE
          print_esc(s2i("tracingstats"), false)
        when Defs::TRACING_PARAGRAPHS_CODE
          print_esc(s2i("tracingparagraphs"), false)
        when Defs::TRACING_PAGES_CODE
          print_esc(s2i("tracingpages"), false)
        when Defs::TRACING_OUTPUT_CODE
          print_esc(s2i("tracingoutput"), false)
        when Defs::TRACING_LOST_CHARS_CODE
          print_esc(s2i("tracinglostchars"), false)
        when Defs::TRACING_COMMANDS_CODE
          print_esc(s2i("tracingcommands"), false)
        when Defs::TRACING_RESTORES_CODE
          print_esc(s2i("tracingrestores"), false)
        when Defs::UC_HYPH_CODE
          print_esc(s2i("uchyph"), false)
        when Defs::OUTPUT_PENALTY_CODE
          print_esc(s2i("outputpenalty"), false)
        when Defs::MAX_DEAD_CYCLES_CODE
          print_esc(s2i("maxdeadcycles"), false)
        when Defs::HANG_AFTER_CODE
          print_esc(s2i("hangafter"), false)
        when Defs::FLOATING_PENALTY_CODE
          print_esc(s2i("floatingpenalty"), false)
        when Defs::GLOBAL_DEFS_CODE
          print_esc(s2i("globaldefs"), false)
        when Defs::CUR_FAM_CODE
          print_esc(s2i("fam"), false)
        when Defs::ESCAPE_CHAR_CODE
          print_esc(s2i("escapechar"), false)
        when Defs::DEFAULT_HYPHEN_CHAR_CODE
          print_esc(s2i("defaulthyphenchar"), false)
        when Defs::DEFAULT_SKEW_CHAR_CODE
          print_esc(s2i("defaultskewchar"), false)
        when Defs::END_LINE_CHAR_CODE
          print_esc(s2i("endlinechar"), false)
        when Defs::NEW_LINE_CHAR_CODE
          print_esc(s2i("newlinechar"), false)
        when Defs::LANGUAGE_CODE
          print_esc(s2i("language"), false)
        when Defs::LEFT_HYPHEN_MIN_CODE
          print_esc(s2i("lefthyphenmin"), false)
        when Defs::RIGHT_HYPHEN_MIN_CODE
          print_esc(s2i("righthyphenmin"), false)
        when Defs::HOLDING_INSERTS_CODE
          print_esc(s2i("holdinginserts"), false)
        when Defs::ERROR_CONTEXT_LINES_CODE
          print_esc(s2i("errorcontextlines"), false)
        when Defs::CHAR_SUB_DEF_MIN_CODE
          print_esc(s2i("charsubdefmin"), false)
        when Defs::CHAR_SUB_DEF_MAX_CODE
          print_esc(s2i("charsubdefmax"), false)
        when Defs::TRACING_CHAR_SUB_DEF_CODE
          print_esc(s2i("tracingcharsubdef"), false)
        when Defs::MUBYTE_IN_CODE
          print_esc(s2i("mubytein"), false)
        when Defs::MUBYTE_OUT_CODE
          print_esc(s2i("mubyteout"), false)
        when Defs::MUBYTE_LOG_CODE
          print_esc(s2i("mubytelog"), false)
        when Defs::SPEC_OUT_CODE
          print_esc(s2i("specialout"), false)
        when Defs::PDF_OUTPUT_CODE
          print_esc(s2i("pdfoutput"), false)
        when Defs::PDF_COMPRESS_LEVEL_CODE
          print_esc(s2i("pdfcompresslevel"), false)
        when Defs::PDF_OBJCOMPRESSLEVEL_CODE
          print_esc(s2i("pdfobjcompresslevel"), false)
        when Defs::PDF_DECIMAL_DIGITS_CODE
          print_esc(s2i("pdfdecimaldigits"), false)
        when Defs::PDF_MOVE_CHARS_CODE
          print_esc(s2i("pdfmovechars"), false)
        when Defs::PDF_IMAGE_RESOLUTION_CODE
          print_esc(s2i("pdfimageresolution"), false)
        when Defs::PDF_PK_RESOLUTION_CODE
          print_esc(s2i("pdfpkresolution"), false)
        when Defs::PDF_UNIQUE_RESNAME_CODE
          print_esc(s2i("pdfuniqueresname"), false)
        when Defs::PDF_OPTION_ALWAYS_USE_PDFPAGEBOX_CODE
          print_esc(s2i("pdfoptionalwaysusepdfpagebox"), false)
        when Defs::PDF_OPTION_PDF_INCLUSION_ERRORLEVEL_CODE
          print_esc(s2i("pdfoptionpdfinclusionerrorlevel"), false)
        when Defs::PDF_MINOR_VERSION_CODE
          print_esc(s2i("pdfminorversion"), false)
        when Defs::PDF_FORCE_PAGEBOX_CODE
          print_esc(s2i("pdfforcepagebox"), false)
        when Defs::PDF_PAGEBOX_CODE
          print_esc(s2i("pdfpagebox"), false)
        when Defs::PDF_INCLUSION_ERRORLEVEL_CODE
          print_esc(s2i("pdfinclusionerrorlevel"), false)
        when Defs::PDF_GAMMA_CODE
          print_esc(s2i("pdfgamma"), false)
        when Defs::PDF_IMAGE_GAMMA_CODE
          print_esc(s2i("pdfimagegamma"), false)
        when Defs::PDF_IMAGE_HICOLOR_CODE
          print_esc(s2i("pdfimagehicolor"), false)
        when Defs::PDF_IMAGE_APPLY_GAMMA_CODE
          print_esc(s2i("pdfimageapplygamma"), false)
        when Defs::PDF_ADJUST_SPACING_CODE
          print_esc(s2i("pdfadjustspacing"), false)
        when Defs::PDF_PROTRUDE_CHARS_CODE
          print_esc(s2i("pdfprotrudechars"), false)
        when Defs::PDF_TRACING_FONTS_CODE
          print_esc(s2i("pdftracingfonts"), false)
        when Defs::PDF_ADJUST_INTERWORD_GLUE_CODE
          print_esc(s2i("pdfadjustinterwordglue"), false)
        when Defs::PDF_PREPEND_KERN_CODE
          print_esc(s2i("pdfprependkern"), false)
        when Defs::PDF_APPEND_KERN_CODE
          print_esc(s2i("pdfappendkern"), false)
        when Defs::PDF_GEN_TOUNICODE_CODE
          print_esc(s2i("pdfgentounicode"), false)
        when Defs::PDF_DRAFTMODE_CODE
          print_esc(s2i("pdfdraftmode"), false)
        when Defs::PDF_INCLUSION_COPY_FONT_CODE
          print_esc(s2i("pdfinclusioncopyfonts"), false)
        when Defs::PDF_SUPPRESS_WARNING_DUP_DEST_CODE
          print_esc(s2i("pdfsuppresswarningdupdest"), false)
        when Defs::PDF_SUPPRESS_WARNING_DUP_MAP_CODE
          print_esc(s2i("pdfsuppresswarningdupmap"), false)
        # {1899}:
        when Defs::SYNCTEX_CODE
          print_esc(s2i("synctex"), false)
        # {1654}:
        when Defs::TRACING_ASSIGNS_CODE
          print_esc(s2i("tracingassigns"), false)
        when Defs::TRACING_GROUPS_CODE
          print_esc(s2i("tracinggroups"), false)
        when Defs::TRACING_IFS_CODE
          print_esc(s2i("tracingifs"), false)
        when Defs::TRACING_SCAN_TOKENS_CODE
          print_esc(s2i("tracingscantokens"), false)
        when Defs::TRACING_NESTING_CODE
          print_esc(s2i("tracingnesting"), false)
        when Defs::PRE_DISPLAY_DIRECTION_CODE
          print_esc(s2i("predisplaydirection"), false)
        when Defs::LAST_LINE_FIT_CODE
          print_esc(s2i("lastlinefit"), false)
        when Defs::SAVING_VDISCARDS_CODE
          print_esc(s2i("savingvdiscards"), false)
        when Defs::SAVING_HYPH_CODES_CODE
          print_esc(s2i("savinghyphcodes"), false)
        # {1695}:
        when (Defs::ETEX_STATE_CODE + Defs::TEXXET_CODE)
          print_esc(s2i("TeXXeTstate"), false)
        # /1695/, /1654/
        else
          print(s2i("[unknown integer parameter!]"), false)
      end
    end
    #private :print_param

    # {265}:
    def print_length_param(n)
      case n
        when Defs::PAR_INDENT_CODE
          print_esc(s2i("parindent"), false)
        when Defs::MATH_SURROUND_CODE
          print_esc(s2i("mathsurround"), false)
        when Defs::LINE_SKIP_LIMIT_CODE
          print_esc(s2i("lineskiplimit"), false)
        when Defs::HSIZE_CODE
          print_esc(s2i("hsize"), false)
        when Defs::VSIZE_CODE
          print_esc(s2i("vsize"), false)
        when Defs::MAX_DEPTH_CODE
          print_esc(s2i("maxdepth"), false)
        when Defs::SPLIT_MAX_DEPTH_CODE
          print_esc(s2i("splitmaxdepth"), false)
        when Defs::BOX_MAX_DEPTH_CODE
          print_esc(s2i("boxmaxdepth"), false)
        when Defs::HFUZZ_CODE
          print_esc(s2i("hfuzz"), false)
        when Defs::VFUZZ_CODE
          print_esc(s2i("vfuzz"), false)
        when Defs::DELIMITER_SHORTFALL_CODE
          print_esc(s2i("delimitershortfall"), false)
        when Defs::NULL_DELIMITER_SPACE_CODE
          print_esc(s2i("nulldelimiterspace"), false)
        when Defs::SCRIPT_SPACE_CODE
          print_esc(s2i("scriptspace"), false)
        when Defs::PRE_DISPLAY_SIZE_CODE
          print_esc(s2i("predisplaysize"), false)
        when Defs::DISPLAY_WIDTH_CODE
          print_esc(s2i("displaywidth"), false)
        when Defs::DISPLAY_INDENT_CODE
          print_esc(s2i("displayindent"), false)
        when Defs::OVERFULL_RULE_CODE
          print_esc(s2i("overfullrule"), false)
        when Defs::HANG_INDENT_CODE
          print_esc(s2i("hangindent"), false)
        when Defs::H_OFFSET_CODE
          print_esc(s2i("hoffset"), false)
        when Defs::V_OFFSET_CODE
          print_esc(s2i("voffset"), false)
        when Defs::EMERGENCY_STRETCH_CODE
          print_esc(s2i("emergencystretch"), false)
        when Defs::PDF_H_ORIGIN_CODE
          print_esc(s2i("pdfhorigin"), false)
        when Defs::PDF_V_ORIGIN_CODE
          print_esc(s2i("pdfvorigin"), false)
        when Defs::PDF_PAGE_WIDTH_CODE
          print_esc(s2i("pdfpagewidth"), false)
        when Defs::PDF_PAGE_HEIGHT_CODE
          print_esc(s2i("pdfpageheight"), false)
        when Defs::PDF_LINK_MARGIN_CODE
          print_esc(s2i("pdflinkmargin"), false)
        when Defs::PDF_DEST_MARGIN_CODE
          print_esc(s2i("pdfdestmargin"), false)
        when Defs::PDF_THREAD_MARGIN_CODE
          print_esc(s2i("pdfthreadmargin"), false)
        when Defs::PDF_FIRST_LINE_HEIGHT_CODE
          print_esc(s2i("pdffirstlineheight"), false)
        when Defs::PDF_LAST_LINE_DEPTH_CODE
          print_esc(s2i("pdflastlinedepth"), false)
        when Defs::PDF_EACH_LINE_HEIGHT_CODE
          print_esc(s2i("pdfeachlineheight"), false)
        when Defs::PDF_EACH_LINE_DEPTH_CODE
          print_esc(s2i("pdfeachlinedepth"), false)
        when Defs::PDF_IGNORED_DIMEN_CODE
          print_esc(s2i("pdfignoreddimen"), false)
        when Defs::PDF_PX_DIMEN_CODE
          print_esc(s2i("pdfpxdimen"), false)
        else
          print(s2i("[unknown dimen parameter!]"), false)
      end
    end
    #private :print_length_param

    # {284}:
    def print_cs(p)
      if p < Defs::HASH_BASE then
        if p >= Defs::SINGLE_BASE then
          if p == Defs::NULL_CS then
            wterm("[ESCAPE, \"\"]")
          else
            wterm("[ESCAPE, \"")
            print(p - Defs::SINGLE_BASE, false)
            wterm("\"]")
          end
        elsif p < Defs::ACTIVE_BASE then
          @owner.alert "print_cs: p < ACTIVE_BASE (#{p})."
        else
          wterm("[ACTIVE_CHAR, \"")
          print(p - Defs::ACTIVE_BASE, false)
          wterm("\"]")
        end
      elsif (p >= Defs::UNDEFINED_CONTROL_SEQUENCE and p <= Defs::EQTB_SIZE) \
      or p > @eqtb_top then
        @owner.allert "print_cs: p (#{p}) is out of range."
      elsif text(p)._ >= @str_ptr then
        @owner.alert "print_cs: p (#{p}) does not exist in str_pool."
      else
        wterm("[ESCAPE, \"")
        print(text(p)._, false)
        wterm("\"]")
      end
    end
    #private :print_cs

    # {285}:
    def sprint_cs(p)
      if p < Defs::HASH_BASE then
        if p < Defs::SINGLE_BASE then
          wterm("[ACTIVE_CHAR, \"")
          print(p - Defs::ACTIVE_BASE, false)
          wterm("\"]")
        elsif p < Defs::NULL_CS then
          wterm("[ESCAPE, \"")
          print(p - Defs::SINGLE_BASE, false)
          wterm("\"]")
        else
          wterm("[ESCAPE, \"\"]")
        end
      else
        wterm("[ESCAPE, \"")
        print(text(p)._, false)
        wterm("\"]")
      end
    end
    #private :sprint_cs

    # {320}:
    def chr_cmd(s, c)
      print(s2i(s), false)
      wterm("'")
      print_ASCII(c, false)
      wterm("'")
    end
    private :chr_cmd

    def print_cmd_chr(cmd, chr_code)
      case cmd
        when Defs::LEFT_BRACE
          chr_cmd("begin-group character ", chr_code)
        when Defs::RIGHT_BRACE
          chr_cmd("end-group character ", chr_code)
        when Defs::MATH_SHIFT
          chr_cmd("math shift character ", chr_code)
        when Defs::MAC_PARAM
          chr_cmd("macro parameter character ", chr_code)
        when Defs::SUP_MARK
          chr_cmd("superscript character ", chr_code)
        when Defs::SUB_MARK
          chr_cmd("subscript character ", chr_code)
        when Defs::ENDV
          print(s2i("end of alignment template"), false)
        when Defs::SPACER
          chr_cmd("blank space ", chr_code)
        when Defs::LETTER
          chr_cmd("the letter ", chr_code)
        when Defs::OTHER_CHAR
          chr_cmd("the character ", chr_code)
        # {245}:
        when Defs::ASSIGN_GLUE, Defs::ASSIGN_MU_GLUE
          if chr_code < Defs::SKIP_BASE then
            print_skip_param(chr_code - Defs::GLUE_BASE)
          elsif chr_code < Defs::MU_SKIP_BASE then
            print_esc(s2i("skip"), false)
            print_int(chr_code - Defs::SKIP_BASE)
          else
            print_esc(s2i("muskip"), false)
            print_int(chr_code - Defs::MU_SKIP_BASE)
          end
        # {249}:
        when Defs::ASSIGN_TOKS
          if chr_code >= Defs::TOKS_BASE then
            print_esc(s2i("toks"), false)
            print_int(chr_code - Defs::TOKS_BASE)
          else
            case chr_code
              when Defs::OUTPUT_ROUTINE_LOC
                print_esc(s2i("output"), false)
              when Defs::EVERY_PAR_LOC
                print_esc(s2i("everypar"), false)
              when Defs::EVERY_MATH_LOC
                print_esc(s2i("everymath"), false)
              when Defs::EVERY_DISPLAY_LOC
                print_esc(s2i("everydisplay"), false)
              when Defs::EVERY_HBOX_LOC
                print_esc(s2i("everyhbox"), false)
              when Defs::EVERY_VBOX_LOC
                print_esc(s2i("everyvbox"), false)
              when Defs::EVERY_JOB_LOC
                print_esc(s2i("everyjob"), false)
              when Defs::EVERY_CR_LOC
                print_esc(s2i("everycr"), false)
              # {1653}:
              when Defs::EVERY_EOF_LOC
                print_esc(s2i("everyeof"), false)
              # /1653/
              when Defs::PDF_PAGES_ATTR_LOC
                print_esc(s2i("pdfpagesattr"), false)
              when Defs::PDF_PAGE_ATTR_LOC
                print_esc(s2i("pdfpageattr"), false)
              when Defs::PDF_PAGE_RESOURCES_LOC
                print_esc(s2i("pdfpageresources"), false)
              when Defs::PDF_PK_MODE_LOC
                print_esc(s2i("pdfpkmode"), false)
              else
                print_esc(s2i("errhelp"), false)
            end
          end
        # {257}:
        when Defs::ASSIGN_INT
          if chr_code < Defs::COUNT_BASE then
            print_param(chr_code - Defs::INT_BASE)
          else
            print_esc(s2i("count"), false)
            print_int(chr_code - Defs::COUNT_BASE)
          end
        # {267}:
        when Defs::ASSIGN_DIMEN
          if chr_code < Defs::SCALED_BASE then
            print_length_param(chr_code - Defs::DIMEN_BASE)
          else
            print_esc(s2i("dimen"), false)
            print_int(chr_code - Defs::SCALED_BASE)
          end
        # {288}:
        when Defs::ACCENT
          print_esc(s2i("accent"), false)
        when Defs::ADVANCE
          print_esc(s2i("advance"), false)
        when Defs::AFTER_ASSIGNMENT
          print_esc(s2i("afterassignment"), false)
        when Defs::AFTER_GROUP
          print_esc(s2i("aftergroup"), false)
        when Defs::ASSIGN_FONT_DIMEN
          print_esc(s2i("fontdimen"), false)
        when Defs::BEGIN_GROUP
          print_esc(s2i("begingroup"), false)
        when Defs::BREAK_PENALTY
          print_esc(s2i("penalty"), false)
        when Defs::CHAR_NUM
          print_esc(s2i("char"), false)
        when Defs::CS_NAME
          print_esc(s2i("csname"), false)
        when Defs::DEF_FONT
          print_esc(s2i("font"), false)
        when Defs::LETTERSPACE_FONT
          print_esc(s2i("letterspacefont"), false)
        when Defs::PDF_COPY_FONT
          print_esc(s2i("pdfcopyfont"), false)
        when Defs::DELIM_NUM
          print_esc(s2i("delimiter"), false)
        when Defs::DIVIDE
          print_esc(s2i("divide"), false)
        when Defs::END_CS_NAME
          if chr_code == 10 then
            print_esc(s2i("endmubyte"), false)
          else
            print_esc(s2i("endcsname"), false)
          end
        when Defs::END_GROUP
          print_esc(s2i("endgroup"), false)
        when Defs::EX_SPACE
          print_esc(" ".ord, false)
        when Defs::EXPAND_AFTER
          if chr_code == 0 then
            print_esc(s2i("expandafter"), false)
          # {1758}:
          else
            print_esc(s2i("unless"), false)
          end
        when Defs::HALIGN
          print_esc(s2i("halign"), false)
        when Defs::HRULE
          print_esc(s2i("hrule"), false)
        when Defs::IGNORE_SPACES
          if chr_code == 0 then
            print_esc(s2i("ignorespaces"), false)
          else
            print_esc(s2i("pdfprimitive"), false)
          end
        when Defs::INSERT
          print_esc(s2i("insert"), false)
        when Defs::ITAL_CORR
          print_esc("/".ord, false)
        when Defs::MARK
          print_esc(s2i("mark"), false)
          if chr_code > 0 then
            print_char("s".ord)
          end
        when Defs::MATH_ACCENT
          print_esc(s2i("mathaccent"), false)
        when Defs::MATH_CHAR_NUM
          print_esc(s2i("mathchar"), false)
        when Defs::MATH_CHOICE
          print_esc(s2i("mathchoice"), false)
        when Defs::MULTIPLY
          print_esc(s2i("multiply"), false)
        when Defs::NO_ALIGN
          print_esc(s2i("noalign"), false)
        when Defs::NO_BOUNDARY
          print_esc(s2i("noboundary"), false)
        when Defs::NO_EXPAND
          if chr_code == 0 then
            print_esc(s2i("noexpand"), false)
          else
            print_esc(s2i("pdfprimitive"), false)
          end
        when Defs::NON_SCRIPT
          print_esc(s2i("nonscript"), false)
        when Defs::OMIT
          print_esc(s2i("omit"), false)
        when Defs::RADICAL
          print_esc(s2i("radical"), false)
        when Defs::READ_TO_CS
          if chr_code == 0 then
            print_esc(s2i("read"), false)
          # {1755}:
          else
            print_esc(s2i("readline"), false)
          end
        when Defs::RELAX
          print_esc(s2i("relax"), false)
        when Defs::SET_BOX
          print_esc(s2i("setbox"), false)
        when Defs::SET_PREV_GRAF
          print_esc(s2i("prevgraf"), false)
        when Defs::SET_SHAPE
          case chr_code
            when Defs::PAR_SHAPE_LOC
              print_esc(s2i("parshape"), false)
            # {1860}:
            when Defs::INTER_LINE_PENALTIES_LOC
              print_esc(s2i("interlinepenalties"), false)
            when Defs::CLUB_PENALTIES_LOC
              print_esc(s2i("clubpenalties"), false)
            when Defs::WIDOW_PENALTIES_LOC
              print_esc(s2i("widowpenalties"), false)
            when Defs::DISPLAY_WIDOW_PENALTIES_LOC
              print_esc(s2i("displaywidowpenalties"), false)
            else
              @owner.alert \
                "Impossible case in print_cmd_chr.SET_SHAPE (#{chr_code})."
          end
        when Defs::THE
          if chr_code == 0 then
            print_esc(s2i("the"), false)
          # {1682}:
          elsif chr_code == 1 then
            print_esc(s2i("unexpanded"), false)
          else
            print_esc(s2i("detokenize"), false)
          end
        when Defs::TOKS_REGISTER
          # {1828}:
          print_esc(s2i("toks"), false)
          if chr_code != @mem_bot then
            print_sa_num(chr_code)
          end
        when Defs::VADJUST
          print_esc(s2i("vadjust"), false)
        when Defs::VALIGN
          if chr_code == 0 then
            print_esc(s2i("valign"), false)
          # {1697}:
          else
            case chr_code
              when Defs::BEGIN_L_CODE
                print_esc(s2i("beginL"), false)
              when Defs::END_L_CODE
                print_esc(s2i("endL"), false)
              when Defs::BEGIN_R_CODE
                print_esc(s2i("beginR"), false)
              else
                print_esc(s2i("endR"), false)
            end
          end
        when Defs::VCENTER
          print_esc(s2i("vcenter"), false)
        when Defs::VRULE
          print_esc(s2i("vrule"), false)
        # {357}:
        when Defs::PAR_END
          print_esc(s2i("par"), false)
        # {406}:
        when Defs::INPUT
          if chr_code == 0 then
            print_esc(s2i("input"), false)
          # {1743}:
          elsif chr_code == 2 then
            print_esc(s2i("scantokens"), false)
          # /1743/
          else
            print_esc(s2i("endinput"), false)
          end
        # {414}:
        when Defs::TOP_BOT_MARK
          case (chr_code % Defs::MARKS_CODE)
            when Defs::FIRST_MARK_CODE
              print_esc(s2i("firstmark"), false)
            when Defs::BOT_MARK_CODE
              print_esc(s2i("botmark"), false)
            when Defs::SPLIT_FIRST_MARK_CODE
              print_esc(s2i("splitfirstmark"), false)
            when Defs::SPLIT_BOT_MARK_CODE
              print_esc(s2i("splitbotmark"), false)
            else
              print_esc(s2i("topmark"), false)
          end
          if chr_code >= Defs::MARKS_CODE then
            print_char("s".ord)
          end
        # {441}:
        when Defs::REGISTER
          # {1827}:
          if chr_code < @mem_bot or chr_code > lo_mem_stat_max then
            cmd = sa_type(chr_code)._
          else
            cmd = chr_code - @mem_bot
            chr_code = Defs::NULL
          end
          if cmd == Defs::INT_VAL then
            print_esc(s2i("count"), false)
          elsif cmd == Defs::DIMEN_VAL then
            print_esc(s2i("dimen"), false)
          elsif cmd == Defs::GLUE_VAL then
            print_esc(s2i("skip"), false)
          else
            print_esc(s2i("muskip"), false)
          end
          if chr_code != Defs::NULL then
            print_sa_num(chr_code)
          end
        # {446}:
        when Defs::SET_AUX
          if chr_code == Defs::VMODE then
            print_esc(s2i("prevdepth"), false)
          else
            print_esc(s2i("spacefactor"), false)
          end
        when Defs::SET_PAGE_INT
          if chr_code == 0 then
            print_esc(s2i("deadcycles"), false)
          # {1688}:
          elsif chr_code == 2 then
            print_esc(s2i("interactionmode"), false)
          else
            print_esc(s2i("insertpenalties"), false)
          end
        when Defs::SET_BOX_DIMEN
          if chr_code == Defs::WIDTH_OFFSET then
            print_esc(s2i("wd"), false)
          elsif chr_code == Defs::HEIGHT_OFFSET then
            print_esc(s2i("ht"), false)
          else
            print_esc(s2i("dp"), false)
          end
        when Defs::LAST_ITEM
          case chr_code
            when Defs::INT_VAL
              print_esc(s2i("lastpenalty"), false)
            when Defs::DIMEN_VAL
              print_esc(s2i("lastkern"), false)
            when Defs::GLUE_VAL
              print_esc(s2i("lastskip"), false)
            when Defs::INPUT_LINE_NO_CODE
              print_esc(s2i("inputlineno"), false)
            # {1645}:
            when Defs::LAST_NODE_TYPE_CODE
              print_esc(s2i("lastnodetype"), false)
            when Defs::ETEX_VERSION_CODE
              print_esc(s2i("eTeXversion"), false)
            # {1659}:
            when Defs::CURRENT_GROUP_LEVEL_CODE
              print_esc(s2i("currentgrouplevel"), false)
            when Defs::CURRENT_GROUP_TYPE_CODE
              print_esc(s2i("currentgrouptype"), false)
            # {1662}:
            when Defs::CURRENT_IF_LEVEL_CODE
              print_esc(s2i("currentiflevel"), false)
            when Defs::CURRENT_IF_TYPE_CODE
              print_esc(s2i("currentiftype"), false)
            when Defs::CURRENT_IF_BRANCH_CODE
              print_esc(s2i("currentifbranch"), false)
            # {1665}:
            when Defs::FONT_CHAR_WD_CODE
              print_esc(s2i("fontcharwd"), false)
            when Defs::FONT_CHAR_HT_CODE
              print_esc(s2i("fontcharht"), false)
            when Defs::FONT_CHAR_DP_CODE
              print_esc(s2i("fontchardp"), false)
            when Defs::FONT_CHAR_IC_CODE
              print_esc(s2i("fontcharic"), false)
            # {1668}:
            when Defs::PAR_SHAPE_LENGTH_CODE
              print_esc(s2i("parshapelength"), false)
            when Defs::PAR_SHAPE_INDENT_CODE
              print_esc(s2i("parshapeindent"), false)
            when Defs::PAR_SHAPE_DIMEN_CODE
              print_esc(s2i("parshapedimen"), false)
            # {1774}:
            when (Defs::ETEX_EXPR - Defs::INT_VAL + Defs::INT_VAL)
              print_esc(s2i("numexpr"), false)
            when (Defs::ETEX_EXPR - Defs::INT_VAL + Defs::DIMEN_VAL)
              print_esc(s2i("dimexpr"), false)
            when (Defs::ETEX_EXPR - Defs::INT_VAL + Defs::GLUE_VAL)
              print_esc(s2i("glueexpr"), false)
            when (Defs::ETEX_EXPR - Defs::INT_VAL + Defs::MU_VAL)
              print_esc(s2i("muexpr"), false)
            # {1797}:
            when Defs::GLUE_STRETCH_ORDER_CODE
              print_esc(s2i("gluestretchorder"), false)
            when Defs::GLUE_SHRINK_ORDER_CODE
              print_esc(s2i("glueshrinkorder"), false)
            when Defs::GLUE_STRETCH_CODE
              print_esc(s2i("gluestretch"), false)
            when Defs::GLUE_SHRINK_CODE
              print_esc(s2i("glueshrink"), false)
            # {1801}:
            when Defs::MU_TO_GLUE_CODE
              print_esc(s2i("mutoglue"), false)
            when Defs::GLUE_TO_MU_CODE
              print_esc(s2i("gluetomu"), false)
            # /1645/
            when Defs::PDFTEX_VERSION_CODE
              print_esc(s2i("pdftexversion"), false)
            when Defs::PDF_LAST_OBJ_CODE
              print_esc(s2i("pdflastobj"), false)
            when Defs::PDF_LAST_XFORM_CODE
              print_esc(s2i("pdflastxform"), false)
            when Defs::PDF_LAST_XIMAGE_CODE
              print_esc(s2i("pdflastximage"), false)
            when Defs::PDF_LAST_XIMAGE_PAGES_CODE
              print_esc(s2i("pdflastximagepages"), false)
            when Defs::PDF_LAST_ANNOT_CODE
              print_esc(s2i("pdflastannot"), false)
            when Defs::PDF_LAST_X_POS_CODE
              print_esc(s2i("pdflastxpos"), false)
            when Defs::PDF_LAST_Y_POS_CODE
              print_esc(s2i("pdflastypos"), false)
            when Defs::PDF_RETVAL_CODE
              print_esc(s2i("pdfretval"), false)
            when Defs::PDF_LAST_XIMAGE_COLORDEPTH_CODE
              print_esc(s2i("pdflastximagecolordepth"), false)
            when Defs::ELAPSED_TIME_CODE
              print_esc(s2i("pdfelapsedtime"), false)
            when Defs::PDF_SHELL_ESCAPE_CODE
              print_esc(s2i("pdfshellescape"), false)
            when Defs::RANDOM_SEED_CODE
              print_esc(s2i("pdfrandomseed"), false)
            when Defs::PDF_LAST_LINK_CODE
              print_esc(s2i("pdflastlink"), false)
            else
              print_esc(s2i("badness"), false)
          end
        # {498}:
        when Defs::CONVERT
          case chr_code
            when Defs::NUMBER_CODE
              print_esc(s2i("number"), false)
            when Defs::ROMAN_NUMERAL_CODE
              print_esc(s2i("romannumeral"), false)
            when Defs::STRING_CODE
              print_esc(s2i("string"), false)
            when Defs::MEANING_CODE
              print_esc(s2i("meaning"), false)
            when Defs::FONT_NAME_CODE
              print_esc(s2i("fontname"), false)
            when Defs::ETEX_REVISION_CODE
              print_esc(s2i("eTeXrevision"), false)
            when Defs::PDFTEX_REVISION_CODE
              print_esc(s2i("pdftexrevision"), false)
            when Defs::PDFTEX_BANNER_CODE
              print_esc(s2i("pdftexbanner"), false)
            when Defs::PDF_FONT_NAME_CODE
              print_esc(s2i("pdffontname"), false)
            when Defs::PDF_FONT_OBJNUM_CODE
              print_esc(s2i("pdffontobjnum"), false)
            when Defs::PDF_FONT_SIZE_CODE
              print_esc(s2i("pdffontsize"), false)
            when Defs::PDF_PAGE_REF_CODE
              print_esc(s2i("pdfpageref"), false)
            when Defs::LEFT_MARGIN_KERN_CODE
              print_esc(s2i("leftmarginkern"), false)
            when Defs::RIGHT_MARGIN_KERN_CODE
              print_esc(s2i("rightmarginkern"), false)
            when Defs::PDF_XFORM_NAME_CODE
              print_esc(s2i("pdfxformname"), false)
            when Defs::PDF_ESCAPE_STRING_CODE
              print_esc(s2i("pdfescapestring"), false)
            when Defs::PDF_ESCAPE_NAME_CODE
              print_esc(s2i("pdfescapename"), false)
            when Defs::PDF_ESCAPE_HEX_CODE
              print_esc(s2i("pdfescapehex"), false)
            when Defs::PDF_UNESCAPE_HEX_CODE
              print_esc(s2i("pdfunescapehex"), false)
            when Defs::PDF_CREATION_DATE_CODE
              print_esc(s2i("pdfcreationdate"), false)
            when Defs::PDF_FILE_MOD_DATE_CODE
              print_esc(s2i("pdffilemoddate"), false)
            when Defs::PDF_FILE_SIZE_CODE
              print_esc(s2i("pdffilesize"), false)
            when Defs::PDF_MDFIVE_SUM_CODE
              print_esc(s2i("pdfmdfivesum"), false)
            when Defs::PDF_FILE_DUMP_CODE
              print_esc(s2i("pdffiledump"), false)
            when Defs::PDF_MATCH_CODE
              print_esc(s2i("pdfmatch"), false)
            when Defs::PDF_LAST_MATCH_CODE
              print_esc(s2i("pdflastmatch"), false)
            when Defs::PDF_STRCMP_CODE
              print_esc(s2i("pdfstrcmp"), false)
            when Defs::PDF_COLORSTACK_INIT_CODE
              print_esc(s2i("pdfcolorstackinit"), false)
            when Defs::UNIFORM_DEVIATE_CODE
              print_esc(s2i("pdfuniformdeviate"), false)
            when Defs::NORMAL_DEVIATE_CODE
              print_esc(s2i("pdfnormaldeviate"), false)
            when Defs::PDF_INSERT_HT_CODE
              print_esc(s2i("pdfinsertht"), false)
            when Defs::PDF_XIMAGE_BBOX_CODE
              print_esc(s2i("pdfximagebbox"), false)
            else
              print_esc(s2i("jobname"), false)
          end
        # {517}:
        when Defs::IF_TEST
          if chr_code >= Defs::UNLESS_CODE then
            print_esc(s2i("unless"), false)
          end
          case (chr_code % Defs::UNLESS_CODE)
            when Defs::IF_CAT_CODE
              print_esc(s2i("ifcat"), false)
            when Defs::IF_INT_CODE
              print_esc(s2i("ifnum"), false)
            when Defs::IF_DIM_CODE
              print_esc(s2i("ifdim"), false)
            when Defs::IF_ODD_CODE
              print_esc(s2i("ifodd"), false)
            when Defs::IF_VMODE_CODE
              print_esc(s2i("ifvmode"), false)
            when Defs::IF_HMODE_CODE
              print_esc(s2i("ifhmode"), false)
            when Defs::IF_MMODE_CODE
              print_esc(s2i("ifmmode"), false)
            when Defs::IF_INNER_CODE
              print_esc(s2i("ifinner"), false)
            when Defs::IF_VOID_CODE
              print_esc(s2i("ifvoid"), false)
            when Defs::IF_HBOX_CODE
              print_esc(s2i("ifhbox"), false)
            when Defs::IF_VBOX_CODE
              print_esc(s2i("ifvbox"), false)
            when Defs::IFX_CODE
              print_esc(s2i("ifx"), false)
            when Defs::IF_EOF_CODE
              print_esc(s2i("ifeof"), false)
            when Defs::IF_TRUE_CODE
              print_esc(s2i("iftrue"), false)
            when Defs::IF_FALSE_CODE
              print_esc(s2i("iffalse"), false)
            when Defs::IF_CASE_CODE
              print_esc(s2i("ifcase"), false)
            when Defs::IF_PDFPRIMITIVE_CODE
              print_esc(s2i("ifpdfprimitive"), false)
            # {1759}:
            when Defs::IF_DEF_CODE
              print_esc(s2i("ifdefined"), false)
            when Defs::IF_CS_CODE
              print_esc(s2i("ifcsname"), false)
            when Defs::IF_FONT_CHAR_CODE
              print_esc(s2i("iffontchar"), false)
            when Defs::IF_IN_CSNAME_CODE
              print_esc(s2i("ifincsname"), false)
            when Defs::IF_PDFABS_NUM_CODE
              print_esc(s2i("ifpdfabsnum"), false)
            when Defs::IF_PDFABS_DIM_CODE
              print_esc(s2i("ifpdfabsdim"), false)
            else
              print_esc(s2i("if"), false)
          end
        # {521}:
        when Defs::FI_OR_ELSE
          if chr_code == Defs::FI_CODE then
            print_esc(s2i("fi"), false)
          elsif chr_code == Defs::OR_CODE then
            print_esc(s2i("or"), false)
          else
            print_esc(s2i("else"), false)
          end
        # {959}:
        when Defs::TAB_MARK
          if chr_code == Defs::SPAN_CODE then
            print_esc(s2i("span"), false)
          else
            chr_cmd("alignment tab character ", chr_code)
          end
        when Defs::CAR_RET
          if chr_code == Defs::CR_CODE then
            print_esc(s2i("cr"), false)
          else
            print_esc(s2i("crcr"), false)
          end
        # {1163}:
        when Defs::SET_PAGE_DIMEN
          case chr_code
            when 0
              print_esc(s2i("pagegoal"), false)
            when 1
              print_esc(s2i("pagetotal"), false)
            when 2
              print_esc(s2i("pagestretch"), false)
            when 3
              print_esc(s2i("pagefilstretch"), false)
            when 4
              print_esc(s2i("pagefillstretch"), false)
            when 5
              print_esc(s2i("pagefilllstretch"), false)
            when 6
              print_esc(s2i("pageshrink"), false)
            else
              print_esc(s2i("pagedepth"), false)
          end
        # {1233}:
        when Defs::STOP
          if chr_code == 1 then
            print_esc(s2i("dump"), false)
          else
            print_esc(s2i("end"), false)
          end
        # {1239}:
        when Defs::HSKIP
          case chr_code
            when Defs::SKIP_CODE
              print_esc(s2i("hskip"), false)
            when Defs::FIL_CODE
              print_esc(s2i("hfil"), false)
            when Defs::FILL_CODE
              print_esc(s2i("hfill"), false)
            when Defs::SS_CODE
              print_esc(s2i("hss"), false)
            else
              print_esc(s2i("hfilneg"), false)
          end
        when Defs::VSKIP
          case chr_code
            when Defs::SKIP_CODE
              print_esc(s2i("vskip"), false)
            when Defs::FIL_CODE
              print_esc(s2i("vfil"), false)
            when Defs::FILL_CODE
              print_esc(s2i("vfill"), false)
            when Defs::SS_CODE
              print_esc(s2i("vss"), false)
            else
              print_esc(s2i("vfilneg"), false)
          end
        when Defs::MSKIP
          print_esc(s2i("mskip"), false)
        when Defs::KERN
          print_esc(s2i("kern"), false)
        when Defs::MKERN
          print_esc(s2i("mkern"), false)
        # {1252}:
        when Defs::HMOVE
          if chr_code == 1 then
            print_esc(s2i("moveleft"), false)
          else
            print_esc(s2i("moveright"), false)
          end
        when Defs::VMOVE
          if chr_code == 1 then
            print_esc(s2i("raise"), false)
          else
            print_esc(s2i("lower"), false)
          end
        when Defs::MAKE_BOX
          case chr_code
            when Defs::BOX_CODE
              print_esc(s2i("box"), false)
            when Defs::COPY_CODE
              print_esc(s2i("copy"), false)
            when Defs::LAST_BOX_CODE
              print_esc(s2i("lastbox"), false)
            when Defs::VSPLIT_CODE
              print_esc(s2i("vsplit"), false)
            when Defs::VTOP_CODE
              print_esc(s2i("vtop"), false)
            when (Defs::VTOP_CODE + Defs::VMODE)
              print_esc(s2i("vbox"), false)
            else
              print_esc(s2i("hbox"), false)
          end
        when Defs::LEADER_SHIP
          if chr_code == Defs::A_LEADERS then
            print_esc(s2i("leaders"), false)
          elsif chr_code == Defs::C_LEADERS then
            print_esc(s2i("cleaders"), false)
          elsif chr_code == Defs::X_LEADERS then
            print_esc(s2i("xleaders"), false)
          else
            print_esc(s2i("shipout"), false)
          end
        # {1269}:
        when Defs::START_PAR
          if chr_code == 0 then
            print_esc(s2i("noindent"), false)
          elsif chr_code == 1 then
            print_esc(s2i("indent"), false)
          else
            print_esc(s2i("quitvmode"), false)
          end
        # {1288}:
        when Defs::REMOVE_ITEM
          if chr_code == Defs::GLUE_NODE then
            print_esc(s2i("unskip"), false)
          elsif chr_code == Defs::KERN_NODE then
            print_esc(s2i("unkern"), false)
          else
            print_esc(s2i("unpenalty"), false)
          end
        when Defs::UN_HBOX
          if chr_code == Defs::COPY_CODE then
            print_esc(s2i("unhcopy"), false)
          else
            print_esc(s2i("unhbox"), false)
          end
        when Defs::UN_VBOX
          if chr_code == Defs::COPY_CODE then
            print_esc(s2i("unvcopy"), false)
          # {1857}:
          elsif chr_code == Defs::LAST_BOX_CODE then
            print_esc(s2i("pagediscards"), false)
          elsif chr_code == Defs::VSPLIT_CODE then
            print_esc(s2i("splitdiscards"), false)
          # /1857/
          else
            print_esc(s2i("unvbox"), false)
          end
        # {1295}:
        when Defs::DISCRETIONARY
          if chr_code == 1 then
            print_esc(s2i("-"), false)
          else
            print_esc(s2i("discretionary"), false)
          end
        # {1323}:
        when Defs::EQ_NO
          if chr_code == 1 then
            print_esc(s2i("leqno"), false)
          else
            print_esc(s2i("eqno"), false)
          end
        # {1337}:
        when Defs::MATH_COMP
          case chr_code
            when Defs::ORD_NOAD
              print_esc(s2i("mathord"), false)
            when Defs::OP_NOAD
              print_esc(s2i("mathop"), false)
            when Defs::BIN_NOAD
              print_esc(s2i("mathbin"), false)
            when Defs::REL_NOAD
              print_esc(s2i("mathrel"), false)
            when Defs::OPEN_NOAD
              print_esc(s2i("mathopen"), false)
            when Defs::CLOSE_NOAD
              print_esc(s2i("mathclose"), false)
            when Defs::PUNCT_NOAD
              print_esc(s2i("mathpunct"), false)
            when Defs::INNER_NOAD
              print_esc(s2i("mathinner"), false)
            when Defs::UNDER_NOAD
              print_esc(s2i("underline"), false)
            else
              print_esc(s2i("overline"), false)
          end
        when Defs::LIMIT_SWITCH
          if chr_code == Defs::LIMITS then
            print_esc(s2i("limits"), false)
          elsif chr_code == Defs::NO_LIMITS then
            print_esc(s2i("nolimits"), false)
          else
            print_esc(s2i("displaylimits"), false)
          end
        # {1350}:
        when Defs::MATH_STYLE
          print_style(chr_code)
        # {1359}:
        when Defs::ABOVE
          case chr_code
            when Defs::OVER_CODE
              print_esc(s2i("over"), false)
            when Defs::ATOP_CODE
              print_esc(s2i("atop"), false)
            when (Defs::DELIMITED_CODE + Defs::ABOVE_CODE)
              print_esc(s2i("abovewithdelims"), false)
            when (Defs::DELIMITED_CODE + Defs::OVER_CODE)
              print_esc(s2i("overwithdelims"), false)
            when (Defs::DELIMITED_CODE + Defs::ATOP_CODE)
              print_esc(s2i("atopwithdelims"), false)
            else
              print_esc(s2i("above"), false)
          end
        # {1369}:
        when Defs::LEFT_RIGHT
          if chr_code == Defs::LEFT_NOAD then
            print_esc(s2i("left"), false)
          # {1693}:
          elsif chr_code == Defs::MIDDLE_NOAD then
            print_esc(s2i("middle"), false)
          else
            print_esc(s2i("right"), false)
          end
        # {1389}:
        when Defs::PREFIX
          if chr_code == 1 then
            print_esc(s2i("long"), false)
          elsif chr_code == 2 then
            print_esc(s2i("outer"), false)
          # {1766}:
          elsif chr_code == 8 then
            print_esc(s2i("protected"), false)
          # /1766/
          else
            print_esc(s2i("global"), false)
          end
        when Defs::DEF
          if chr_code == 0 then
            print_esc(s2i("def"), false)
          elsif chr_code == 1 then
            print_esc(s2i("gdef"), false)
          elsif chr_code == 2 then
            print_esc(s2i("edef"), false)
          else
            print_esc(s2i("xdef"), false)
          end
        # {1400}:
        when Defs::LET
          if chr_code != Defs::NORMAL then
            if chr_code == Defs::NORMAL + 10 then
              print_esc(s2i("mubyte"), false)
            elsif chr_code == Defs::NORMAL + 11 then
              print_esc(s2i("noconvert"), false)
            else
              print_esc(s2i("futurelet"), false)
            end
          else
            print_esc(s2i("let"), false)
          end
        # {1403}:
        when Defs::SHORTHAND_DEF
          case chr_code
            when Defs::CHAR_DEF_CODE
              print_esc(s2i("chardef"), false)
            when Defs::MATH_CHAR_DEF_CODE
              print_esc(s2i("mathchardef"), false)
            when Defs::COUNT_DEF_CODE
              print_esc(s2i("countdef"), false)
            when Defs::DIMEN_DEF_CODE
              print_esc(s2i("dimendef"), false)
            when Defs::SKIP_DEF_CODE
              print_esc(s2i("skipdef"), false)
            when Defs::MU_SKIP_DEF_CODE
              print_esc(s2i("muskipdef"), false)
            when Defs::CHAR_SUB_DEF_CODE
              print_esc(s2i("charsubdef"), false)
            else
              print_esc(s2i("toksdef"), false)
          end
        when Defs::CHAR_GIVEN
          print_esc(s2i("char"), false)
          print_hex(chr_code)
        when Defs::MATH_GIVEN
          print_esc(s2i("mathchar"), false)
          print_hex(chr_code)
        # {1411}:
        when Defs::DEF_CODE
          if chr_code == Defs::XORD_CODE_BASE then
            print_esc(s2i("xordcode"), false)
          elsif chr_code == Defs::XCHR_CODE_BASE then
            print_esc(s2i("xchrcode"), false)
          elsif chr_code == Defs::XPRN_CODE_BASE then
            print_esc(s2i("xprncode"), false)
          elsif chr_code == Defs::CAT_CODE_BASE then
            print_esc(s2i("catcode"), false)
          elsif chr_code == Defs::MATH_CODE_BASE then
            print_esc(s2i("mathcode"), false)
          elsif chr_code == Defs::LC_CODE_BASE then
            print_esc(s2i("lccode"), false)
          elsif chr_code == Defs::UC_CODE_BASE then
            print_esc(s2i("uccode"), false)
          elsif chr_code == Defs::SF_CODE_BASE then
            print_esc(s2i("sfcode"), false)
          else
            print_esc(s2i("delcode"), false)
          end
        when Defs::DEF_FAMILY
          print_size(chr_code - Defs::MATH_FONT_BASE)
        # {1431}:
        when Defs::HYPH_DATA
          if chr_code == 1 then
            print_esc(s2i("patterns"), false)
          else
            print_esc(s2i("hyphenation"), false)
          end
        # {1435}:
        when Defs::ASSIGN_FONT_INT
          case chr_code
            when 0
              print_esc(s2i("hyphenchar"), false)
            when 1
              print_esc(s2i("skewchar"), false)
            when Defs::LP_CODE_BASE
              print_esc(s2i("lpcode"), false)
            when Defs::RP_CODE_BASE
              print_esc(s2i("rpcode"), false)
            when Defs::EF_CODE_BASE
              print_esc(s2i("efcode"), false)
            when Defs::TAG_CODE
              print_esc(s2i("tagcode"), false)
            when Defs::KN_BS_CODE_BASE
              print_esc(s2i("knbscode"), false)
            when Defs::ST_BS_CODE_BASE
              print_esc(s2i("stbscode"), false)
            when Defs::SH_BS_CODE_BASE
              print_esc(s2i("shbscode"), false)
            when Defs::KN_BC_CODE_BASE
              print_esc(s2i("knbccode"), false)
            when Defs::KN_AC_CODE_BASE
              print_esc(s2i("knaccode"), false)
            when Defs::NO_LIG_CODE
              print_esc(s2i("pdfnoligatures"), false)
          end
        # {1441}:
        when Defs::SET_FONT
          print(s2i("select font "), false)
          slow_print(@font_name[chr_code]._, false)
          if @font_size[chr_code]._ != @font_dsize[chr_code]._ then
            print(s2i(" at "), false)
            print_scaled(@font_size[chr_code]._)
            print(s2i("pt"), false)
          end
        # {1443}:
        when Defs::SET_INTERACTION
          case chr_code
            when Defs::BATCH_MODE
              print_esc(s2i("batchmode"), false)
            when Defs::NONSTOP_MODE
              print_esc(s2i("nonstopmode"), false)
            when Defs::SCROLL_MODE
              print_esc(s2i("scrollmode"), false)
            else
              print_esc(s2i("errorstopmode"), false)
          end
        # {1453}:
        when Defs::IN_STREAM
          if chr_code == 0 then
            print_esc(s2i("closein"), false)
          else
            print_esc(s2i("openin"), false)
          end
        # {1458}:
        when Defs::MESSAGE
          if chr_code == 0 then
            print_esc(s2i("message"), false)
          else
            print_esc(s2i("errmessage"), false)
          end
        # {1467}:
        when Defs::CASE_SHIFT
          if chr_code == Defs::LC_CODE_BASE then
            print_esc(s2i("lowercase"), false)
          else
            print_esc(s2i("uppercase"), false)
          end
        # {1472}:
        when Defs::XRAY
          case chr_code
            when Defs::SHOW_BOX_CODE
              print_esc(s2i("showbox"), false)
            when Defs::SHOW_THE_CODE
              print_esc(s2i("showthe"), false)
            when Defs::SHOW_LISTS
              print_esc(s2i("showlists"), false)
            # {1671}:
            when Defs::SHOW_GROUPS
              print_esc(s2i("showgroups"), false)
            # {1680}:
            when Defs::SHOW_TOKENS
              print_esc(s2i("showtokens"), false)
            # {1685}:
            when Defs::SHOW_IFS
              print_esc(s2i("showifs"), false)
            # /1671/
            else
              print_esc(s2i("show"), false)
          end
        # {1475}:
        when Defs::UNDEFINED_CS
          print(s2i("undefined"), false)
        when Defs::CALL, Defs::LONG_CALL, Defs::OUTER_CALL, \
             Defs::LONG_OUTER_CALL
          n = cmd - Defs::CALL
          if chr_code != Defs::NULL \
          and info(link(chr_code)._)._ == Defs::PROTECTED_TOKEN then
            n += 4
          end
          if ((n >> 2) & 1) == 1 then
            print_esc(s2i("protected"), false)
          end
          if (n & 1) == 1 then
            print_esc(s2i("long"), false)
          end
          if ((n >> 1) & 1) == 1 then
            print_esc(s2i("outer"), false)
          end
          if n > 0 then
            print_char(" ".ord)
          end
          print(s2i("macro"), false)
          if chr_code == Defs::NULL then
            wterm(" (null)")
          end
        when Defs::END_TEMPLATE
          print_esc(s2i("outer endtemplate"), false)
        # {1528}:
        when Defs::EXTENSION
          case chr_code
            when Defs::OPEN_NODE
              print_esc(s2i("openout"), false)
            when Defs::WRITE_NODE
              print_esc(s2i("write"), false)
            when Defs::CLOSE_NODE
              print_esc(s2i("closeout"), false)
            when Defs::SPECIAL_NODE
              print_esc(s2i("special"), false)
            when Defs::IMMEDIATE_CODE
              print_esc(s2i("immediate"), false)
            when Defs::SET_LANGUAGE_CODE
              print_esc(s2i("setlanguage"), false)
            when Defs::PDF_ANNOT_NODE
              print_esc(s2i("pdfannot"), false)
            when Defs::PDF_CATALOG_CODE
              print_esc(s2i("pdfcatalog"), false)
            when Defs::PDF_DEST_NODE
              print_esc(s2i("pdfdest"), false)
            when Defs::PDF_END_LINK_NODE
              print_esc(s2i("pdfendlink"), false)
            when Defs::PDF_END_THREAD_NODE
              print_esc(s2i("pdfendthread"), false)
            when Defs::PDF_FONT_ATTR_CODE
              print_esc(s2i("pdffontattr"), false)
            when Defs::PDF_FONT_EXPAND_CODE
              print_esc(s2i("pdffontexpand"), false)
            when Defs::PDF_INCLUDE_CHARS_CODE
              print_esc(s2i("pdfincludechars"), false)
            when Defs::PDF_INFO_CODE
              print_esc(s2i("pdfinfo"), false)
            when Defs::PDF_LITERAL_NODE
              print_esc(s2i("pdfliteral"), false)
            when Defs::PDF_COLORSTACK_NODE
              print_esc(s2i("pdfcolorstack"), false)
            when Defs::PDF_SETMATRIX_NODE
              print_esc(s2i("pdfsetmatrix"), false)
            when Defs::PDF_SAVE_NODE
              print_esc(s2i("pdfsave"), false)
            when Defs::PDF_RESTORE_NODE
              print_esc(s2i("pdfrestore"), false)
            when Defs::PDF_MAP_FILE_CODE
              print_esc(s2i("pdfmapfile"), false)
            when Defs::PDF_MAP_LINE_CODE
              print_esc(s2i("pdfmapline"), false)
            when Defs::PDF_NAMES_CODE
              print_esc(s2i("pdfnames"), false)
            when Defs::PDF_OBJ_CODE
              print_esc(s2i("pdfobj"), false)
            when Defs::PDF_OUTLINE_CODE
              print_esc(s2i("pdfoutline"), false)
            when Defs::PDF_REFOBJ_NODE
              print_esc(s2i("pdfrefobj"), false)
            when Defs::PDF_REFXFORM_NODE
              print_esc(s2i("pdfrefxform"), false)
            when Defs::PDF_REFXIMAGE_NODE
              print_esc(s2i("pdfrefximage"), false)
            when Defs::PDF_SAVE_POS_NODE
              print_esc(s2i("pdfsavepos"), false)
            when Defs::PDF_SNAP_REF_POINT_NODE
              print_esc(s2i("pdfsnaprefpoint"), false)
            when Defs::PDF_SNAPY_COMP_NODE
              print_esc(s2i("pdfsnapycomp"), false)
            when Defs::PDF_SNAPY_NODE
              print_esc(s2i("pdfsnapy"), false)
            when Defs::PDF_START_LINK_NODE
              print_esc(s2i("pdfstartlink"), false)
            when Defs::PDF_START_THREAD_NODE
              print_esc(s2i("pdfstartthread"), false)
            when Defs::PDF_THREAD_NODE
              print_esc(s2i("pdfthread"), false)
            when Defs::PDF_TRAILER_CODE
              print_esc(s2i("pdftrailer"), false)
            when Defs::PDF_XFORM_CODE
              print_esc(s2i("pdfxform"), false)
            when Defs::PDF_XIMAGE_CODE
              print_esc(s2i("pdfximage"), false)
            when Defs::RESET_TIMER_CODE
              print_esc(s2i("pdfresettimer"), false)
            when Defs::SET_RANDOM_SEED_CODE
              print_esc(s2i("pdfsetrandomseed"), false)
            when Defs::PDF_NOBUILTIN_TOUNICODE_CODE
              print_esc(s2i("pdfnobuiltintounicode"), false)
            when Defs::PDF_GLYPH_TO_UNICODE_CODE
              print_esc(s2i("pdfglyphtounicode"), false)
            else
              print(s2i("[unknown extension!]"), false)
          end
        else
          print(s2i("[unknown command code!]"), false)
      end
    end
    #private :print_cmd_chr

    # {547}:
    def print_quoted(x)
      if x == 0 then
        return
      end
      ((@str_start[x]._)..(@str_start[x + 1]._ - 1)).each do |j|
        if so(@str_pool[j]._) == "\"".ord then
          wterm("\\")
        end
        print(so(@str_pool[j]._), false)
      end
    end
    private :print_quoted

    def print_file_name(n ,a, e)
      print_quoted(a)
      print_quoted(n)
      print_quoted(e)
    end
    #private :print_file_name

    # {869}:
    def print_fam_and_char(p)
      wterm("{fam: ")
      print_int(fam(p)._)
      wterm(", char: '")
      print_ASCII(qo(character(p)._), false)
      wterm("'}")
    end
    #private :print_fam_and_char

    def print_delimiter(p)
      a = (small_fam(p)._ << 8) + qo(small_char(p)._)
      a = (a << 12) + (large_fam(p)._ << 8) + qo(large_char(p)._)
      if a < 0 then
        print_int(a)
      else
        print_hex(a)
      end
    end
    #private :print_delimiter

    # {870}:
    def print_subsidiary_data(p, indent, visited)
      visited.push(p)
      case math_type(p)._
        when Defs::MATH_CHAR
          wterm_ln(indent + "(:MATH_CHAR")
          wterm(indent + "  ")
          print_fam_and_char(p)
          wterm_cr
          wterm_ln(indent + ":)")
        when Defs::SUB_BOX
          wterm_ln(indent + "(:SUB_BOX")
          show_node_list(info(p)._, indent + "  ", visited)
          wterm_ln(indent + ":)")
        when Defs::SUB_MLIST
          wterm_ln(indent + "(:SUB_MLIST")
          if info(p)._ != Defs::NULL then
            show_node_list(info(p)._, indent + "  ", visited)
          end
          wterm_ln(indent + ":)")
        else
          wterm_ln(indent + "(:???:)")
      end
    end
    #private :print_subsidiary_data

    # {872}:
    def print_style(c)
      case (c >> 1)
        when 0
          print_esc(s2i("displaystyle"), false)
        when 1
          print_esc(s2i("textstyle"), false)
        when 2
          print_esc(s2i("scriptstyle"), false)
        when 3
          print_esc(s2i("scriptscriptstyle"), false)
        else
          print(s2i("Unknown style!"), false)
      end
    end
    #private :print_style

    # {877}:
    def print_size(s)
      if s == Defs::TEXT_SIZE then
        print_esc(s2i("textfont"), false)
      elsif s == Defs::SCRIPT_SIZE then
        print_esc(s2i("scriptfont"), false)
      else
        print_esc(s2i("scriptscriptfont"), false)
      end
    end
    #private :print_size

    # {1597}:
    def print_write_whatsit(s, p)
      print(s, false)
      wterm(" {stream_num: ")
      print_int(write_stream(p)._)
      if s == s2i("write") and write_mubyte(p)._ != Defs::MUBYTE_ZERO then
        wterm(", mubyte: ")
        print_int(write_mubyte(p)._ - Defs::MUBYTE_ZERO)
      end
      wterm("}")
    end
    #private :print_write_whatsit

    # {1817}:
    def print_sa_num(q)
      n = 0
      if sa_index(q)._ < Defs::DIMEN_VAL_LIMIT then
        n = sa_num(q)._
      else
        n = sa_index(q)._ & 15
        q = link(q)._
        n += (sa_index(q)._ << 4)
        q = link(q)._
        n += ((sa_index(q)._ + (sa_index(link(q)._)._ << 4)) << 8)
      end
      print_int(n)
    end
    #private :print_sa_num

    # -------------------------------------------------------------------------
    # -- Showing the things
    # --
    class TokenListPrinter
      def initialize(opts)
        @level = 0
        @indent = opts[:indent] or ""
        @tex = opts[:tex]
      end

      def indent
        @level += 1
      end

      def dedent
        @level -= 1
        @level = 0 if @level < 0
      end

      def printmsg(msg)
        @tex.wterm_ln(@indent + "  "*@level + msg)
      end

      def print_cs(cs)
        @tex.wterm(@indent + "  "*@level)
        @tex.print_cs(cs)
        @tex.wterm_cr
      end

      def printtok(catname, c)
        @tex.wterm(@indent + "  "*@level)
        @tex.wterm("[#{catname}, \"")
        @tex.print(c, false)
        @tex.wterm_ln("\"]")
      end

      def printstok(catname, n)
        @tex.wterm(@indent + "  "*@level)
        @tex.wterm_ln("[#{catname}, #{n}]")
      end
    end

    # {200}:
    def show_node_list(p, indent, visited = [])
      n = 0
      while p > @mem_min and (not visited.include? p) do
        if p > @mem_end then
          @owner.alert "show_node_list: p (#{p}) > mem_end."
          return
        end
        n += 1
        visited.push(p)
        # Display node ({201}):
        if is_char_node(p) then
          wterm_ln(indent + "[:CHAR_NODE")
          print_font_and_char(p, indent + "  ")
          wterm_ln(indent + ":]")
        else
          case type(p)._
            when Defs::HLIST_NODE, Defs::VLIST_NODE, Defs::UNSET_NODE
              # Display box ({202}):
              wterm(indent + "[:")
              if type(p)._ == Defs::HLIST_NODE then
                wterm("HLIST")
              elsif type(p)._ == Defs::VLIST_NODE then
                wterm("VLIST")
              else
                wterm("UNSET")
              end
              wterm_ln("_NODE")
              # Box dimensions:
              wterm_ln(indent + "  dimensions ((h + d) * w): (")
              print_scaled(height(p)._)
              wterm(" + ")
              print_scaled(depth(p)._)
              wterm(") * ")
              print_scaled(width(p)._)
              wterm_cr
              if type(p)._ == Defs::UNSET_NODE then
                # Special fields of unset node ({203}):
                if span_count(p)._ != Defs::MIN_QUARTERWORD then
                  wterm(indent + "  columns: ")
                  print_int(qo(span_count(p)._) + 1)
                  wterm_cr
                end
                if glue_stretch(p)._ != 0 then
                  wterm(indent + "  stretch: ")
                  print_glue(glue_stretch(p)._, glue_order(p)._, 0)
                  wterm_cr
                end
                if glue_shrink(p)._ != 0 then
                  wterm(indent + "  shrink: ")
                  print_glue(glue_shrink(p)._, glue_sign(p)._, 0)
                  wterm_cr
                end
                # /203/
              else
                # Value of glue_set(p) ({204}):
                g = float(glue_set(p)._)
                if g != float_constant(0) \
                and glue_sign(p)._ != Defs::NORMAL then
                  wterm(indent + "  glue_set: ")
                  # - glue sign:
                  if glue_sign(p)._ == Defs::SHRINKING then
                    wterm("sign: '-' (shrinking), ")
                  elsif glue_sign(p)._ == Defs::STRETCHING then
                    wterm("sign: '+' (stretching), ")
                  elsif glue_sign(p)._ == Defs::NORMAL then
                    wterm("sign: '0' (normal), ")
                  else
                    wterm("sign: ??? (#{glue_sign(p)._}), ")
                  end
                  # - glue value:
                  wterm("value: ")
                  if g.abs > float_constant(20000) then
                    if g > float_constant(0) then
                      wterm("greater than ")
                    else
                      wterm("less than -")
                    end
                    print_glue(20000 * Defs::UNITY, glue_order(p)._, 0)
                  else
                    print_glue(round(g * Defs::UNITY), glue_order(p)._, 0)
                  end
                  wterm_cr
                end
                # /204/
                if shift_amount(p)._ != 0 then
                  wterm(indent + "  shift_amount: ")
                  print_scaled(shift_amount(p)._)
                  wterm_cr
                end
                if eTeX_ex then
                  # Never to be reserved? ({1699}):
                  if type(p)._ == Defs::HLIST_NODE \
                  and box_lr(p)._ == Defs::DLIST then
                    wterm_ln(indent + "  subtype: display (never be reserved)")
                  end
                  # /1699/
                end
              end
              wterm_ln(indent + "  ----")
              show_node_list(list_ptr(p)._, indent + "  ", visited)
              wterm_ln(indent + ":]")
              # /202/
            when Defs::RULE_NODE
              # Display rule ({205}):
              wterm_ln(indent + "[:RULE_NODE")
              wterm(indent + "  dimensions ((h + d) * w): (")
              print_rule_dimen(height(p)._)
              wterm(" + ")
              print_rule_dimen(depth(p)._)
              wterm(") * ")
              print_rule_dimen(width(p)._)
              wterm_cr
              wterm_ln(indent + ":]")
              # /205/
            when Defs::INS_NODE
              # Display insertion ({206}):
              wterm_ln(indent + "[:INS_NODE")
              wterm(indent + "  subtype (associated register): ")
              print_int(qo(subtype(p)._))
              wterm_cr
              wterm(indent + "  natural size (height): ")
              print_scaled(height(p)._)
              wterm_cr
              wterm(indent + "  split_top: ")
              print_spec(split_top_ptr(p)._, 0)
              wterm_cr
              wterm(indent + "  depth: ")
              print_scaled(depth(p)._)
              wterm_cr
              wterm(indent + "  float cost: ")
              print_int(float_cost(p)._)
              wterm_cr
              wterm_ln(indent + "  ----")
              show_node_list(ins_ptr(p)._, indent + "  ", visited)
              wterm_ln(indent + ":]")
              # /206/
            when Defs::WHATSIT_NODE
              # Display whatsit ({1598}):
              wterm(indent + "[:WHATSIT_NODE")
              case subtype(p)._
                when Defs::OPEN_NODE
                  wterm_ln("/OPEN_NODE")
                  wterm(indent + "  ")
                  print_write_whatsit(s2i("openout"), p)
                  wterm_cr
                  wterm(indent + "  file name: \"")
                  print_file_name(
                    open_name(p)._, open_area(p)._, open_ext(p)._
                  )
                  wterm_ln("\"")
                when Defs::WRITE_NODE
                  wterm_ln("/WRITE_NODE")
                  wterm(indent + "  ")
                  print_write_whatsit(s2i("write"), p)
                  wterm_cr
                  wterm(indent + "  tokens (mark): ")
                  p_ = write_tokens(p)._
                  if p_ < @hi_mem_min or p_ > @mem_end then
                    wterm_ln("CLOBBERED.")
                  else
                    printer = TokenListPrinter.new \
                      :tex => self, :indent => (indent + " "*4)
                    wterm_ln("{")
                    show_token_list(link(p_)._, printer, 10000)
                    wterm_ln(indent + "  }")
                  end
                when Defs::CLOSE_NODE
                  wterm_ln("/CLOSE_NODE")
                  wterm(indent + "  ")
                  print_write_whatsit(s2i("closeout"), p)
                  wterm_cr
                when Defs::SPECIAL_NODE
                  wterm_ln("/SPECIAL_NODE")
                  if write_stream(p)._ != Defs::MUBYTE_ZERO then
                    wterm(indent + "  write stream: ")
                    z = write_stream(p)._ - Defs::MUBYTE_ZERO
                    print_int(z)
                    wterm_cr
                    if z == 2 or z == 3 then
                      wterm(indent + "  mubyte: ")
                      print_int(write_mubyte(p)._ - Defs::MUBYTE_ZERO)
                      wterm_cr
                    end
                  end
                  wterm(indent + "  tokens (mark): ")
                  p_ = write_tokens(p)._
                  if p_ < @hi_mem_min or p_ > @mem_end then
                    wterm_ln("CLOBBERED.")
                  else
                    printer = TokenListPrinter.new \
                      :tex => self, :indent => (indent + " "*4)
                    wterm_ln("{")
                    show_token_list(link(p_)._, printer, 10000)
                    wterm_ln(indent + "  }")
                  end
                when Defs::LANGUAGE_NODE
                  wterm_ln("/LANGUAGE_NODE")
                  wterm(indent + "  language: ")
                  print_int(what_lang(p)._)
                  wterm_cr
                  wterm(indent + "  hyphenmin (lhm/rhm): ")
                  print_int(what_lhm(p)._)
                  wterm("/")
                  print_int(what_rhm(p)._)
                  wterm_cr
                when Defs::PDF_LITERAL_NODE
                  wterm_ln("/PDF_LITERAL_NODE")
                  wterm(indent + "  pdf literal mode: ")
                  case pdf_literal_mode(p)._
                    when Defs::SET_ORIGIN
                      wterm_ln("SET_ORIGIN")
                    when Defs::DIRECT_PAGE
                      wterm_ln("DIRECT_PAGE")
                    when Defs::DIRECT_ALWAYS
                      wterm_ln("DIRECT_ALWAYS")
                    else
                      @owner.alert "show_node_list: " \
                        "Bad pdf literal mode (#{pdf_literal_mode(p)._})."
                      wterm_ln("???")
                  end
                  wterm(indent + "  data (mark): ")
                  p_ = pdf_literal_data(p)._
                  if p_ < @hi_mem_min or p_ > @mem_end then
                    wterm_ln("CLOBBERED.")
                  else
                    printer = TokenListPrinter.new \
                      :tex => self, :indent => (indent + " "*4)
                    wterm_ln("{")
                    show_token_list(link(p_)._, printer, 10000)
                    wterm_ln(indent + "  }")
                  end
                when Defs::PDF_COLORSTACK_NODE
                  wterm_ln("/PDF_COLORSTACK_NODE")
                  wterm(indent + "  stack: ")
                  print_int(pdf_colorstack_stack(p)._)
                  wterm_cr
                  wterm(indent + "  command: ")
                  case pdf_colorstack_cmd(p)._
                    when Defs::COLORSTACK_SET
                      wterm_ln("set")
                    when Defs::COLORSTACK_PUSH
                      wterm_ln("push")
                    when Defs::COLORSTACK_POP
                      wterm_ln("pop")
                    when Defs::COLORSTACK_CURRENT
                      wterm_ln("current")
                    else
                      @owner.alert "show_node_list: " \
                        "Bad pdf colorstack command (" \
                          "#{pdf_colorstack_cmd(p)._}" \
                        ")."
                      wterm_ln("???")
                  end
                  if pdf_colorstack_cmd(p)._ <= Defs::COLORSTACK_DATA then
                    wterm(indent + "  data (mark): ")
                    p_ = pdf_colorstack_data(p)._
                    if p_ < @hi_mem_min or p_ > @mem_end then
                      wterm_ln("CLOBBERED.")
                    else
                      printer = TokenListPrinter.new \
                        :tex => self, :indent => (indent + " "*4)
                      wterm_ln("{")
                      show_token_list(link(p_)._, printer, 10000)
                      wterm_ln(indent + "  }")
                    end
                  end
                when Defs::PDF_SETMATRIX_NODE
                  wterm_ln("/PDF_SETMATRIX_NODE")
                  wterm(indent + "  data (mark): ")
                  p_ = pdf_setmatrix_data(p)._
                  if p_ < @hi_mem_min or p_ > @mem_end then
                    wterm_ln("CLOBBERED.")
                  else
                    printer = TokenListPrinter.new \
                      :tex => self, :indent => (indent + " "*4)
                    wterm_ln("{")
                    show_token_list(link(p_)._, printer, 10000)
                    wterm_ln(indent + "  }")
                  end
                when Defs::PDF_SAVE_NODE
                  wterm_ln("/PDF_SAVE_NODE")
                when Defs::PDF_RESTORE_NODE
                  wterm_ln("/PDF_RESTORE_NODE")
                when Defs::PDF_REFOBJ_NODE
                  wterm_ln("/PDF_REFOBJ_NODE")
                  if obj_obj_is_stream(pdf_obj_objnum(p)._)._ > 0 then
                    wterm_ln(indent + "  stream:")
                    if obj_obj_stream_attr(pdf_obj_objnum(p)._)._ \
                    != Defs::NULL then
                      wterm(indent + "    attribute (mark): ")
                      p_ = obj_obj_stream_attr(pdf_obj_objnum(p)._)._
                      if p_ < @hi_mem_min or p_ > @mem_end then
                        wterm_ln("CLOBBERED.")
                      else
                        printer = TokenListPrinter.new \
                          :tex => self, :indent => (indent + " "*6)
                        wterm_ln("{")
                        show_token_list(link(p_)._, printer, 10000)
                        wterm_ln(indent + "    }")
                      end
                    end
                  end
                  if obj_obj_is_file(pdf_obj_objnum(p)._)._ > 0 then
                    wterm_ln(indent + "  file:")
                    wterm(indent + "    data (mark): ")
                    p_ = obj_obj_data(pdf_obj_objnum(p)._)._
                    if p_ < @hi_mem_min or p_ > @mem_end then
                      wterm_ln("CLOBBERED.")
                    else
                      printer = TokenListPrinter.new \
                        :tex => self, :indent => (indent + " "*6)
                      wterm_ln("{")
                      show_token_list(link(p_)._, printer, 10000)
                      wterm_ln(indent + "    }")
                    end
                  end
                when Defs::PDF_REFXFORM_NODE
                  wterm_ln("/PDF_REFXFORM_NODE")
                  wterm(indent + "  dimensions ((h + d) * w): (")
                  print_scaled(obj_xform_height(pdf_xform_objnum(p)._)._)
                  wterm(" + ")
                  print_scaled(obj_xform_depth(pdf_xform_objnum(p)._)._)
                  wterm(") * ")
                  print_scaled(obj_xform_width(pdf_xform_objnum(p)._)._)
                  wterm_cr
                when Defs::PDF_REFXIMAGE_NODE
                  wterm_ln("/PDF_REFXIMAGE_NODE")
                  wterm(indent + "  dimensions ((h + d) * w): (")
                  print_scaled(obj_ximage_height(pdf_ximage_objnum(p)._)._)
                  wterm(" + ")
                  print_scaled(obj_ximage_depth(pdf_ximage_objnum(p)._)._)
                  wterm(") * ")
                  print_scaled(obj_ximage_width(pdf_ximage_objnum(p)._)._)
                  wterm_cr
                when Defs::PDF_ANNOT_NODE
                  wterm_ln("/PDF_ANNOT_NODE")
                  wterm(indent + "  dimensions ((h + d) * w): (")
                  print_rule_dimen(pdf_height(p)._)
                  wterm(" + ")
                  print_rule_dimen(pdf_depth(p)._)
                  wterm(") * ")
                  print_rule_dimen(pdf_width(p)._)
                  wterm_cr
                  wterm(indent + "  data (mark): ")
                  p_ = pdf_annot_data(p)._
                  if p_ < @hi_mem_min or p_ > @mem_end then
                    wterm_ln("CLOBBERED.")
                  else
                    printer = TokenListPrinter.new \
                      :tex => self, :indent => (indent + " "*4)
                    wterm_ln("{")
                    show_token_list(link(p_)._, printer, 10000)
                    wterm_ln(indent + "  }")
                  end
                when Defs::PDF_START_LINK_NODE
                  wterm_ln("/PDF_START_LINK_NODE")
                  wterm(indent + "  dimensions ((h + d) * w): (")
                  print_rule_dimen(pdf_height(p)._)
                  wterm(" + ")
                  print_rule_dimen(pdf_depth(p)._)
                  wterm(") * ")
                  print_rule_dimen(pdf_width(p)._)
                  wterm_cr
                  if pdf_link_attr(p)._ != Defs::NULL then
                    wterm(indent + "  attribute (mark): ")
                    p_ = pdf_link_attr(p)._
                    if p_ < @hi_mem_min or p_ > @mem_end then
                      wterm_ln("CLOBBERED.")
                    else
                      printer = TokenListPrinter.new \
                        :tex => self, :indent => (indent + " "*4)
                      wterm_ln("{")
                      show_token_list(link(p_)._, printer, 10000)
                      wterm_ln(indent + "  }")
                    end
                  end
                  if pdf_action_type(pdf_link_action(p)._)._ \
                  == Defs::PDF_ACTION_USER then
                    wterm(indent + "  action user tokens (mark): ")
                    p_ = pdf_action_user_tokens(pdf_link_action(p)._)._
                    if p_ < @hi_mem_min or p_ > @mem_end then
                      wterm_ln("CLOBBERED.")
                    else
                      printer = TokenListPrinter.new \
                        :tex => self, :indent => (indent + " "*4)
                      wterm_ln("{")
                      show_token_list(link(p_)._, printer, 10000)
                      wterm_ln(indent + "  }")
                    end
                  else
                    if pdf_action_file(pdf_link_action(p)._)._ \
                    != Defs::NULL then
                      wterm(indent + "  action file (mark): ")
                      p_ = pdf_action_file(pdf_link_action(p)._)._
                      if p_ < @hi_mem_min or p_ > @mem_end then
                        wterm_ln("CLOBBERED.")
                      else
                        printer = TokenListPrinter.new \
                          :tex => self, :indent => (indent + " "*4)
                        wterm_ln("{")
                        show_token_list(link(p_)._, printer, 10000)
                        wterm_ln(indent + "  }")
                      end
                    end
                    case pdf_action_type(pdf_link_action(p)._)._
                      when Defs::PDF_ACTION_GOTO
                        if pdf_action_named_id(pdf_link_action(p)._)._ > 0 then
                          wterm(indent + "  action goto name (mark): ")
                          p_ = pdf_action_id(pdf_link_action(p)._)._
                          if p_ < @hi_mem_min or p_ > @mem_end then
                            wterm_ln("CLOBBERED.")
                          else
                            printer = TokenListPrinter.new \
                              :tex => self, :indent => (indent + " "*4)
                            wterm_ln("{")
                            show_token_list(link(p_)._, printer, 10000)
                            wterm_ln(indent + "  }")
                          end
                        else
                          wterm(indent + "  action goto num: ")
                          print_int(pdf_action_id(pdf_link_action(p)._)._)
                          wterm_cr
                        end
                      when Defs::PDF_ACTION_PAGE
                        wterm(indent + "  action page ")
                        print_int(pdf_action_id(pdf_link_action(p)._)._)
                        wterm(" tokens (mark): ")
                        p_ = pdf_action_page_tokens(pdf_link_action(p)._)._
                        if p_ < @hi_mem_min or p_ > @mem_end then
                          wterm_ln("CLOBBERED.")
                        else
                          printer = TokenListPrinter.new \
                            :tex => self, :indent => (indent + " "*4)
                          wterm_ln("{")
                          show_token_list(link(p_)._, printer, 10000)
                          wterm_ln(indent + "  }")
                        end
                      when Defs::PDF_ACTION_THREAD
                        if pdf_action_named_id(pdf_link_action(p)._)._ > 0 then
                          wterm(indent + "  action thread name (mark): ")
                          p_ = pdf_action_id(pdf_link_action(p)._)._
                          if p_ < @hi_mem_min or p_ > @mem_end then
                            wterm_ln("CLOBBERED.")
                          else
                            printer = TokenListPrinter.new \
                              :tex => self, :indent => (indent + " "*4)
                            wterm_ln("{")
                            show_token_list(link(p_)._, printer, 10000)
                            wterm_ln(indent + "  }")
                          end
                        else
                          wterm(indent + "  action thread num: ")
                          print_int(pdf_action_id(pdf_link_action(p)._)._)
                          wterm_cr
                        end
                      else
                        @owner.alert "show_node_list: Unknown action type (" \
                          "#{pdf_action_type(pdf_link_action(p)._)._}" \
                        ")."
                        wterm_ln(indent + "  action ???")
                    end
                  end
                when Defs::PDF_END_LINK_NODE
                  wterm_ln("/PDF_END_LINK_NODE")
                when Defs::PDF_DEST_NODE
                  wterm_ln("/PDF_DEST_NODE")
                  if pdf_dest_named_id(p)._ > 0 then
                    wterm(indent + "  name (mark): ")
                    p_ = pdf_dest_id(p)._
                    if p_ < @hi_mem_min or p_ > @mem_end then
                      wterm_ln("CLOBBERED.")
                    else
                      printer = TokenListPrinter.new \
                        :tex => self, :indent => (indent + " "*4)
                      wterm_ln("{")
                      show_token_list(link(p_)._, printer, 10000)
                      wterm_ln(indent + "  }")
                    end
                  else
                    wterm(indent + "  num: ")
                    print_int(pdf_dest_id(p)._)
                    wterm_cr
                  end
                  wterm(indent + "  type: ")
                  case pdf_dest_type(p)._
                    when Defs::PDF_DEST_XYZ
                      wterm("xyz")
                      if pdf_dest_xyz_zoom(p)._ != Defs::NULL then
                        wterm(" zoom [")
                        print_int(pdf_dest_xyz_zoom(p)._)
                        wterm("]")
                      end
                      wterm_cr
                    when Defs::PDF_DEST_FITBH
                      wterm_ln("fitbh")
                    when Defs::PDF_DEST_FITBV
                      wterm_ln("fitbv")
                    when Defs::PDF_DEST_FITB
                      wterm_ln("fitb")
                    when Defs::PDF_DEST_FITH
                      wterm_ln("fith")
                    when Defs::PDF_DEST_FITV
                      wterm_ln("fitv")
                    when Defs::PDF_DEST_FITR
                      wterm("fitr {dimensions ((h + d) * w): (")
                      print_rule_dimen(pdf_height(p)._)
                      wterm(" + ")
                      print_rule_dimen(pdf_depth(p)._)
                      wterm(") * ")
                      print_rule_dimen(pdf_width(p)._)
                      wterm_ln("}")
                    when Defs::PDF_DEST_FIT
                      wterm_ln("fit")
                    else
                      @owner.alert "show_node_list: Unknown pdf dest type (" \
                        "#{pdf_dest_type(p)._}" \
                      ")."
                      wterm_ln("???")
                  end
                when Defs::PDF_THREAD_NODE, Defs::PDF_START_THREAD_NODE
                  if subtype(p)._ == Defs::PDF_THREAD_NODE
                    wterm_ln("/PDF_THREAD_NODE")
                  else
                    wterm_ln("/PDF_START_THREAD_NODE")
                  end
                  wterm(indent + "  dimensions ((h + d) * w): (")
                  print_rule_dimen(pdf_height(p)._)
                  wterm(" + ")
                  print_rule_dimen(pdf_depth(p)._)
                  wterm(") * ")
                  print_rule_dimen(pdf_width(p)._)
                  wterm_cr
                  if pdf_thread_attr(p)._ != Defs::NULL then
                    wterm(indent + "  attribute (mark): ")
                    p_ = pdf_thread_attr(p)._
                    if p_ < @hi_mem_min or p_ > @mem_end then
                      wterm_ln("CLOBBERED.")
                    else
                      printer = TokenListPrinter.new \
                        :tex => self, :indent => (indent + " "*4)
                      wterm_ln("{")
                      show_token_list(link(p_)._, printer, 10000)
                      wterm_ln(indent + "  }")
                    end
                  end
                  if pdf_thread_named_id(p)._ > 0 then
                    wterm(indent + "  name (mark): ")
                    p_ = pdf_thread_id(p)._
                    if p_ < @hi_mem_min or p_ > @mem_end then
                      wterm_ln("CLOBBERED.")
                    else
                      printer = TokenListPrinter.new \
                        :tex => self, :indent => (indent + " "*4)
                      wterm_ln("{")
                      show_token_list(link(p_)._, printer, 10000)
                      wterm_ln(indent + "  }")
                    end
                  else
                    wterm(indent + "  num: ")
                    print_int(pdf_thread_id(p)._)
                    wterm_cr
                  end
                when Defs::PDF_END_THREAD_NODE
                  wterm_ln("/PDF_END_THREAD_NODE")
                when Defs::PDF_SAVE_POS_NODE
                  wterm_ln("/PDF_SAVE_POS_NODE")
                when Defs::PDF_SNAP_REF_POINT_NODE
                  wterm_ln("/PDF_SNAP_REF_POINT_NODE")
                when Defs::PDF_SNAPY_NODE
                  wterm_ln("/PDF_SNAPY_NODE")
                  wterm(indent + "  glue: ")
                  print_spec(snap_glue_ptr(p)._, 0)
                  wterm_cr
                  wterm(indent + "  skip: ")
                  print_spec(final_skip(p)._, 0)
                  wterm_cr
                when Defs::PDF_SNAPY_COMP_NODE
                  wterm_ln("/PDF_SNAPY_COMP_NODE")
                  wterm(indent + "  comp ratio: ")
                  print_int(snapy_comp_ratio(p)._)
                else
                  @owner.alert "show_node_list: What `#{subtype(p)._}' is?"
                  wterm_ln("/???")
              end
              wterm_ln(indent + ":]")
              # /1598/
            when Defs::GLUE_NODE
              # Display glue ({207}):
              wterm_ln(indent + "[:GLUE_NODE")
              if subtype(p)._ >= Defs::A_LEADERS then
                # Display leaders ({208}):
                wterm(indent + "  ")
                if subtype(p)._ == Defs::C_LEADERS then
                  wterm("c")
                elsif subtype(p)._ == Defs::X_LEADERS then
                  wterm("x")
                end
                wterm("leaders: ")
                print_spec(glue_ptr(p)._, 0)
                wterm_cr
                wterm_ln(indent + "  ----")
                show_node_list(leader_ptr(p)._, indent + "  ", visited)
                # /208/
              else
                wterm(indent + "  glue")
                if subtype(p)._ != Defs::NORMAL then
                  wterm(": ")
                  if subtype(p)._ < Defs::COND_MATH_GLUE then
                    print_skip_param(subtype(p)._ - 1)
                  elsif subtype(p)._ == Defs::COND_MATH_GLUE then
                    print_esc(s2i("nonscript"), false)
                  else
                    print_esc(s2i("mskip"), false)
                  end
                end
                if subtype(p)._ != Defs::COND_MATH_GLUE then
                  if subtype(p)._ == Defs::NORMAL then
                    wterm(":")
                  end
                  wterm(" ")
                  if subtype(p)._ < Defs::COND_MATH_GLUE then
                    print_spec(glue_ptr(p)._, 0)
                  else
                    print_spec(glue_ptr(p)._, s2i("mu"))
                  end
                end
                wterm_cr
              end
              wterm_ln(indent + ":]")
              # /207/
            when Defs::MARGIN_KERN_NODE
              wterm_ln(indent + "[:MARGIN_KERN_NODE")
              wterm(indent + "  kern: ")
              print_scaled(width(p)._)
              wterm_cr
              wterm(indent + "  margin: ")
              if subtype(p)._ == Defs::LEFT_SIDE then
                wterm_ln("left")
              else
                wterm_ln("right")
              end
              wterm_ln(indent + ":]")
            when Defs::KERN_NODE
              # Display kern ({209}):
              wterm_ln(indent + "[:KERN_NODE")
              if subtype(p)._ != Defs::MU_GLUE then
                wterm(indent + "  kern")
                if subtype(p)._ == Defs::ACC_KERN then
                  wterm(" (for accent): ")
                else
                  wterm(": ")
                end
                print_scaled(width(p)._)
                wterm_cr
              else
                wterm(indent + "  mkern: ")
                print_scaled(width(p)._)
                wterm_ln("mu")
              end
              wterm_ln(indent + ":]")
              # /209/
            when Defs::MATH_NODE
              # Display math ({210}):
              wterm_ln(indent + "[:MATH_NODE")
              wterm(indent + "  kind: ")
              if subtype(p)._ > Defs::AFTER then
                if end_LR(p) then
                  wterm("end")
                else
                  wterm("begin")
                end
                if subtype(p)._ > Defs::R_CODE then
                  wterm_ln("R")
                elsif subtype(p)._ > Defs::L_CODE then
                  wterm_ln("L")
                else
                  wterm_ln("M")
                end
              else
                wterm("math")
                if subtype(p)._ == Defs::BEFORE then
                  wterm("on")
                else
                  wterm("off")
                end
                if width(p)._ != 0 then
                  wterm(" (surrounded by ")
                  print_scaled(width(p)._)
                  wterm(")")
                end
                wterm_cr
              end
              wterm_ln(indent + ":]")
              # /210/
            when Defs::LIGATURE_NODE
              # Display node ({211}):
              wterm_ln(indent + "[:LIGATURE_NODE")
              print_font_and_char(lig_char(p)._, indent + "  ")
              wterm_ln(indent + "  ligature:")
              if subtype(p)._ > 1 then
                wterm_ln(indent + "  | (implicit left boundary)")
              end
              wterm_ln(indent + "    characters to be ligatured:")
              show_node_list(lig_ptr(p)._, indent + " " * 4, visited)
              if subtype(p)._ & 1 == 1 then
                wterm_ln(indent + "  | (implicit right boundary)")
              end
              wterm_ln(indent + ":]")
              # /211/
            when Defs::PENALTY_NODE
              # Display penalty ({212}):
              wterm_ln(indent + "[:PENALTY_NODE")
              wterm(indent + "  value: ")
              print_int(penalty(p)._)
              wterm_cr
              wterm_ln(indent + ":]")
              # /212/
            when Defs::DISC_NODE
              # Display discretionary ({213}):
              wterm_ln(indent + "[:DISC_NODE")
              wterm(indent + "  replace count: ")
              print_int(replace_count(p)._)
              wterm_cr
              wterm_ln(indent + "  ---- (pre break)")
              show_node_list(pre_break(p)._, indent + "  ", visited)
              wterm_ln(indent + "  ---- (post break)")
              show_node_list(post_break(p)._, indent + "  ", visited)
              wterm_ln(indent + ":]")
              # /213/
            when Defs::MARK_NODE
              # Display mark ({214}):
              wterm_ln(indent + "[:MARK_NODE")
              wterm(indent + "  marks: ")
              print_int(mark_class(p)._)
              wterm_cr
              wterm(indent + "  mark: ")
              p_ = mark_ptr(p)._
              if p_ < @hi_mem_min or p_ > @mem_end then
                wterm_ln("CLOBBERED.")
              else
                printer = TokenListPrinter.new \
                  :tex => self, :indent => (indent + " "*4)
                wterm_ln("{")
                show_token_list(link(p_)._, printer, 10000)
                wterm_ln(indent + "  }")
              end
              wterm_ln(indent + ":]")
              # /214/
            when Defs::ADJUST_NODE
              # Display adjustment ({215}):
              wterm_ln(indent + "[:ADJUST_NODE")
              wterm(indent + "  preadjustment: ")
              print_int(adjust_pre(p)._)
              wterm_cr
              wterm_ln(indent + "  ----")
              show_node_list(adjust_ptr(p)._, indent + "  ", visited)
              wterm_ln(indent + ":]")
              # /215/
            # Mlists ({868}):
            when Defs::STYLE_NODE
              wterm_ln(indent + "[:STYLE_NODE")
              wterm(indent + "  style: ")
              print_style(subtype(p)._)
              wterm_cr
              wterm_ln(indent + ":]")
            when Defs::CHOICE_NODE
              # Display choice ({873}):
              wterm_ln(indent + "[:CHOICE_NODE")
              wterm_ln(indent + "  ---- (display mlist)")
              show_node_list(display_mlist(p)._, indent + "  ", visited)
              wterm_ln(indent + "  ---- (text mlist)")
              show_node_list(text_mlist(p)._, indent + "  ", visited)
              wterm_ln(indent + "  ---- (script mlist)")
              show_node_list(script_mlist(p)._, indent + "  ", visited)
              wterm_ln(indent + "  ---- (script script mlist)")
              show_node_list(script_script_mlist(p)._, indent + "  ", visited)
              wterm_ln(indent + ":]")
              # /873/
            when Defs::ORD_NOAD, Defs::OP_NOAD, Defs::BIN_NOAD, \
            Defs::REL_NOAD, Defs::OPEN_NOAD, Defs::CLOSE_NOAD, \
            Defs::PUNCT_NOAD, Defs::INNER_NOAD, Defs::RADICAL_NOAD, \
            Defs::OVER_NOAD, Defs::UNDER_NOAD, Defs::VCENTER_NOAD, \
            Defs::ACCENT_NOAD, Defs::LEFT_NOAD, Defs::RIGHT_NOAD
              # Display normal noad ({874}):
              wterm(indent + "[:")
              case type(p)._
                when Defs::ORD_NOAD
                  wterm_ln("ORD_NOAD")
                when Defs::OP_NOAD
                  wterm_ln("OP_NOAD")
                when Defs::BIN_NOAD
                  wterm_ln("BIN_NOAD")
                when Defs::REL_NOAD
                  wterm_ln("REL_NOAD")
                when Defs::OPEN_NOAD
                  wterm_ln("OPEN_NOAD")
                when Defs::CLOSE_NOAD
                  wterm_ln("CLOSE_NOAD")
                when Defs::PUNCT_NOAD
                  wterm_ln("PUNCT_NOAD")
                when Defs::INNER_NOAD
                  wterm_ln("INNER_NOAD")
                when Defs::OVER_NOAD
                  wterm_ln("OVER_NOAD")
                when Defs::UNDER_NOAD
                  wterm_ln("UNDER_NOAD")
                when Defs::VCENTER_NOAD
                  wterm_ln("VCENTER_NOAD")
                when Defs::RADICAL_NOAD
                  wterm_ln("RADICAL_NOAD")
                  wterm(indent + "  delimiter: ")
                  print_delimiter(left_delimiter(p)._)
                  wterm_cr
                when Defs::ACCENT_NOAD
                  wterm_ln("ACCENT_NOAD")
                  wterm(indent + "  ")
                  print_fam_and_char(accent_chr(p)._)
                  wterm_cr
                when Defs::LEFT_NOAD
                  wterm_ln("LEFT_NOAD")
                  wterm(indent + "  delimiter: ")
                  print_delimiter(delimiter(p)._)
                  wterm_cr
                when Defs::RIGHT_NOAD
                  wterm_ln("RIGHT_NOAD")
                  wterm(indent + "  kind: ")
                  if subtype(p)._ == Defs::NORMAL then
                    wterm_ln("right")
                  else
                    wterm_ln("middle")
                  end
                  wterm(indent + "  delimiter: ")
                  print_delimiter(delimiter(p)._)
                  wterm_cr
              end
              if type(p)._ < Defs::LEFT_NOAD then
                if subtype(p)._ != Defs::NORMAL then
                  if subtype(p)._ == Defs::LIMIT then
                    wterm_ln(indent + "  ---- (limits)")
                  else
                    wterm_ln(indent + "  ---- (nolimits)")
                  end
                end
                print_subsidiary_data(nucleus(p)._, indent + "  ", visited)
              end
              wterm_ln(indent + "  ---- (superscript)")
              print_subsidiary_data(supscr(p)._, indent + "  ", visited)
              wterm_ln(indent + "  ---- (subscript)")
              print_subsidiary_data(subscr(p)._, indent + "  ", visited)
              wterm_ln(indent + ":]")
              # /874/
            when Defs::FRACTION_NOAD
              # Display fraction noad ({875}):
              wterm_ln(indent + "[:FRACTION_NOAD")
              wterm(indent + "  thickness: ")
              if thickness(p)._ == Defs::DEFAULT_CODE then
                wterm_ln("default")
              else
                print_scaled(thickness(p)._)
                wterm_cr
              end
              if small_fam(left_delimiter(p)._)._ != 0 \
              or small_char(left_delimiter(p)._)._ != Defs::MIN_QUARTERWORD \
              or large_fam(left_delimiter(p)._)._ != 0 \
              or large_char(left_delimiter(p)._)._ != Defs::MIN_QUARTERWORD \
              then
                wterm(indent + "  left delimiter: ")
                print_delimiter(left_delimiter(p)._)
                wterm_cr
              end
              if small_fam(right_delimiter(p)._)._ != 0 \
              or small_char(right_delimiter(p)._)._ != Defs::MIN_QUARTERWORD \
              or large_fam(right_delimiter(p)._)._ != 0 \
              or large_char(right_delimiter(p)._)._ != Defs::MIN_QUARTERWORD \
              then
                wterm(indent + "  right delimiter: ")
                print_delimiter(right_delimiter(p)._)
                wterm_cr
              end
              wterm_ln(indent + "  ---- (numerator)")
              print_subsidiary_data(numerator(p)._, indent + "  ", visited)
              wterm_ln(indent + "  ---- (denominator)")
              print_subsidiary_data(denominator(p)._, indent + "  ", visited)
              wterm_ln(indent + ":]")
              # /875/
            # /868/
            else
              wterm_ln(indent + "[:???:]")
          end # case
        end # if
        # /201/
        p = link(p)._
      end
    end
    private :show_node_list

    def show_memory_location(m)
      s = "%08X:" % m
      @mem[m]._.unpack("C*").each {|x| s += " %02X" % x}
      wterm_ln(s)
    end

    def show_page_ins
      wake_up_terminal
      show_memory_location(page_ins_head)
      wterm_ln("Page insertions:")
      r = link(page_ins_head)._
      while r != page_ins_head do
        print_esc(s2i("insert"), false)
        t = qo(subtype(r)._)
        print_int(t)
        wterm(" adds ")
        if count(t)._ == 1000 then
          t = height(r)._
        else
          t = x_over_n(height(r)._, 1000)[0] * count(t)._
        end
        print_scaled(t)
        if type(r)._ == Defs::SPLIT_UP then
          q = page_head
          t = 0
          loop do
            q = link(q)._
            if type(q)._ == Defs::INS_NODE \
            and subtype(q)._ == subtype(r)._ then
              t += 1
            end
            break if q == broken_ins(r)._
          end
          wterm(", #")
          print_int(t)
          wterm(" might split")
        end
        wterm_cr
      end
      update_terminal
    end

    def show_contrib
      wake_up_terminal
      show_memory_location(contrib_head)
      wterm_ln("Page contribution list:")
      if link(contrib_head)._ != Defs::NULL then
        show_node_list(link(contrib_head)._, "  ", [])
      end
      update_terminal
    end

    def show_page
      wake_up_terminal
      show_memory_location(page_head)
      wterm_ln("Current page list:")
      if link(page_head)._ != Defs::NULL then
        show_node_list(link(page_head)._, "  ", [])
      end
      update_terminal
    end

    def show_temp
      wake_up_terminal
      show_memory_location(temp_head)
      wterm_ln("Temporary list:")
      if link(temp_head)._ != Defs::NULL then
        show_node_list(link(temp_head)._, "  ", [])
      end
      update_terminal
    end

    def show_ttemp
      printer = TokenListPrinter.new :tex => self, :indent => "  "
      wake_up_terminal
      show_memory_location(temp_head)
      wterm_ln("Temporary (token) list:")
      if link(temp_head)._ != Defs::NULL then
        show_token_list(link(temp_head)._, printer, 10000)
      end
      update_terminal
    end

    def show_hold
      wake_up_terminal
      show_memory_location(hold_head)
      wterm_ln("Hold list:")
      if link(hold_head)._ != Defs::NULL then
        show_node_list(link(hold_head)._, "  ", [])
      end
      update_terminal
    end

    def show_thold
      printer = TokenListPrinter.new :tex => self, :indent => "  "
      wake_up_terminal
      show_memory_location(hold_head)
      wterm_ln("Hold (token) list:")
      if link(hold_head)._ != Defs::NULL then
        show_token_list(link(hold_head)._, printer, 10000)
      end
      update_terminal
    end

    def show_adjust
      wake_up_terminal
      show_memory_location(adjust_head)
      wterm_ln("Adjustment list:")
      if link(adjust_head)._ != Defs::NULL then
        show_node_list(link(adjust_head)._, "  ", [])
      end
      update_terminal
    end

    def show_active
      wake_up_terminal
      show_memory_location(active)
      show_memory_location(active + 1)
      wterm_ln("Active break nodes list:")
      r = active
      while link(r)._ != Defs::NULL do
        r = link(r)._
        case type(r)._
          when Defs::HYPHENATED, Defs::UNHYPHENATED
            wterm_ln("  [[ACTIVE_NODE")
            wterm("    Type: ")
            if type(r)._ == Defs::HYPHENATED then
              wterm_ln("hyphenated")
            else
              wterm_ln("unhyphenated")
            end
            wterm("    Line number: ")
            print_int(line_number(r)._)
            wterm_cr
            wterm("    Fitness: ")
            wterm_ln([
              'very loose fit', 'loose fit', 'decent fit', 'tight fit'
            ][fitness(r)._])
            wterm("    Total demerits: ")
            print_int(total_demerits(r)._)
            wterm_cr
            if break_node(r)._ != Defs::NULL then
              b = break_node(r)._
              wterm_ln("    Associated pasive node:")
              wterm("    - serial number: ")
              print_int(serial(b)._)
              wterm_cr
              wterm("    - previous passive node: ")
              if link(b)._ == Defs::NULL then
                wterm_ln("NULL")
              else
                print_int(link(b)._)
                wterm_ln(" (#{link(b)._.to_s(16)})")
              end
              wterm("    - current break: ")
              if cur_break(b)._ == Defs::NULL then
                wterm_ln("NULL")
              else
                print_int(cur_break(b)._)
                wterm_ln(" (#{cur_break(b)._.to_s(16)})")
              end
              wterm("    - previous break: ")
              if prev_break(b)._ == Defs::NULL then
                wterm_ln("NULL")
              else
                print_int(prev_break(b)._)
                wterm_ln(" (#{prev_break(b)._.to_s(16)})")
              end
            end
            wterm_ln("  ]]")
          when Defs::DELTA_NODE
            wterm_ln("  [[DELTA_NODE")
            wterm("    Natural width difference: ")
            print_scaled(@mem[r + 1].sc._)
            wterm_cr
            wterm("    Stretch differences: ")
            print_scaled(@mem[r + 2].sc._)
            wterm("pt ")
            print_scaled(@mem[r + 3].sc._)
            wterm("fil ")
            print_scaled(@mem[r + 4].sc._)
            wterm("fill ")
            print_scaled(@mem[r + 5].sc._)
            wterm_ln("filll")
            wterm("    Shrink difference: ")
            print_scaled(@mem[r + 6].sc._)
            wterm_cr
            wterm_ln("  ]]")
          else
            wterm_ln("  [[???]]")
        end
        break if r == active
      end
      update_terminal
    end

    def show_align
      wake_up_terminal
      show_memory_location(align_head)
      wterm_ln("Align list:")
      if link(align_head)._ != Defs::NULL then
        show_node_list(link(align_head)._, "  ", [])
      end
      update_terminal
    end

    def show_end_span
      wake_up_terminal
      show_memory_location(end_span)
      wterm_ln("End span:")
      wterm("- link: ")
      print_int(link(end_span)._)
      wterm_cr
      wterm("- info: ")
      print_int(info(end_span)._)
      wterm_cr
      update_terminal
    end

    def show_omit_template
      printer = TokenListPrinter.new :tex => self, :indent => "  "
      wake_up_terminal
      show_memory_location(omit_template)
      wterm_ln("Omit template token list:")
      show_token_list(omit_template, printer, 10000)
      update_terminal
    end

    # {270}:
    def show_eqtb(n)
      printer = TokenListPrinter.new :tex => self, :indent => (" " * 5)
      wake_up_terminal
      wterm_ln("Equivalents table's item no. #{n}:")
      if n >= Defs::ACTIVE_BASE and n <= @eqtb_top then
        wterm_ln("* eq_type(#{n}) = #{eq_type(n)._.to_s(16)}")
        wterm_ln("* eq_level(#{n}) = #{eq_level(n)._.to_s(16)}")
        wterm_ln("* equiv(#{n}) = #{equiv(n)._.to_s(16)}")
      end
      if n < Defs::ACTIVE_BASE then
        @owner.alert "No eqtb item at #{n}."
      elsif n < Defs::GLUE_BASE \
      or (n > Defs::EQTB_SIZE and n <= @eqtb_top) then
        # Region 1 or 2 ({241}):
        wterm_ln(" - Region: 1 or 2 (control sequences)")
        wterm(" - Item name: ")
        sprint_cs(n)
        wterm_cr
        wterm(" - Control sequence name: ")
        print_cmd_chr(eq_type(n)._, equiv(n)._)
        wterm_cr
        if eq_type(n)._ >= Defs::CALL then
          wterm_ln(" - Token list:")
          show_token_list(link(equiv(n)._)._, printer, 10000)
        end
      elsif n < Defs::LOCAL_BASE then
        # Region 3 ({247}):
        wterm_ln(" - Region: 3 (glue or muglue registers)")
        wterm(" - Register: ")
        if n < Defs::SKIP_BASE then
          print_skip_param(n - Defs::GLUE_BASE)
          wterm("=")
          if n < Defs::GLUE_BASE + Defs::THIN_MU_SKIP_CODE then
            print_spec(equiv(n)._, s2i("pt"))
          else
            print_spec(equiv(n)._, s2i("mu"))
          end
        elsif n < Defs::MU_SKIP_BASE then
          print_esc(s2i("skip"), false)
          print_int(n - Defs::SKIP_BASE)
          wterm("=")
          print_spec(equiv(n)._, s2i("pt"))
        else
          print_esc(s2i("muskip"), false)
          print_int(n - Defs::MU_SKIP_BASE)
          wterm("=")
          print_spec(equiv(n)._, s2i("mu"))
        end
        wterm_cr
      elsif n < Defs::INT_BASE then
        # Region 4 ({251}):
        wterm_ln(" - Region: 4 (penalties, toklists, boxes, codes, fonts)")
        if n == Defs::PAR_SHAPE_LOC \
        or (n >= Defs::ETEX_PEN_BASE and n < Defs::ETEX_PENS) then
          if n == Defs::PAR_SHAPE_LOC then
            wterm(" - Paragraph shape: ")
          else
            wterm(" - Penalties: ")
          end
          print_cmd_chr(Defs::SET_SHAPE, n)
          wterm("=")
          if equiv(n)._ == Defs::NULL then
            wterm("0")
          elsif n > Defs::PAR_SHAPE_LOC then
            np = penalty(equiv(n)._)._
            print_int(np)
            i = 1
            while np > 0 do
              wterm(" ")
              print_int(penalty(equiv(n)._ + i)._)
              i += 1
              np -= 1
            end
          else
            q = par_shape_ptr._
            np = info(q)._
            print_int(np)
            i = 1
            while np > 0 do
              wterm(" (")
              print_scaled(@mem[q + 2*i - 1].sc._) # indentation
              wterm(", ")
              print_scaled(@mem[q + 2*i].sc._) # width
              wterm(")")
              i += 1
              np -= 1
            end
          end
          wterm_cr
        elsif n < Defs::TOKS_BASE then
          wterm(" - Token list name: ")
          print_cmd_chr(Defs::ASSIGN_TOKS, n)
          wterm_cr
          if equiv(n)._ != Defs::NULL then
            wterm_ln(" - Token list:")
            show_token_list(link(equiv(n)._)._, printer, 10000)
          end
        elsif n < Defs::BOX_BASE then
          wterm(" - Toks register: ")
          print_esc(s2i("toks"), false)
          print_int(n - Defs::TOKS_BASE)
          wterm_cr
          if equiv(n)._ != Defs::NULL then
            wterm_ln(" - Token list:")
            show_token_list(link(equiv(n)._)._, printer, 10000)
          end
        elsif n < Defs::CUR_FONT_LOC then
          wterm(" - Box register: ")
          print_esc(s2i("box"), false)
          print_int(n - Defs::BOX_BASE)
          if equiv(n)._ == Defs::NULL then
            wterm_ln("=void")
          else
            wterm_cr
            wterm_ln(" - Node list:")
            show_node_list(equiv(n)._, " " * 5, [])
          end
        elsif n == Defs::XORD_CODE_BASE then
          wterm_ln(" - \\xordcode slot (reserved/unused)")
        elsif n == Defs::XCHR_CODE_BASE then
          wterm_ln(" - \\xchrcode slot (reserved/unused)")
        elsif n == Defs::XPRN_CODE_BASE then
          wterm_ln(" - \\xprncode slot (reserved/unused)")
        elsif n < Defs::CAT_CODE_BASE then
          # Font identifier ({252}):
          wterm(" - Font identifier: ")
          if n == Defs::CUR_FONT_LOC then
            wterm("<current font>")
          elsif n < Defs::MATH_FONT_BASE + 16 then
            print_esc(s2i("textfont"), false)
            print_int(n - Defs::MATH_FONT_BASE)
          elsif n < Defs::MATH_FONT_BASE + 32 then
            print_esc(s2i("scriptfont"), false)
            print_int(n - Defs::MATH_FONT_BASE - 16)
          else
            print_esc(s2i("scriptscriptfont"), false)
            print_int(n - Defs::MATH_FONT_BASE - 32)
          end
          wterm("=")
          print_esc(@hash[Defs::FONT_ID_BASE + equiv(n)._].rh._, false)
          wterm_cr
          # /252/
        else
          # Halfword ({253}):
          wterm(" - Code: ")
          if n < Defs::MATH_CODE_BASE then
            if n < Defs::LC_CODE_BASE then
              print_esc(s2i("catcode"), false)
              print_int(n - Defs::CAT_CODE_BASE)
            elsif n < Defs::UC_CODE_BASE then
              print_esc(s2i("lccode"), false)
              print_int(n - Defs::LC_CODE_BASE)
            elsif n < Defs::SF_CODE_BASE then
              print_esc(s2i("uccode"), false)
              print_int(n - Defs::UC_CODE_BASE)
            else
              print_esc(s2i("sfcode"), false)
              print_int(n - Defs::SF_CODE_BASE)
            end
            wterm("=")
            print_int(equiv(n)._)
          else
            if n < Defs::CHAR_SUB_CODE_BASE then
              print_esc(s2i("mathcode"), false)
              print_int(n - Defs::MATH_CODE_BASE)
            else
              print_esc(s2i("charsubdef"), false)
              print_int(n - Defs::MATH_CODE_BASE)
            end
            wterm("=")
            print_int(ho(equiv(n)._))
          end
          wterm_cr
          # /253/
        end
      elsif n < Defs::DIMEN_BASE then
        # Region 5 ({260}):
        wterm_ln(" - Region: 5 (parameters, counts, delcodes)")
        if n < Defs::COUNT_BASE then
          wterm(" - Parameter: ")
          print_param(n - Defs::INT_BASE)
        elsif n < Defs::DEL_CODE_BASE then
          wterm(" - Count register: ")
          print_esc(s2i("count"), false)
          print_int(n - Defs::COUNT_BASE)
        else
          wterm(" - Delcode register: ")
          print_esc(s2i("delcode"), false)
          print_int(n - Defs::DEL_CODE_BASE)
        end
        wterm("=")
        print_int(@eqtb[n].int._)
        wterm_cr
      elsif n <= Defs::EQTB_SIZE then
        # Region 6 ({269}):
        wterm_ln(" - Region: 6 (lengths, dimensions)")
        if n < Defs::SCALED_BASE then
          wterm(" - Length parameter: ")
          print_length_param(n - Defs::DIMEN_BASE)
        else
          wterm(" - Dimension register: ")
          print_esc(s2i("dimen"), false)
          print_int(n - Defs::SCALED_BASE)
        end
        wterm("=")
        print_scaled(@eqtb[n].sc._)
        wterm_ln("pt")
      else
        wterm_ln(" - ???")
      end
      update_terminal
    end

    def list_actives
      wake_up_terminal
      wterm_ln("Active characters:")
      ((Defs::ACTIVE_BASE)..(Defs::SINGLE_BASE - 1)).each do |n|
        if equiv(n)._ != Defs::NULL or eq_level(n)._ != 0 then
          wterm("#{n}: ")
          sprint_cs(n)
          wterm(", ")
          print_cmd_chr(eq_type(n)._, equiv(n)._)
          wterm_cr
        end
      end
      update_terminal
    end

    def list_singles
      wake_up_terminal
      wterm_ln("Single-character control sequences:")
      ((Defs::SINGLE_BASE)..(Defs::NULL_CS - 1)).each do |n|
        if equiv(n)._ != Defs::NULL or eq_level(n)._ != 0 then
          wterm("#{n}: ")
          sprint_cs(n)
          wterm(", ")
          print_cmd_chr(eq_type(n)._, equiv(n)._)
          wterm_cr
        end
      end
      update_terminal
    end

    def list_hash
      wake_up_terminal
      wterm_ln("Multi-letter control sequences:")
      ((Defs::NULL_CS)..(Defs::GLUE_BASE - 1)).each do |n|
        if equiv(n)._ != Defs::NULL or eq_level(n)._ != 0 then
          wterm("#{n}: ")
          sprint_cs(n)
          wterm(", ")
          print_cmd_chr(eq_type(n)._, equiv(n)._)
          wterm_cr
        end
      end
      ((Defs::EQTB_SIZE + 1)..@eqtb_top).each do |n|
        if equiv(n)._ != Defs::NULL or eq_level(n)._ != 0 then
          wterm("#{n}: ")
          sprint_cs(n)
          wterm(", ")
          print_cmd_chr(eq_type(n)._, equiv(n)._)
          wterm_cr
        end
      end
      update_terminal
    end

    def list_glues
      wake_up_terminal
      wterm_ln("Glue registers:")
      ((Defs::GLUE_BASE)..(Defs::SKIP_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_skip_param(n - Defs::GLUE_BASE)
        wterm("=")
        if n < Defs::GLUE_BASE + Defs::THIN_MU_SKIP_CODE then
          print_spec(equiv(n)._, s2i("pt"))
        else
          print_spec(equiv(n)._, s2i("mu"))
        end
        wterm_cr
      end
      update_terminal
    end

    def list_skips
      wake_up_terminal
      wterm_ln("Skip registers:")
      ((Defs::SKIP_BASE)..(Defs::MU_SKIP_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("skip"), false)
        print_int(n - Defs::SKIP_BASE)
        wterm("=")
        print_spec(equiv(n)._, s2i("pt"))
        wterm_cr
      end
      update_terminal
    end

    def list_muskips
      wake_up_terminal
      wterm_ln("mu-Skip registers:")
      ((Defs::MU_SKIP_BASE)..(Defs::LOCAL_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("muskip"), false)
        print_int(n - Defs::MU_SKIP_BASE)
        wterm("=")
        print_spec(equiv(n)._, s2i("mu"))
        wterm_cr
      end
      update_terminal
    end

    def show_parshape
      wake_up_terminal
      wterm_ln("Paragraph shape:")
      wterm("#{Defs::PAR_SHAPE_LOC}: ")
      print_cmd_chr(Defs::SET_SHAPE, Defs::PAR_SHAPE_LOC)
      wterm("=")
      if equiv(Defs::PAR_SHAPE_LOC)._ == Defs::NULL then
        wterm("0")
      else
        q = par_shape_ptr._
        np = info(q)._
        print_int(np)
        i = 1
        while np > 0 do
          wterm(" (")
          print_scaled(@mem[q + 2*i - 1].sc._) # indentation
          wterm(", ")
          print_scaled(@mem[q + 2*i].sc._) # width
          wterm(")")
          i += 1
          np -= 1
        end
      end
      wterm_cr
      update_terminal
    end

    def list_assign_toks
      wake_up_terminal
      wterm_ln("Assign toks:")
      ((Defs::PAR_SHAPE_LOC + 1)..(Defs::TOKS_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_cmd_chr(Defs::ASSIGN_TOKS, n)
        wterm("=")
        if equiv(n)._ != Defs::NULL then
          wterm_ln("...")
        else
          wterm_ln("null")
        end
      end
      update_terminal
    end

    def list_toks
      wake_up_terminal
      wterm_ln("Toks registers:")
      ((Defs::TOKS_BASE)..(Defs::ETEX_PEN_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("toks"), false)
        print_int(n - Defs::TOKS_BASE)
        wterm("=")
        if equiv(n)._ != Defs::NULL then
          wterm_ln("...")
        else
          wterm_ln("null")
        end
      end
      update_terminal
    end

    def list_penalties
      wake_up_terminal
      wterm_ln("Penalties:")
      ((Defs::ETEX_PEN_BASE)..(Defs::BOX_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_cmd_chr(Defs::SET_SHAPE, n)
        wterm("=")
        if equiv(n)._ == Defs::NULL then
          wterm("0")
        else
          np = penalty(equiv(n)._)._
          print_int(np)
          i = 1
          while np > 0 do
            wterm(" ")
            print_int(penalty(equiv(n)._ + i)._)
            i += 1
            np -= 1
          end
        end
        wterm_cr
      end
      update_terminal
    end

    def list_boxes
      wake_up_terminal
      wterm_ln("Box registers:")
      ((Defs::BOX_BASE)..(Defs::CUR_FONT_LOC - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("box"), false)
        print_int(n - Defs::BOX_BASE)
        wterm("=")
        if equiv(n)._ == Defs::NULL then
          wterm_ln("void")
        else
          wterm_ln("[...]")
        end
      end
      update_terminal
    end

    def show_current_font
      wake_up_terminal
      wterm_ln("Current font:")
      wterm("#{Defs::CUR_FONT_LOC}: ")
      wterm("<current font>")
      wterm("=")
      print_esc(@hash[Defs::FONT_ID_BASE + equiv(Defs::CUR_FONT_LOC)._].rh._)
      wterm_cr
      update_terminal
    end

    def list_xcodes
      wake_up_terminal
      wterm_ln("X-codes:")
      wterm_ln("#{Defs::XORD_CODE_BASE}: \\xordcode slot (reserved/unused)")
      wterm_ln("#{Defs::XCHR_CODE_BASE}: \\xchrcode slot (reserved/unused)")
      wterm_ln("#{Defs::XPRN_CODE_BASE}: \\xprncode slot (reserved/unused)")
      update_terminal
    end

    def list_fonts
      wake_up_terminal
      wterm_ln("Font identifiers:")
      ((Defs::MATH_FONT_BASE)..(Defs::CAT_CODE_BASE - 1)).each do |n|
        wterm("#{n}: ")
        if n < Defs::MATH_FONT_BASE + 16 then
          print_esc(s2i("textfont"), false)
          print_int(n - Defs::MATH_FONT_BASE)
        elsif n < Defs::MATH_FONT_BASE + 32 then
          print_esc(s2i("scriptfont"), false)
          print_int(n - Defs::MATH_FONT_BASE - 16)
        else
          print_esc(s2i("scriptscriptfont"), false)
          print_int(n - Defs::MATH_FONT_BASE - 32)
        end
        wterm("=")
        print_esc(@hash[Defs::FONT_ID_BASE + equiv(n)._].rh._)
        wterm_cr
      end
      update_terminal
    end

    def list_catcodes
      wake_up_terminal
      wterm_ln("Category codes:")
      ((Defs::CAT_CODE_BASE)..(Defs::LC_CODE_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("catcode"), false)
        print_int(n - Defs::CAT_CODE_BASE)
        wterm("=")
        print_int(equiv(n)._)
        wterm(" (")
        wterm([
          'escape', 'begin group', 'end group', 'math switch',
          'tab align', 'end of line', 'macro parameter', 'superscript',
          'subscript', 'ignore', 'space', 'letter',
          'other', 'active', 'comment', 'illegal'
        ][equiv(n)._])
        wterm_ln(")")
      end
      update_terminal
    end

    def list_lccodes
      wake_up_terminal
      wterm_ln("LC codes:")
      ((Defs::LC_CODE_BASE)..(Defs::UC_CODE_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("lccode"), false)
        print_int(n - Defs::LC_CODE_BASE)
        wterm("=")
        print_int(equiv(n)._)
        wterm_cr
      end
      update_terminal
    end

    def list_uccodes
      wake_up_terminal
      wterm_ln("UC codes:")
      ((Defs::UC_CODE_BASE)..(Defs::SF_CODE_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("uccode"), false)
        print_int(n - Defs::UC_CODE_BASE)
        wterm("=")
        print_int(equiv(n)._)
        wterm_cr
      end
      update_terminal
    end

    def list_sfcodes
      wake_up_terminal
      wterm_ln("SF codes:")
      ((Defs::SF_CODE_BASE)..(Defs::MATH_CODE_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("sfcode"), false)
        print_int(n - Defs::SF_CODE_BASE)
        wterm("=")
        print_int(equiv(n)._)
        wterm_cr
      end
      update_terminal
    end

    def list_mathcodes
      wake_up_terminal
      wterm_ln("Math codes:")
      ((Defs::MATH_CODE_BASE)..(Defs::CHAR_SUB_CODE_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("mathcode"), false)
        print_int(n - Defs::MATH_CODE_BASE)
        wterm("=")
        print_int(ho(equiv(n)._))
        wterm_cr
      end
      update_terminal
    end

    def list_charsubs
      wake_up_terminal
      wterm_ln("Character substitution codes:")
      ((Defs::CHAR_SUB_CODE_BASE)..(Defs::INT_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("charsubdef"), false)
        print_int(n - Defs::CHAR_SUB_CODE_BASE)
        wterm("=")
        print_int(ho(equiv(n)._))
        wterm_cr
      end
      update_terminal
    end

    def list_intpars
      wake_up_terminal
      wterm_ln("Integer parameters:")
      ((Defs::INT_BASE)..(Defs::COUNT_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_param(n - Defs::INT_BASE)
        wterm("=")
        print_int(@eqtb[n].int._)
        wterm_cr
      end
      update_terminal
    end

    def list_counts
      wake_up_terminal
      wterm_ln("Count registers:")
      ((Defs::COUNT_BASE)..(Defs::DEL_CODE_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("count"), false)
        print_int(n - Defs::COUNT_BASE)
        wterm("=")
        print_int(@eqtb[n].int._)
        wterm_cr
      end
      update_terminal
    end

    def list_dels
      wake_up_terminal
      wterm_ln("Del codes:")
      ((Defs::DEL_CODE_BASE)..(Defs::DIMEN_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("delcode"), false)
        print_int(n - Defs::DEL_CODE_BASE)
        wterm("=")
        print_int(@eqtb[n].int._)
        wterm_cr
      end
      update_terminal
    end

    def list_lengths
      wake_up_terminal
      wterm_ln("Length parameters:")
      ((Defs::DIMEN_BASE)..(Defs::SCALED_BASE - 1)).each do |n|
        wterm("#{n}: ")
        print_length_param(n - Defs::DIMEN_BASE)
        wterm("=")
        print_scaled(@eqtb[n].sc._)
        wterm_ln("pt")
      end
      update_terminal
    end

    def list_dimens
      wake_up_terminal
      wterm_ln("Length parameters:")
      ((Defs::SCALED_BASE)..(Defs::EQTB_SIZE)).each do |n|
        wterm("#{n}: ")
        print_esc(s2i("dimen"), false)
        print_int(n - Defs::SCALED_BASE)
        wterm("=")
        print_scaled(@eqtb[n].sc._)
        wterm_ln("pt")
      end
      update_terminal
    end

    # {314}:
    def show_token_list(p, pt, l)
      limit = 0
      n = 0
      while p != Defs::NULL and limit < l do
        if p < @hi_mem_min or p > @mem_end then
          pt.printmsg("CLOBERRED.")
          return
        end
        if info(p)._ >= Defs::CS_TOKEN_FLAG then
          pt.print_cs(info(p)._ - Defs::CS_TOKEN_FLAG)
        else
          m = info(p)._ >> 8 # / 0400
          c = info(p)._ & 255 # % 0400
          if info(p)._ < 0 then
            pt.printmsg("BAD.")
            return
          else
            case m
              when Defs::LEFT_BRACE
                pt.printtok('LEFT_BRACE', c)
                pt.indent
              when Defs::RIGHT_BRACE
                pt.dedent
                pt.printtok('RIGHT_BRACE', c)
              when Defs::MATH_SHIFT
                pt.printtok('MATH_SHIFT', c)
              when Defs::TAB_MARK
                pt.printtok('TAB_MARK', c)
              when Defs::SUP_MARK
                pt.printtok('SUP_MARK', c)
              when Defs::SUB_MARK
                pt.printtok('SUB_MARK', c)
              when Defs::SPACER
                pt.printtok('SPACER', c)
              when Defs::LETTER
                pt.printtok('LETTER', c)
              when Defs::OTHER_CHAR
                pt.printtok('OTHER_CHAR', c)
              when Defs::MAC_PARAM
                pt.printtok('MAC_PARAM', c)
              when Defs::OUT_PARAM
                if c < 1 or c > 9 then
                  @owner.alert \
                    "show_token_list: Invalid parameter number (#{c})."
                  return
                end
                pt.printstok('OUT_PARAM', c)
              when Defs::MATCH
                if n > 9 then
                  @owner.alert "show_token_list: Too many #'s."
                  return
                end
                n += 1
                pt.printtok('MATCH #' "#{n}", c)
              when Defs::END_MATCH
                pt.printstok('END_MATCH', c)
                if c == 0 then
                  wterm_cr
                  pt.printmsg("### MACRO BODY ###")
                  wterm_cr
                end
              else
                pt.printmsg("BAD.")
                return
            end
          end
        end
        p = link(p)._
        limit += 1
      end
      if p != Defs::NULL then
        pt.printmsg("ETC.")
      end
    end
    private :show_token_list

    # -------------------------------------------------------------------------
    # -- String management
    # --
    def make_pdftex_banner
      make_tex_string(
        "#{@ptexbanner}#{@versionstring} #{@kpathsea_version_string}"
      )
    end
    private :make_pdftex_banner

    def make_tex_string(s)
      if s == nil then
        return s2i("")
      end
      if @str_str_num_hash[s] != nil then
        return @str_str_num_hash[s]
      end
      if @pool_ptr + s.size > @pool_size then
        raise OverflowError.new "No room for #{s.dump} in 'str_pool' array."
      end
      @str_pool[@pool_ptr, s.size] = s
      @pool_ptr += s.size
      last_tex_string = make_string
      @str_str_num_hash[s] = last_tex_string
      return last_tex_string
    end
    private :make_tex_string

    def make_string
      if @str_ptr == @max_strings then
        raise OverflowError.new(
          "The maximal limit of free slots for strings (" \
            "#{@max_strings - @init_str_ptr}" \
          ") was exhausted."
        )
      end
      @str_ptr += 1
      @str_start[@str_ptr]._ = @pool_ptr
      return @str_ptr - 1
    end
    private :make_string

    def str_eq_str(s, t)
      if length(s) != length(t)
        return false
      end
      j = @str_start[s]._
      k = @str_start[t]._
      while j < @str_start[s + 1]._ do
        if @str_pool[j]._ != @str_pool[k]._
          return false
        end
        j += 1
        k += 1
      end
      return true
    end
    private :str_eq_str

    # {40}:
    def length(x)
      @str_start[x + 1]._ - @str_start[x]._
    end
    private :length

    # {41}:
    def cur_length
      @pool_ptr - @str_start[@str_ptr]._
    end
    private :cur_length

    # {42:}
    def append_char(x)
      @str_pool[@pool_ptr]._ = si(x)
      @pool_ptr += 1
    end
    private :append_char

    def flush_char
      @pool_ptr -= 1
    end
    private :flush_char

    def str_room(x)
      if @pool_ptr + x > @pool_size
        raise OverflowError.new "No room in 'str_pool' array left."
      end
    end
    private :str_room

    # {44}:
    def flush_string
      @str_ptr -= 1
      @pool_ptr = @str_start[@str_ptr]._
    end
    private :flush_string

    # {48}:
    def app_lc_hex(x)
      if x < 10
        append_char(x + "0".ord)
      else
        append_char(x - 10 + "a".ord)
      end
    end
    private :app_lc_hex

    def s2i(s)
      if @str_str_num_hash[s] == nil then
        raise IndexError.new "#{s.dump} is not in 'str_pool' array."
      end
      @str_str_num_hash[s]
    end
    private :s2i

    # -------------------------------------------------------------------------
    # -- Utilities
    # --
    def i2b(x)
      [x].pack(CPascal::IntType::PACKER)
    end
    private :i2b

    # {16}:
    def negate(x)
      -x
    end
    private :negate

    def do_nothing
    end
    private :do_nothing

    # {38}:
    def si(x)
      x
    end
    private :si

    def so(x)
      x
    end
    private :so

    # {106}:
    def x_over_n(x, n)
      sign = 1
      if n == 0 then
        raise ArithError.new "Division by zero."
      end
      if n < 0 then
        x = negate(x)
        n = negate(n)
        sign = -1
      end
      if x < 0 then
        return [-((-x) / n), (-((-x) % n))*sign]
      end
      [x / n, (x % n)*sign]
    end

    # {109}:
    def float(x)
      x
    end
    private :float

    def unfloat(x)
      x
    end
    private :unfloat

    def float_constant(x)
      x + 0.0
    end
    private :float_constant

    def round(x)
      CPascal::round(x)
    end
    private :round

    # {130}:
    def qi(x)
      x
    end
    private :qi

    def qo(x)
      x
    end
    private :qo

    def hi(x)
      x
    end
    private :hi

    def ho(x)
      x
    end
    private :ho

    # -------------------------------------------------------------------------
    # -- Memory access
    # --
    # {136}:
    def link(x)
      @mem[x].hh.rh
    end

    def info(x)
      @mem[x].hh.lh
    end

    # {142}:
    def is_empty(x)
      link(x)._ == Defs::EMPTY_FLAG
    end

    def node_size(x)
      info(x)
    end

    def llink(x)
      info(x + 1)
    end

    def rlink(x)
      link(x + 1)
    end

    # {151}:
    def type(x)
      @mem[x].hh.b0
    end

    def subtype(x)
      @mem[x].hh.b1
    end

    # {152}:
    def is_char_node(x)
      x >= @hi_mem_min
    end

    def font(x)
      type(x)
    end

    def character(x)
      subtype(x)
    end

    # {153}:
    def sync_tag(x)
      @mem[x - Defs::SYNCTEX_FIELD_SIZE].int
    end

    def sync_line(x)
      @mem[x - Defs::SYNCTEX_FIELD_SIZE + 1].int
    end

    def width(x)
      @mem[x + Defs::WIDTH_OFFSET].sc
    end

    def depth(x)
      @mem[x + Defs::DEPTH_OFFSET].sc
    end

    def height(x)
      @mem[x + Defs::HEIGHT_OFFSET].sc
    end

    def shift_amount(x)
      @mem[x + 4].sc
    end

    def list_ptr(x)
      link(x + Defs::LIST_OFFSET)
    end

    def glue_order(x)
      subtype(x + Defs::LIST_OFFSET)
    end

    def glue_sign(x)
      type(x + Defs::LIST_OFFSET)
    end

    def glue_set(x)
      @mem[x + Defs::GLUE_OFFSET].gr
    end

    # {156}:
    def is_running(x)
      x == Defs::NULL_FLAG
    end

    # {158}:
    def float_cost(x)
      @mem[x + 1].int
    end

    def ins_ptr(x)
      info(x + 4)
    end

    def split_top_ptr(x)
      link(x + 4)
    end

    # {159}:
    def mark_ptr(x)
      link(x + 1)
    end

    def mark_class(x)
      info(x + 1)
    end

    # {160}:
    def adjust_pre(x)
      subtype(x)
    end

    def adjust_ptr(x)
      @mem[x + 1].int
    end

    # {161}:
    def lig_char(x)
      x + 1
    end

    def lig_ptr(x)
      link(lig_char(x))
    end

    # {163}:
    def replace_count(x)
      subtype(x)
    end

    def pre_break(x)
      llink(x)
    end

    def post_break(x)
      rlink(x)
    end

    # {165}:
    def end_LR(x)
      subtype(x)._ % 2 == 1
    end

    def end_LR_type(x)
      Defs::L_CODE*(subtype(x)._ / Defs::L_CODE) + Defs::END_M_CODE
    end

    def begin_LR_type(x)
      x - Defs::AFTER + Defs::BEFORE
    end

    # {166}:
    def precedes_break(x)
      type(x)._ < Defs::MATH_NODE
    end

    def non_discardable(x)
      type(x)._ < Defs::MATH_NODE
    end

    # {167}:
    def glue_ptr(x)
      llink(x)
    end

    def leader_ptr(x)
      rlink(x)
    end

    # {168}:
    def glue_ref_count(x)
      link(x)
    end

    def stretch(x)
      @mem[x + 2].sc
    end

    def shrink(x)
      @mem[x + 3].sc
    end

    def stretch_order(x)
      type(x)
    end

    def shrink_order(x)
      subtype(x)
    end

    # {173}:
    def margin_char(x)
      info(x + 2)
    end

    # {175}:
    def penalty(x)
      @mem[x + 1].int
    end

    # {177}:
    def glue_stretch(x)
      @mem[x + Defs::GLUE_OFFSET].sc
    end

    def glue_shrink(x)
      shift_amount(x)
    end

    def span_count(x)
      subtype(x)
    end

    # {180}:
    def zero_glue
      @mem_bot
    end

    def fil_glue
      zero_glue + Defs::GLUE_SPEC_SIZE
    end

    def fill_glue
      fil_glue + Defs::GLUE_SPEC_SIZE
    end

    def ss_glue
      fill_glue + Defs::GLUE_SPEC_SIZE
    end

    def fil_neg_glue
      ss_glue + Defs::GLUE_SPEC_SIZE
    end

    def lo_mem_stat_max
      fil_neg_glue + Defs::GLUE_SPEC_SIZE - 1
    end

    def page_ins_head
      @mem_top
    end

    def contrib_head
      @mem_top - 1
    end

    def page_head
      @mem_top - 2
    end

    def temp_head
      @mem_top - 3
    end

    def hold_head
      @mem_top - 4
    end

    def adjust_head
      @mem_top - 5
    end

    def active
      @mem_top - 7
    end

    def align_head
      @mem_top - 8
    end

    def end_span
      @mem_top - 9
    end

    def omit_template
      @mem_top - 10
    end

    def null_list
      @mem_top - 11
    end

    def lig_trick
      @mem_top - 12
    end

    def garbage
      @mem_top - 12
    end

    def backup_head
      @mem_top - 13
    end

    def pre_adjust_head
      @mem_top - 14
    end

    def hi_mem_stat_min
      @mem_top - 14
    end

    # {218}:
    def token_ref_count(x)
      info(x)
    end

    # -------------------------------------------------------------------------
    # -- Current page access
    # --
    # {231}:
    def mode
      @cur_list.mode_field
    end

    def head
      @cur_list.head_field
    end

    def tail
      @cur_list.tail_field
    end

    def eTeX_aux
      @cur_list.eTeX_aux_field
    end

    def LR_save
      eTeX_aux
    end

    def LR_box
      eTeX_aux
    end

    def delim_ptr
      eTeX_aux
    end

    def prev_graf
      @cur_list.pg_field
    end

    def aux
      @cur_list.aux_field
    end

    def prev_depth
      aux.sc
    end

    def space_factor
      aux.hh.lh
    end

    def clang
      aux.hh.rh
    end

    def incompleat_noad
      aux.int
    end

    def mode_line
      @cur_list.ml_field
    end

    # -------------------------------------------------------------------------
    # -- Table of equivalence access
    # --
    # {239}:
    def eq_level_field(x)
      x.hh.b1
    end

    def eq_type_field(x)
      x.hh.b0
    end

    def equiv_field(x)
      x.hh.rh
    end

    def eq_level(x)
      eq_level_field(@eqtb[x])
    end

    def eq_type(x)
      eq_type_field(@eqtb[x])
    end

    def equiv(x)
      equiv_field(@eqtb[x])
    end

    # {242}:
    def skip(x)
      equiv(Defs::SKIP_BASE + x)
    end

    def mu_skip(x)
      equiv(Defs::MU_SKIP_BASE + x)
    end

    def glue_par(x)
      equiv(Defs::GLUE_BASE + x)
    end

    def line_skip
      glue_par(Defs::LINE_SKIP_CODE)
    end

    def baseline_skip
      glue_par(Defs::BASELINE_SKIP_CODE)
    end

    def par_skip
      glue_par(Defs::PAR_SKIP_CODE)
    end

    def above_display_skip
      glue_par(Defs::ABOVE_DISPLAY_SKIP_CODE)
    end

    def below_display_skip
      glue_par(Defs::BELOW_DISPLAY_SKIP_CODE)
    end

    def above_display_short_skip
      glue_par(Defs::ABOVE_DISPLAY_SHORT_SKIP_CODE)
    end

    def below_display_short_skip
      glue_par(Defs::BELOW_DISPLAY_SHORT_SKIP_CODE)
    end

    def left_skip
      glue_par(Defs::LEFT_SKIP_CODE)
    end

    def right_skip
      glue_par(Defs::RIGHT_SKIP_CODE)
    end

    def top_skip
      glue_par(Defs::TOP_SKIP_CODE)
    end

    def split_top_skip
      glue_par(Defs::SPLIT_TOP_SKIP_CODE)
    end

    def tab_skip
      glue_par(Defs::TAB_SKIP_CODE)
    end

    def space_skip
      glue_par(Defs::SPACE_SKIP_CODE)
    end

    def xspace_skip
      glue_par(Defs::XSPACE_SKIP_CODE)
    end

    def par_fill_skip
      glue_par(Defs::PAR_FILL_SKIP_CODE)
    end

    def thin_mu_skip
      glue_par(Defs::THIN_MU_SKIP_CODE)
    end

    def med_mu_skip
      glue_par(Defs::MED_MU_SKIP_CODE)
    end

    def thick_mu_skip
      glue_par(Defs::THICK_MU_SKIP_CODE)
    end

    # {248}:
    def par_shape_ptr
      equiv(Defs::PAR_SHAPE_LOC)
    end

    def output_routine
      equiv(Defs::OUTPUT_ROUTINE_LOC)
    end

    def every_par
      equiv(Defs::EVERY_PAR_LOC)
    end

    def every_math
      equiv(Defs::EVERY_MATH_LOC)
    end

    def every_display
      equiv(Defs::EVERY_DISPLAY_LOC)
    end

    def every_hbox
      equiv(Defs::EVERY_HBOX_LOC)
    end

    def every_vbox
      equiv(Defs::EVERY_VBOX_LOC)
    end

    def every_job
      equiv(Defs::EVERY_JOB_LOC)
    end

    def every_cr
      equiv(Defs::EVERY_CR_LOC)
    end

    def err_help
      equiv(Defs::ERR_HELP_LOC)
    end

    def pdf_pages_attr
      equiv(Defs::PDF_PAGES_ATTR_LOC)
    end

    def pdf_page_attr
      equiv(Defs::PDF_PAGE_ATTR_LOC)
    end

    def pdf_page_resources
      equiv(Defs::PDF_PAGE_RESOURCES_LOC)
    end

    def pdf_pk_mode
      equiv(Defs::PDF_PK_MODE_LOC)
    end

    def toks(x)
      equiv(Defs::TOKS_BASE + x)
    end

    def box(x)
      equiv(Defs::BOX_BASE + x)
    end

    def cur_font
      equiv(Defs::CUR_FONT_LOC)
    end

    def fam_fnt(x)
      equiv(Defs::MATH_FONT_BASE + x)
    end

    def cat_code(x)
      equiv(Defs::CAT_CODE_BASE + x)
    end

    def lc_code(x)
      equiv(Defs::LC_CODE_BASE + x)
    end

    def uc_code(x)
      equiv(Defs::UC_CODE_BASE + x)
    end

    def sf_code(x)
      equiv(Defs::SF_CODE_BASE + x)
    end

    def math_code(x)
      equiv(Defs::MATH_CODE_BASE + x)
    end

    def char_sub_code(x)
      equiv(Defs::CHAR_SUB_CODE_BASE + x)
    end

    # {254}:
    def del_code(x)
      @eqtb[Defs::DEL_CODE_BASE + x].int
    end

    def count(x)
      @eqtb[Defs::COUNT_BASE + x].int
    end

    def int_par(x)
      @eqtb[Defs::INT_BASE + x].int
    end

    def pretolerance
      int_par(Defs::PRETOLERANCE_CODE)
    end

    def tolerance
      int_par(Defs::TOLERANCE_CODE)
    end

    def line_penalty
      int_par(Defs::LINE_PENALTY_CODE)
    end

    def hyphen_penalty
      int_par(Defs::HYPHEN_PENALTY_CODE)
    end

    def ex_hyphen_penalty
      int_par(Defs::EX_HYPHEN_PENALTY_CODE)
    end

    def club_penalty
      int_par(Defs::CLUB_PENALTY_CODE)
    end

    def widow_penalty
      int_par(Defs::WIDOW_PENALTY_CODE)
    end

    def display_widow_penalty
      int_par(Defs::DISPLAY_WIDOW_PENALTY_CODE)
    end

    def broken_penalty
      int_par(Defs::BROKEN_PENALTY_CODE)
    end

    def bin_op_penalty
      int_par(Defs::BIN_OP_PENALTY_CODE)
    end

    def rel_penalty
      int_par(Defs::REL_PENALTY_CODE)
    end

    def pre_display_penalty
      int_par(Defs::PRE_DISPLAY_PENALTY_CODE)
    end

    def post_display_penalty
      int_par(Defs::POST_DISPLAY_PENALTY_CODE)
    end

    def inter_line_penalty
      int_par(Defs::INTER_LINE_PENALTY_CODE)
    end

    def double_hyphen_demerits
      int_par(Defs::DOUBLE_HYPHEN_DEMERITS_CODE)
    end

    def final_hyphen_demerits
      int_par(Defs::FINAL_HYPHEN_DEMERITS_CODE)
    end

    def adj_demerits
      int_par(Defs::ADJ_DEMERITS_CODE)
    end

    def mag
      int_par(Defs::MAG_CODE)
    end

    def delimiter_factor
      int_par(Defs::DELIMITER_FACTOR_CODE)
    end

    def looseness
      int_par(Defs::LOOSENESS_CODE)
    end

    def time
      int_par(Defs::TIME_CODE)
    end

    def day
      int_par(Defs::DAY_CODE)
    end

    def month
      int_par(Defs::MONTH_CODE)
    end

    def year
      int_par(Defs::YEAR_CODE)
    end

    def show_box_breadth
      int_par(Defs::SHOW_BOX_BREADTH_CODE)
    end

    def show_box_depth
      int_par(Defs::SHOW_BOX_DEPTH_CODE)
    end

    def hbadness
      int_par(Defs::HBADNESS_CODE)
    end

    def vbadness
      int_par(Defs::VBADNESS_CODE)
    end

    def pausing
      int_par(Defs::PAUSING_CODE)
    end

    def tracing_online
      int_par(Defs::TRACING_ONLINE_CODE)
    end

    def tracing_macros
      int_par(Defs::TRACING_MACROS_CODE)
    end

    def tracing_stats
      int_par(Defs::TRACING_STATS_CODE)
    end

    def tracing_paragraphs
      int_par(Defs::TRACING_PARAGRAPHS_CODE)
    end

    def tracing_pages
      int_par(Defs::TRACING_PAGES_CODE)
    end

    def tracing_output
      int_par(Defs::TRACING_OUTPUT_CODE)
    end

    def tracing_lost_chars
      int_par(Defs::TRACING_LOST_CHARS_CODE)
    end

    def tracing_commands
      int_par(Defs::TRACING_COMMANDS_CODE)
    end

    def tracing_restores
      int_par(Defs::TRACING_RESTORES_CODE)
    end

    def uc_hyph
      int_par(Defs::UC_HYPH_CODE)
    end

    def output_penalty
      int_par(Defs::OUTPUT_PENALTY_CODE)
    end

    def max_dead_cycles
      int_par(Defs::MAX_DEAD_CYCLES_CODE)
    end

    def hang_after
      int_par(Defs::HANG_AFTER_CODE)
    end

    def floating_penalty
      int_par(Defs::FLOATING_PENALTY_CODE)
    end

    def global_defs
      int_par(Defs::GLOBAL_DEFS_CODE)
    end

    def cur_fam
      int_par(Defs::CUR_FAM_CODE)
    end

    def escape_char
      int_par(Defs::ESCAPE_CHAR_CODE)
    end

    def default_hyphen_char
      int_par(Defs::DEFAULT_HYPHEN_CHAR_CODE)
    end

    def default_skew_char
      int_par(Defs::DEFAULT_SKEW_CHAR_CODE)
    end

    def end_line_char
      int_par(Defs::END_LINE_CHAR_CODE)
    end

    def new_line_char
      int_par(Defs::NEW_LINE_CHAR_CODE)
    end

    def language
      int_par(Defs::LANGUAGE_CODE)
    end

    def left_hyphen_min
      int_par(Defs::LEFT_HYPHEN_MIN_CODE)
    end

    def right_hyphen_min
      int_par(Defs::RIGHT_HYPHEN_MIN_CODE)
    end

    def holding_inserts
      int_par(Defs::HOLDING_INSERTS_CODE)
    end

    def error_context_lines
      int_par(Defs::ERROR_CONTEXT_LINES_CODE)
    end

    def synctex
      int_par(Defs::SYNCTEX_CODE)
    end

    def char_sub_def_min
      int_par(Defs::CHAR_SUB_DEF_MIN_CODE)
    end

    def char_sub_def_max
      int_par(Defs::CHAR_SUB_DEF_MAX_CODE)
    end

    def tracing_char_sub_def
      int_par(Defs::TRACING_CHAR_SUB_DEF_CODE)
    end

    def mubyte_in
      int_par(Defs::MUBYTE_IN_CODE)
    end

    def mubyte_out
      int_par(Defs::MUBYTE_OUT_CODE)
    end

    def mubyte_log
      int_par(Defs::MUBYTE_LOG_CODE)
    end

    def spec_out
      int_par(Defs::SPEC_OUT_CODE)
    end

    def pdf_adjust_spacing
      int_par(Defs::PDF_ADJUST_SPACING_CODE)
    end

    def pdf_protrude_chars
      int_par(Defs::PDF_PROTRUDE_CHARS_CODE)
    end

    def pdf_tracing_fonts
      int_par(Defs::PDF_TRACING_FONTS_CODE)
    end

    def pdf_adjust_interword_glue
      int_par(Defs::PDF_ADJUST_INTERWORD_GLUE_CODE)
    end

    def pdf_prepend_kern
      int_par(Defs::PDF_PREPEND_KERN_CODE)
    end

    def pdf_append_kern
      int_par(Defs::PDF_APPEND_KERN_CODE)
    end

    def pdf_gen_tounicode
      int_par(Defs::PDF_GEN_TOUNICODE_CODE)
    end

    def pdf_output
      int_par(Defs::PDF_OUTPUT_CODE)
    end

    def pdf_compress_level
      int_par(Defs::PDF_COMPRESS_LEVEL_CODE)
    end

    def pdf_objcompresslevel
      int_par(Defs::PDF_OBJCOMPRESSLEVEL_CODE)
    end

    def pdf_decimal_digits
      int_par(Defs::PDF_DECIMAL_DIGITS_CODE)
    end

    def pdf_move_chars
      int_par(Defs::PDF_MOVE_CHARS_CODE)
    end

    def pdf_image_resolution
      int_par(Defs::PDF_IMAGE_RESOLUTION_CODE)
    end

    def pdf_pk_resolution
      int_par(Defs::PDF_PK_RESOLUTION_CODE)
    end

    def pdf_unique_resname
      int_par(Defs::PDF_UNIQUE_RESNAME_CODE)
    end

    def pdf_option_always_use_pdfpagebox
      int_par(Defs::PDF_OPTION_ALWAYS_USE_PDFPAGEBOX_CODE)
    end

    def pdf_option_pdf_inclusion_errorlevel
      int_par(Defs::PDF_OPTION_PDF_INCLUSION_ERRORLEVEL_CODE)
    end

    def pdf_minor_version
      int_par(Defs::PDF_MINOR_VERSION_CODE)
    end

    def pdf_force_pagebox
      int_par(Defs::PDF_FORCE_PAGEBOX_CODE)
    end

    def pdf_pagebox
      int_par(Defs::PDF_PAGEBOX_CODE)
    end

    def pdf_inclusion_errorlevel
      int_par(Defs::PDF_INCLUSION_ERRORLEVEL_CODE)
    end

    def pdf_gamma
      int_par(Defs::PDF_GAMMA_CODE)
    end

    def pdf_image_gamma
      int_par(Defs::PDF_IMAGE_GAMMA_CODE)
    end

    def pdf_image_hicolor
      int_par(Defs::PDF_IMAGE_HICOLOR_CODE)
    end

    def pdf_image_apply_gamma
      int_par(Defs::PDF_IMAGE_APPLY_GAMMA_CODE)
    end

    def pdf_draftmode
      int_par(Defs::PDF_DRAFTMODE_CODE)
    end

    def pdf_inclusion_copy_font
      int_par(Defs::PDF_INCLUSION_COPY_FONT_CODE)
    end

    def pdf_suppress_warning_dup_dest
      int_par(Defs::PDF_SUPPRESS_WARNING_DUP_DEST_CODE)
    end

    def pdf_suppress_warning_dup_map
      int_par(Defs::PDF_SUPPRESS_WARNING_DUP_MAP_CODE)
    end

    def tracing_assigns
      int_par(Defs::TRACING_ASSIGNS_CODE)
    end

    def tracing_groups
      int_par(Defs::TRACING_GROUPS_CODE)
    end

    def tracing_ifs
      int_par(Defs::TRACING_IFS_CODE)
    end

    def tracing_scan_tokens
      int_par(Defs::TRACING_SCAN_TOKENS_CODE)
    end

    def tracing_nesting
      int_par(Defs::TRACING_NESTING_CODE)
    end

    def pre_display_direction
      int_par(Defs::PRE_DISPLAY_DIRECTION_CODE)
    end

    def last_line_fit
      int_par(Defs::LAST_LINE_FIT_CODE)
    end

    def saving_vdiscards
      int_par(Defs::SAVING_VDISCARDS_CODE)
    end

    def saving_hyph_codes
      int_par(Defs::SAVING_HYPH_CODES_CODE)
    end

    # {265}:
    def dimen(x)
      @eqtb[Defs::SCALED_BASE + x].sc
    end

    def dimen_par(x)
      @eqtb[Defs::DIMEN_BASE + x].sc
    end

    def par_indent
      dimen_par(Defs::PAR_INDENT_CODE)
    end

    def math_surround
      dimen_par(Defs::MATH_SURROUND_CODE)
    end

    def line_skip_limit
      dimen_par(Defs::LINE_SKIP_LIMIT_CODE)
    end

    def hsize
      dimen_par(Defs::HSIZE_CODE)
    end

    def vsize
      dimen_par(Defs::VSIZE_CODE)
    end

    def max_depth
      dimen_par(Defs::MAX_DEPTH_CODE)
    end

    def split_max_depth
      dimen_par(Defs::SPLIT_MAX_DEPTH_CODE)
    end

    def box_max_depth
      dimen_par(Defs::BOX_MAX_DEPTH_CODE)
    end

    def hfuzz
      dimen_par(Defs::HFUZZ_CODE)
    end

    def vfuzz
      dimen_par(Defs::VFUZZ_CODE)
    end

    def delimiter_shortfall
      dimen_par(Defs::DELIMITER_SHORTFALL_CODE)
    end

    def null_delimiter_space
      dimen_par(Defs::NULL_DELIMITER_SPACE_CODE)
    end

    def script_space
      dimen_par(Defs::SCRIPT_SPACE_CODE)
    end

    def pre_display_size
      dimen_par(Defs::PRE_DISPLAY_SIZE_CODE)
    end

    def display_width
      dimen_par(Defs::DISPLAY_WIDTH_CODE)
    end

    def display_indent
      dimen_par(Defs::DISPLAY_INDENT_CODE)
    end

    def overfull_rule
      dimen_par(Defs::OVERFULL_RULE_CODE)
    end

    def hang_indent
      dimen_par(Defs::HANG_INDENT_CODE)
    end

    def h_offset
      dimen_par(Defs::H_OFFSET_CODE)
    end

    def v_offset
      dimen_par(Defs::V_OFFSET_CODE)
    end

    def emergency_stretch
      dimen_par(Defs::EMERGENCY_STRETCH_CODE)
    end

    def pdf_h_origin
      dimen_par(Defs::PDF_H_ORIGIN_CODE)
    end

    def pdf_v_origin
      dimen_par(Defs::PDF_V_ORIGIN_CODE)
    end

    def pdf_page_width
      dimen_par(Defs::PDF_PAGE_WIDTH_CODE)
    end

    def pdf_page_height
      dimen_par(Defs::PDF_PAGE_HEIGHT_CODE)
    end

    def pdf_link_margin
      dimen_par(Defs::PDF_LINK_MARGIN_CODE)
    end

    def pdf_dest_margin
      dimen_par(Defs::PDF_DEST_MARGIN_CODE)
    end

    def pdf_thread_margin
      dimen_par(Defs::PDF_THREAD_MARGIN_CODE)
    end

    def pdf_first_line_height
      dimen_par(Defs::PDF_FIRST_LINE_HEIGHT_CODE)
    end

    def pdf_last_line_depth
      dimen_par(Defs::PDF_LAST_LINE_DEPTH_CODE)
    end

    def pdf_each_line_height
      dimen_par(Defs::PDF_EACH_LINE_HEIGHT_CODE)
    end

    def pdf_each_line_depth
      dimen_par(Defs::PDF_EACH_LINE_DEPTH_CODE)
    end

    def pdf_ignored_dimen
      dimen_par(Defs::PDF_IGNORED_DIMEN_CODE)
    end

    def pdf_px_dimen
      dimen_par(Defs::PDF_PX_DIMEN_CODE)
    end

    # -------------------------------------------------------------------------
    # -- Hash table access
    # --
    # {274}:
    def next_(x)
      @hash[x].lh
    end

    def text(x)
      @hash[x].rh
    end

    def hash_is_full
      @hash_used == Defs::HASH_BASE
    end

    def font_id_text(x)
      text(Defs::FONT_ID_BASE + x)
    end

    # {275}:
    def prim_next(x)
      @prim[x].lh
    end

    def prim_text(x)
      @prim[x].rh
    end

    def prim_is_full
      @prim_used == Defs::PRIM_BASE
    end

    def prim_eq_level_field(x)
      x.hh.b1
    end

    def prim_eq_type_field(x)
      x.hh.b0
    end

    def prim_equiv_field(x)
      x.hh.rh
    end

    def prim_eq_level(x)
      prim_eq_level_field(@prim_eqtb[x])
    end

    def prim_eq_type(x)
      prim_eq_type_field(@prim_eqtb[x])
    end

    def prim_equiv(x)
      prim_equiv_field(@prim_eqtb[x])
    end

    # -------------------------------------------------------------------------
    # -- Input reading settings
    # --
    # {382}:
    def end_line_char_inactive
      (end_line_char < 0) or (end_line_char > 255)
    end

    # -------------------------------------------------------------------------
    # -- Branching utilities
    # --
    # {518}:
    def if_line_field(x)
      @mem[x + 1].int
    end

    # -------------------------------------------------------------------------
    # -- Font management
    # --
    # {574}:
    def stop_flag
      qi(128)
    end

    def kern_flag
      qi(128)
    end

    def skip_byte(x)
      x.b0
    end

    def next_char(x)
      x.b1
    end

    def op_byte(x)
      x.b2
    end

    def rem_byte(x)
      x.b3
    end

    # {575}:
    def ext_top(x)
      x.b0
    end

    def ext_mid(x)
      x.b1
    end

    def ext_bot(x)
      x.b2
    end

    def ext_rep(x)
      x.b3
    end

    # {578}:
    def non_char
      qi(256)
    end

    # {583}:
    def char_list_exists(x)
      char_sub_code(x)._ > hi(0)
    end

    def char_list_accent(x)
      ho(char_sub_code(x)._) / 256
    end

    def char_list_char(x)
      ho(char_sub_code(x)._) % 256
    end

    def char_info(x, y)
      @font_info[@char_base[x] + effective_char(true, x, y)].qqqq
    end

    def orig_char_info(x, y)
      @font_info[@char_base[x] + y].qqqq
    end

    def char_width(x, y)
      @font_info[@width_base[x] + y.b0._].sc
    end

    def char_exists(x)
      x.b0._ > Defs::MIN_QUARTERWORD
    end

    def char_italic(x, y)
      @font_info[@italic_base[x] + qo(y.b2._) / 4].sc
    end

    def height_depth(x)
      qo(x.b1)
    end

    def char_height(x, y)
      @font_info[@height_base[x] + y / 16].sc
    end

    def char_depth(x, y)
      @font_info[@depth_base[x] + y / 16].sc
    end

    def char_tag(x)
      qo(x.b2._) / 4
    end

    # {586}:
    def char_kern(x, y)
      @font_info[@kern_base[x] + 256*op_byte(y) + rem_byte(y)].sc
    end

    def lig_kern_start(x, y)
      @lig_kern_base[x] + rem_byte(y)
    end

    def lig_kern_restart(x, y)
      @lig_kern_base[x] \
      + 256*op_byte(y) + rem_byte(y) + 32768 - Defs::KERN_BASE_OFFSET
    end

    # {587}:
    def param(x, y)
      @font_info[x + @param_base[y]].sc
    end

    def slant(x)
      param(Defs::SLANT_CODE, x)
    end

    def space(x)
      param(Defs::SPACE_CODE, x)
    end

    def space_stretch(x)
      param(Defs::SPACE_STRETCH_CODE, x)
    end

    def space_shrink(x)
      param(Defs::SPACE_SHRINK_CODE, x)
    end

    def x_height(x)
      param(Defs::X_HEIGHT_CODE, x)
    end

    def quad(x)
      param(Defs::QUAD_CODE, x)
    end

    def extra_space(x)
      param(Defs::EXTRA_SPACE_CODE, x)
    end

    # {635}:
    def location(x)
      @mem[x + 2].int
    end

    # {646}:
    def box_lr(x)
      qo(subtype(x)._)
    end

    def set_box_lr(x, y)
      subtype(x)._ = qi(y)
    end

    # {676}:
    def flushable(x)
      x == @str_ptr - 1
    end

    def is_valid_char(f, x)
      (@font_bc[f] <= x) and (x <= @font_ec[f]) \
      and char_exists(orig_char_info(f, x))
    end

    # -------------------------------------------------------------------------
    # -- PDF stuff access
    # --
    # {699}:
    def obj_info(x)
      @obj_tab[x].int0
    end

    def obj_link(x)
      @obj_tab[x].int1
    end

    def obj_offset(x)
      @obj_tab[x].int2
    end

    def obj_os_idx(x)
      @obj_tab[x].int3
    end

    def obj_aux(x)
      @obj_tab[x].int4
    end

    def set_obj_fresh(x)
      obj_offset(x)._ = -2
    end

    def set_obj_scheduled(x)
      if obj_offset(x)._ == -2 then
        obj_offset(x)._ = -1
      end
    end

    def is_obj_scheduled(x)
      obj_offset(x)._ > -2
    end

    def is_obj_written(x)
      obj_offset(x)._ > -1
    end

    def pdf_left(x)
      @mem[x + 1].sc
    end

    def pdf_top(x)
      @mem[x + 2].sc
    end

    def pdf_right(x)
      @mem[x + 3].sc
    end

    def pdf_bottom(x)
      @mem[x + 4].sc
    end

    def pdf_width(x)
      @mem[x + 1].sc
    end

    def pdf_height(x)
      @mem[x + 2].sc
    end

    def pdf_depth(x)
      @mem[x + 3].sc
    end

    def pdf_literal_data(x)
      link(x + 1)
    end

    def pdf_literal_mode(x)
      info(x + 1)
    end

    def pdf_colorstack_stack(x)
      link(x + 1)
    end

    def pdf_colorstack_cmd(x)
      info(x + 1)
    end

    def pdf_colorstack_data(x)
      link(x + 2)
    end

    def pdf_setmatrix_data(x)
      link(x + 1)
    end

    def pdf_obj_objnum(x)
      info(x + 1)
    end

    def obj_data_ptr(x)
      obj_aux(x)
    end

    def obj_obj_data(x)
      @pdf_mem[obj_data_ptr(x) + 0]
    end

    def obj_obj_is_stream(x)
      @pdf_mem[obj_data_ptr(x) + 1]
    end

    def obj_obj_stream_attr(x)
      @pdf_mem[obj_data_ptr(x) + 2]
    end

    def obj_obj_is_file(x)
      @pdf_mem[obj_data_ptr(x) + 3]
    end

    def pdf_xform_objnum(x)
      info(x + 4)
    end

    def obj_xform_width(x)
      @pdf_mem[obj_data_ptr(x) + 0]
    end

    def obj_xform_height(x)
      @pdf_mem[obj_data_ptr(x) + 1]
    end

    def obj_xform_depth(x)
      @pdf_mem[obj_data_ptr(x) + 2]
    end

    def obj_xform_box(x)
      @pdf_mem[obj_data_ptr(x) + 3]
    end

    def obj_xform_attr(x)
      @pdf_mem[obj_data_ptr(x) + 4]
    end

    def obj_xform_resources(x)
      @pdf_mem[obj_data_ptr(x) + 5]
    end

    def pdf_ximage_objnum(x)
      info(x + 4)
    end

    def obj_ximage_width(x)
      @pdf_mem[obj_data_ptr(x) + 0]
    end

    def obj_ximage_height(x)
      @pdf_mem[obj_data_ptr(x) + 1]
    end

    def obj_ximage_depth(x)
      @pdf_mem[obj_data_ptr(x) + 2]
    end

    def obj_ximage_attr(x)
      @pdf_mem[obj_data_ptr(x) + 3]
    end

    def obj_ximage_data(x)
      @pdf_mem[obj_data_ptr(x) + 4]
    end

    def obj_annot_ptr(x)
      obj_aux(x)
    end

    def pdf_annot_data(x)
      info(x + 5)
    end

    def pdf_link_attr(x)
      info(x + 5)
    end

    def pdf_link_action(x)
      link(x + 5)
    end

    def pdf_annot_objnum(x)
      @mem[x + 6].int
    end

    def pdf_link_objnum(x)
      @mem[x + 6].int
    end

    def pdf_action_type(x)
      type(x)
    end

    def pdf_action_named_id(x)
      subtype(x)
    end

    def pdf_action_id(x)
      link(x)
    end

    def pdf_action_file(x)
      info(x + 1)
    end

    def pdf_action_new_window(x)
      link(x + 1)
    end

    def pdf_action_page_tokens(x)
      info(x + 2)
    end

    def pdf_action_user_tokens(x)
      info(x + 2)
    end

    def pdf_action_refcount(x)
      link(x + 2)
    end

    def obj_outline_count(x)
      obj_info(x)
    end

    def obj_outline_ptr(x)
      obj_aux(x)
    end

    def obj_outline_title(x)
      @pdf_mem[obj_outline_ptr(x)]
    end

    def obj_outline_parent(x)
      @pdf_mem[obj_outline_ptr(x) + 1]
    end

    def obj_outline_prev(x)
      @pdf_mem[obj_outline_ptr(x) + 2]
    end

    def obj_outline_next(x)
      @pdf_mem[obj_outline_ptr(x) + 3]
    end

    def obj_outline_first(x)
      @pdf_mem[obj_outline_ptr(x) + 4]
    end

    def obj_outline_last(x)
      @pdf_mem[obj_outline_ptr(x) + 5]
    end

    def obj_outline_action_objnum(x)
      @pdf_mem[obj_outline_ptr(x) + 6]
    end

    def obj_outline_attr(x)
      @pdf_mem[obj_outline_ptr(x) + 7]
    end

    def obj_dest_ptr(x)
      obj_aux(x)
    end

    def pdf_dest_type(x)
      type(x + 5)
    end

    def pdf_dest_named_id(x)
      subtype(x + 5)
    end

    def pdf_dest_id(x)
      link(x + 5)
    end

    def pdf_dest_xyz_zoom(x)
      info(x + 6)
    end

    def pdf_dest_objnum(x)
      link(x + 6)
    end

    def pdf_thread_named_id(x)
      subtype(x + 5)
    end

    def pdf_thread_id(x)
      link(x + 5)
    end

    def pdf_thread_attr(x)
      info(x + 6)
    end

    def obj_thread_first(x)
      obj_aux(x)
    end

    def obj_bead_ptr(x)
      obj_aux(x)
    end

    def obj_bead_rect(x)
      @pdf_mem[obj_bead_ptr(x)]
    end

    def obj_bead_page(x)
      @pdf_mem[obj_bead_ptr(x) + 1]
    end

    def obj_bead_next(x)
      @pdf_mem[obj_bead_ptr(x) + 2]
    end

    def obj_bead_prev(x)
      @pdf_mem[obj_bead_ptr(x) + 3]
    end

    def obj_bead_attr(x)
      @pdf_mem[obj_bead_ptr(x) + 4]
    end

    def obj_bead_data(x)
      obj_bead_rect(x)
    end

    def snap_glue_ptr(x)
      info(x + 1)
    end

    def final_skip(x)
      @mem[x + 2].sc
    end

    def snapy_comp_ratio(x)
      @mem[x + 1].int
    end

    # -------------------------------------------------------------------------
    # -- Math noads access
    # --
    # {859}:
    def nucleus(x)
      x + 1
    end

    def supscr(x)
      x + 2
    end

    def subscr(x)
      x + 3
    end

    def math_type(x)
      link(x)
    end

    def fam(x)
      font(x)
    end

    # {861}:
    def left_delimiter(x)
      x + 4
    end

    def right_delimiter(x)
      x + 5
    end

    def small_fam(x)
      @mem[x].qqqq.b0
    end

    def small_char(x)
      @mem[x].qqqq.b1
    end

    def large_fam(x)
      @mem[x].qqqq.b2
    end

    def large_char(x)
      @mem[x].qqqq.b3
    end

    def thickness(x)
      width(x)
    end

    def numerator(x)
      supscr(x)
    end

    def denominator(x)
      subscr(x)
    end

    # {865}:
    def accent_chr(x)
      x + 4
    end

    def delimiter(x)
      nucleus(x)
    end

    def scripts_allowed(x)
      type(x)._ >= Defs::ORD_NOAD and type(x)._ < Defs::LEFT_NOAD
    end

    # {867}:
    def display_mlist(x)
      info(x + 1)
    end

    def text_mlist(x)
      link(x + 1)
    end

    def script_mlist(x)
      info(x + 2)
    end

    def script_script_mlist(x)
      link(x + 2)
    end

    # {878}:
    def mathsy(x, y)
      @font_info[x + @param_base[fam_fnt(2 + y)]].sc
    end

    def math_x_height(x)
      mathsy(5, x)
    end

    def math_quad(x)
      mathsy(6, x)
    end

    def num1(x)
      mathsy(8, x)
    end

    def num2(x)
      mathsy(9, x)
    end

    def num3(x)
      mathsy(10, x)
    end

    def denom1(x)
      mathsy(11, x)
    end

    def denom2(x)
      mathsy(12, x)
    end

    def sup1(x)
      mathsy(13, x)
    end

    def sup2(x)
      mathsy(14, x)
    end

    def sup3(x)
      mathsy(15, x)
    end

    def sub1(x)
      mathsy(16, x)
    end

    def sub2(x)
      mathsy(17, x)
    end

    def sup_drop(x)
      mathsy(18, x)
    end

    def sub_drop(x)
      mathsy(19, x)
    end

    def delim1(x)
      mathsy(20, x)
    end

    def delim2(x)
      mathsy(21, x)
    end

    def axis_height(x)
      mathsy(22, x)
    end

    # {880}:
    def cramped_style(x)
      2*(x / 2) + Defs::CRAMPED
    end

    def sub_style(x)
      2*(x / 4) + Defs::SCRIPT_STYLE + Defs::CRAMPED
    end

    def sup_style(x)
      2*(x / 4) + Defs::SCRIPT_STYLE + x % 2
    end

    def num_style(x)
      x + 2 - 2*(x / 6)
    end

    def denom_style(x)
      2*(x / 2) + Defs::CRAMPED + 2 - 2*(x / 6)
    end

    # -------------------------------------------------------------------------
    # -- Paragraph stuff
    # --
    # {903}:
    def new_hlist(x)
      @mem[nucleus(x)].int
    end

    # {947}:
    def u_part(x)
      @mem[x + Defs::HEIGHT_OFFSET].int
    end

    def v_part(x)
      @mem[x + Defs::DEPTH_OFFSET].int
    end

    def extra_info(x)
      info(x + Defs::LIST_OFFSET)
    end

    # {948}:
    def preamble
      link(align_head)
    end

    # {997}:
    def fitness(x)
      subtype(x)
    end

    def break_node(x)
      rlink(x)
    end

    def line_number(x)
      llink(x)
    end

    def total_demerits(x)
      @mem[x + 2].int
    end

    def last_active
      active
    end

    # {999}:
    def cur_break(x)
      rlink(x)
    end

    def prev_break(x)
      llink(x)
    end

    def serial(x)
      info(x)
    end

    # {1055}:
    def next_break(x)
      prev_break(x)
    end

    # -------------------------------------------------------------------------
    # -- Hyphenation stuff
    # --
    # {1100}:
    def trie_link(x)
      @trie_trl[x]
    end

    def trie_char(x)
      @trie_trc[x]
    end

    def trie_op(x)
      @trie_tro[x]
    end

    # {1129}:
    def trie_back(x)
      @trie_tro[x]
    end

    # -------------------------------------------------------------------------
    # -- Page breaking stuff
    # --
    # {1160}:
    def broken_ptr(x)
      link(x + 1)
    end

    def broken_ins(x)
      info(x + 1)
    end

    def last_ins_ptr(x)
      link(x + 2)
    end

    def best_ins_ptr(x)
      info(x + 2)
    end

    # -------------------------------------------------------------------------
    # -- Language utilities
    # --
    # {1331}:
    def fam_in_range
      cur_fam >= 0 and cur_fam < 16
    end

    # -------------------------------------------------------------------------
    # -- Extensions
    # --
    # {1523}:
    def what_lang(x)
      link(x + 1)
    end

    def what_lhm(x)
      type(x + 1)
    end

    def what_rhm(x)
      subtype(x + 1)
    end

    def write_tokens(x)
      link(x + 1)
    end

    def write_stream(x)
      type(x + 1)
    end

    def write_mubyte(x)
      subtype(x + 1)
    end

    def open_name(x)
      link(x + 1)
    end

    def open_area(x)
      info(x + 2)
    end

    def open_ext(x)
      link(x + 2)
    end

    # {1644}:
    def eTeX_state(x)
      @eqtb[Defs::ETEX_STATE_BASE + x].int
    end

    # {1647}:
    def eTeX_ex
      @eTeX_mode == 1
    end

    # {1653}:
    def every_eof
      equiv(Defs::EVERY_EOF_LOC)
    end

    # {1695}:
    def TeXXeT_state
      eTeX_state(Defs::TEXXET_CODE)
    end

    def TeXXeT_en
      TeXXeT_state > 0
    end

    # {1712}:
    def LR_dir(x)
      subtype(x)._ / Defs::R_CODE
    end

    # {1714}:
    def edge_dist(x)
      depth(x)
    end

    # {1783}:
    def expr_e_field(x)
      @mem[x + 1].int
    end

    def expr_t_field(x)
      @mem[x + 2].int
    end

    def expr_n_field(x)
      @mem[x + 3].int
    end

    # {1810}:
    def sa_index(x)
      type(x)
    end

    def sa_used(x)
      subtype(x)
    end

    # {1811}:
    def sa_mark
      @sa_root[Defs::MARK_VAL]
    end

    # {1815}:
    def sa_lev(x)
      sa_used(x)
    end

    def sa_type(x)
      sa_index(x) / 16
    end

    def sa_ref(x)
      info(x + 1)
    end

    def sa_ptr(x)
      link(x + 1)
    end

    def sa_num(x)
      sa_ptr(x)
    end

    def sa_int(x)
      @mem[x + 2].int
    end

    def sa_dim(x)
      @mem[x + 2].sc
    end

    # {1820}:
    def sa_top_mark(x)
      info(x + 1)
    end

    def sa_first_mark(x)
      link(x + 1)
    end

    def sa_bot_mark(x)
      info(x + 2)
    end

    def sa_split_first_mark(x)
      link(x + 2)
    end

    def sa_split_bot_mark(x)
      info(x + 3)
    end

    # {1832}:
    def sa_loc(x)
      sa_ref(x)
    end

    # {1837}:
    def active_short(x)
      @mem[x + 3].sc
    end

    def active_glue(x)
      @mem[x + 4].sc
    end

    # {1859}:
    def inter_line_penalties_ptr
      equiv(Defs::INTER_LINE_PENALTIES_LOC)
    end

    def club_penalties_ptr
      equiv(Defs::CLUB_PENALTIES_LOC)
    end

    def widow_penalties_ptr
      equiv(Defs::WIDOW_PENALTIES_LOC)
    end

    def display_widow_penalties_ptr
      equiv(Defs::DISPLAY_WIDOW_PENALTIES_LOC)
    end

    # {1889}:
    def subinfo(x)
      subtype(x)
    end
  end

=begin
  # ---------------------------------------------------------------------------
  # -- Printing routines
  # --


  # {132}:
  def print_word(tex, w)
    print_int(tex, w.int)
    print_char(tex, " ".ord)
    print_scaled(tex, w.sc)
    print_char(tex, " ".ord)
    print_scaled(tex, round(Constants::UNITY * float(w.gr)))
    print_ln(tex)
    print_int(tex, w.hh.lh)
    print_char(tex, "=".ord)
    print_int(tex, w.hh.b0)
    print_char(tex, ":".ord)
    print_int(tex, w.hh.b1)
    print_char(tex, ";".ord)
    print_int(tex, w.hh.rh)
    print_char(tex, " ".ord)
    print_int(tex, w.qqqq.b0)
    print_char(tex, ":".ord)
    print_int(tex, w.qqqq.b1)
    print_char(tex, ":".ord)
    print_int(tex, w.qqqq.b2)
    print_char(tex, ":".ord)
    print_int(tex, w.qqqq.b3)
  end
=end

end
