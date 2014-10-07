#                                                         -*- coding: utf-8 -*-
#! \file    ./fmtviewer/fmtviewer.rbw
#! \author  Jiří Kučera, <sanczes@gmail.com>
#! \stamp   2014-08-12 15:02:55 (UTC+01:00, DST+01:00)
#! \project textools: Utilities for debugging TeX/LaTeX output.
#! \license MIT
#! \version 0.1.0
#! \fdesc   pdfTeX .fmt file viewer.
#

require 'tk'
require 'tkextlib/tile'
require './texlib'

# =============================================================================
# == Debugging
# ==
$DEBUGMODE = false
$NESTLEVEL = 0

if (ARGV.include? "--debug") || (ARGV.include? "-d")
  $DEBUGMODE = true
end

if $DEBUGMODE

  def dnl(l)
    $NESTLEVEL += l
  end

  def dp(s)
    p(" "*($NESTLEVEL*2) + s)
  end

else

  def dnl(l)
  end

  def dp(s)
  end

end

# =============================================================================
# == GUI Widgets
# ==
class Dispatcher
  attr_accessor :slots, :listeners, :transtab

  def initialize
    @slots = {}
    @listeners = []
    @transtab = {}
  end

  def signal(s, *args)
    v = nil
    s = @transtab[s] if @transtab[s]
    @listeners.each do |l|
      v = l.slots[s].call(*args) if l.slots[s]
    end
    return v
  end
end

class Viewer
  class Storage
    attr_reader :data

    def initialize
      @data = ""
    end

    def emit(s)
      @data += s
    end

    def clear
      @data.clear
      GC.start
    end
  end

  def initialize(main_window, storage)
    @to_unpack = []
    @to_destroy = []
    @main_window = main_window
    @storage = storage
    @storage.clear
    @destroyed = true
  end

  def create(master)
    return if not @destroyed
    @master = master
    # Bounding frame:
    @container = TkFrame.new @master
    @to_destroy.push @container
    before_scrollbars
    # Vertical scrollbar:
    @yscroll = TkScrollbar.new @container
    @yscroll.orient 'vertical'
    @yscroll.command proc {|*args| @viewer.yview(*args)}
    @yscroll.pack :side => 'right', :fill => 'y', :expand => false
    @to_destroy.push @yscroll
    @to_unpack.push @yscroll
    # Horizontal scrollbar:
    @xscroll = TkScrollbar.new @container
    @xscroll.orient 'horizontal'
    @xscroll.command proc {|*args| @viewer.xview(*args)}
    @xscroll.pack :side => 'bottom', :fill => 'x', :expand => false
    @to_destroy.push @xscroll
    @to_unpack.push @xscroll
    after_scrollbars
    # Viewing area:
    @viewer = TkText.new @container
    @viewer.font 'TkFixedFont'
    @viewer.wrap 'none'
    @viewer.xscrollcommand proc {|*args| @xscroll.set(*args)}
    @viewer.yscrollcommand proc {|*args| @yscroll.set(*args)}
    @viewer['state'] = :disabled
    @viewer.pack :side => 'top', :fill => 'both', :expand => true
    @to_destroy.push @viewer
    @to_unpack.push @viewer
    @viewer['state'] = :normal
    @viewer.insert('end', @storage.data)
    @viewer['state'] = :disabled
    @viewer.see 'end -1 lines'
    @destroyed = false
  end

  def destroyed?
    @destroyed
  end

  def before_scrollbars
  end

  def after_scrollbars
  end

  def handle
    @container
  end

  def append(s)
    @storage.emit(s)
  end

  def clrscr
    return if @destroyed
    @viewer['state'] = :normal
    @viewer.delete(1.0, 'end')
    @viewer['state'] = :disabled
    GC.start
  end

  def refresh
    return if @destroyed
    clrscr
    @viewer['state'] = :normal
    @viewer.insert('end', @storage.data)
    @viewer['state'] = :disabled
    @viewer.see 'end -1 lines'
  end

  def clear
    clrscr
    @storage.clear
  end

  def destroy
    return if @destroyed
    clrscr
    @to_unpack.reverse_each {|x| x.unpack}
    @to_destroy.reverse_each {|x| x.destroy}
    @to_unpack.clear
    @to_destroy.clear
    @container = @viewer = @xscroll = @yscroll = nil
    @destroyed = true
  end
end

class HexViewer < Viewer
  class LineBuffer
    attr_reader :data, :offset

    class Line
      attr_reader :line

      def initialize(owner)
        @owner = owner
        reset
      end

      def add(b)
        x, c = xpos, cpos
        @line[x, 2] = "%02X" % b
        @line[c] = (31 < b && b < 127) ? b.chr : '.'
        @owner.on_add
      end

      def reset
        @line = "%08X: " % (@owner.offset & ~15) + " "*68 # = (3*16 + 4 + 16)
      end

      def xpos
        # XXXXXXXX:  00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF
        return 11 + (@owner.offset & 15)*3
      end

      def cpos
        return 62 + (@owner.offset & 15) # 62 = (8 + 1 + 1 + 3*16 + 4)
      end
    end

    def initialize
      @data = ""
      @offset = 0
      @line = Line.new self
    end

    def label(s)
      flush
      @data << (("%08X: " % (@offset & ~15)) << s).rstrip << "\n"
    end

    def send(data)
      data.unpack("C*").each do |x|
        @line.add x
      end
    end

    def flush
      l = @line.line.rstrip
      if l[-1] != ':'
        @data << l << "\n"
        @line.reset
      end
    end

    def clear(force = false)
      @data.clear
      @offset = 0 if force
      @line.reset
    end

    def on_add
      @offset += 1
      if (@offset & 15) == 0
        @data << @line.line.rstrip << "\n"
        @line.reset
      end
    end
  end

  def initialize(main_window, storage, buffer)
    @buffer = buffer
    super(main_window, storage)
  end

  def create(master)
    return if not destroyed?
    super(master)
    @buffer.clear
  end

  def after_scrollbars
    @xrule = TkLabel.new handle
    @xrule.font 'TkFixedFont'
    @xrule.text " "*11 + "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F" \
              + " "*4  + "0123456789ABCDEF"
    @xrule['anchor'] = 'w'
    @xrule['padx'] = 1
    @xrule['pady'] = 3
    @xrule['border'] = 1
    @xrule['relief'] = 'flat'
    @xrule.pack :side => 'top', :fill => 'x', :expand => false
    @to_unpack.push @xrule
    @to_destroy.push @xrule
  end

  def label(s)
    @buffer.label(s)
  end

  def send(data)
    @buffer.send(data)
  end

  def flush
    @buffer.flush
    if @buffer.data.size > 0
      @storage.emit(@buffer.data)
      @buffer.clear
    end
  end

  def clear
    @buffer.clear(true)
    super
    GC.start
  end

  def destroy
    return if destroyed?
    super
    @xrule = nil
    @buffer.clear
  end
end

class LogViewer < Viewer
  def initialize(main_window, storage)
    super(main_window, storage)
  end

  def <<(msg)
    @storage.emit(msg)
  end

  def log_start
    self << (Time.now.strftime "** %Y-%m-%d %H:%M:%S %z:\n")
  end

  def log_end
    self << "\n"
  end
end

class MemoryViewer < LogViewer
  def initialize(main_window, storage)
    super(main_window, storage)
  end

  def before_scrollbars
    @controls = TkFrame.new handle
    @controls['relief'] = 'flat'
    @controls['border'] = 3
    @to_unpack.push @controls
    @to_destroy.push @controls
    @mem_input_label = TkLabel.new @controls
    @mem_input_label.text "Command or address to TeX memory (in hex): "
    @mem_input_label.pack :side => 'left'
    @to_unpack.push @mem_input_label
    @to_destroy.push @mem_input_label
    @mem_input_entry = TkEntry.new @controls
    @mem_input_entry.pack :side => 'left', :padx => 2
    @to_unpack.push @mem_input_entry
    @to_destroy.push @mem_input_entry
    @mem_input_button = TkButton.new @controls
    @mem_input_button.text "View"
    @mem_input_button.command proc {do_view}
    @mem_input_button['padx'] = 12
    @mem_input_button.pack :side => 'left', :padx => 6
    @to_unpack.push @mem_input_button
    @to_destroy.push @mem_input_button
    @clear_button = TkButton.new @controls
    @clear_button.text "Clear"
    @clear_button.command proc {clear}
    @clear_button['padx'] = 24
    @clear_button.pack :side => 'right', :padx => 2
    @to_unpack.push @clear_button
    @to_destroy.push @clear_button
    @controls.pack :side => 'bottom', :fill => 'x', :expand => false
  end

  def do_view
    proc_map = {
      'mem_top' => proc {
        @main_window.tex.show_memory_location(@main_window.tex.mem_top)
        refresh
      },
      'page_ins' => proc {
        @main_window.tex.show_page_ins
      },
      'contrib' => proc {
        @main_window.tex.show_contrib
      },
      'page' => proc {
        @main_window.tex.show_page
      },
      'temp' => proc {
        @main_window.tex.show_temp
      },
      'ttemp' => proc {
        @main_window.tex.show_ttemp
      },
      'hold' => proc {
        @main_window.tex.show_hold
      },
      'thold' => proc {
        @main_window.tex.show_thold
      },
      'adjust' => proc {
        @main_window.tex.show_adjust
      },
      'active' => proc {
        @main_window.tex.show_active
      },
      'align' => proc {
        @main_window.tex.show_align
      },
      'end_span' => proc {
        @main_window.tex.show_end_span
      },
      'omit_template' => proc {
        @main_window.tex.show_omit_template
      }
    }
    ##
    v = @mem_input_entry.get
    v.strip!
    ##
    @main_window.signal :redirect, {
      :log_start => :mv_start,
      :log_write => :mv_write,
      :log_end => :mv_end,
      :log_refresh => :mv_refresh
    }
    if proc_map[v] != nil
      @mem_input_entry.delete(0, 'end')
      proc_map[v].call
    elsif not /\A[0-9A-Fa-f]+\z/ =~ v
      Tk::messageBox \
        :type => 'ok', \
        :message => "Entry value must be command or hexadecimal integer.", \
      :title => "Error", \
      :icon => 'error', \
      :default => 'ok'
    else
      @mem_input_entry.delete(0, 'end')
      begin
        @main_window.tex.show_memory_location(v.to_i(16))
      rescue
        Tk::messageBox \
          :type => 'ok', \
          :message => "Bad memory address.", \
          :title => "Error", \
          :icon => 'error', \
          :default => 'ok'
      end
      refresh
    end
    @main_window.signal :redirect, {}
  end

  def destroy
    return if destroyed?
    super
    @controls = nil
    @mem_input_label = @mem_input_entry = @mem_input_button = nil
    @clear_button = nil
  end
end

class EqtbViewer < LogViewer
  def initialize(main_window, storage)
    super(main_window, storage)
  end

  def before_scrollbars
    @controls = TkFrame.new handle
    @controls['relief'] = 'flat'
    @controls['border'] = 3
    @to_unpack.push @controls
    @to_destroy.push @controls
    @eq_input_label = TkLabel.new @controls
    @eq_input_label.text "Eqtb item number: "
    @eq_input_label.pack :side => 'left'
    @to_unpack.push @eq_input_label
    @to_destroy.push @eq_input_label
    @eq_input_entry = TkEntry.new @controls
    @eq_input_entry.pack :side => 'left', :padx => 2
    @to_unpack.push @eq_input_entry
    @to_destroy.push @eq_input_entry
    @eq_input_button = TkButton.new @controls
    @eq_input_button.text "View"
    @eq_input_button.command proc {do_view}
    @eq_input_button['padx'] = 12
    @eq_input_button.pack :side => 'left', :padx => 6
    @to_unpack.push @eq_input_button
    @to_destroy.push @eq_input_button
    @clear_button = TkButton.new @controls
    @clear_button.text "Clear"
    @clear_button.command proc {clear}
    @clear_button['padx'] = 24
    @clear_button.pack :side => 'right', :padx => 2
    @to_unpack.push @clear_button
    @to_destroy.push @clear_button
    @controls.pack :side => 'bottom', :fill => 'x', :expand => false
  end

  def do_view
    proc_map = {
      'actives' => proc {
        @main_window.tex.list_actives
      },
      'singles' => proc {
        @main_window.tex.list_singles
      },
      'hash' => proc {
        @main_window.tex.list_hash
      },
      'glues' => proc {
        @main_window.tex.list_glues
      },
      'skips' => proc {
        @main_window.tex.list_skips
      },
      'muskips' => proc {
        @main_window.tex.list_muskips
      },
      'parshape' => proc {
        @main_window.tex.show_parshape
      },
      'assign_toks' => proc {
        @main_window.tex.list_assign_toks
      },
      'toks' => proc {
        @main_window.tex.list_toks
      },
      'penalties' => proc {
        @main_window.tex.list_penalties
      },
      'boxes' => proc {
        @main_window.tex.list_boxes
      },
      'curfont' => proc {
        @main_window.tex.show_current_font
      },
      'xcodes' => proc {
        @main_window.tex.list_xcodes
      },
      'fonts' => proc {
        @main_window.tex.list_fonts
      },
      'catcodes' => proc {
        @main_window.tex.list_catcodes
      },
      'lccodes' => proc {
        @main_window.tex.list_lccodes
      },
      'uccodes' => proc {
        @main_window.tex.list_uccodes
      },
      'sfcodes' => proc {
        @main_window.tex.list_sfcodes
      },
      'mathcodes' => proc {
        @main_window.tex.list_mathcodes
      },
      'charsubs' => proc {
        @main_window.tex.list_charsubs
      },
      'intpars' => proc {
        @main_window.tex.list_intpars
      },
      'counts' => proc {
        @main_window.tex.list_counts
      },
      'dels' => proc {
        @main_window.tex.list_dels
      },
      'lengths' => proc {
        @main_window.tex.list_lengths
      },
      'dimens' => proc {
        @main_window.tex.list_dimens
      }
    }
    ##
    v = @eq_input_entry.get
    v.strip!
    ##
    @main_window.signal :redirect, {
      :log_start => :ev_start,
      :log_write => :ev_write,
      :log_end => :ev_end,
      :log_refresh => :ev_refresh
    }
    if proc_map[v] != nil
      @eq_input_entry.delete(0, 'end')
      proc_map[v].call
    elsif v != '0' and not /\A[1-9][0-9]*\z/ =~ v
      Tk::messageBox \
        :type => 'ok', \
        :message => "Entry value must be nonnegative integer.", \
      :title => "Error", \
      :icon => 'error', \
      :default => 'ok'
    else
      @eq_input_entry.delete(0, 'end')
      @main_window.tex.show_eqtb(v.to_i)
    end
    @main_window.signal :redirect, {}
  end

  def destroy
    return if destroyed?
    super
    @controls = nil
    @eq_input_label = @eq_input_entry = @eq_input_button = nil
    @clear_button = nil
  end
end

class MenuBar
  attr_reader :handle

  def initialize(main_window)
    @handle = TkMenu.new
    @handle.add \
      :cascade, \
      :menu => FileMenu.new(main_window).handle, \
      :label => "File", \
      :underline => 0
    @handle.add \
      :cascade, \
      :menu => ViewMenu.new(main_window).handle, \
      :label => "View", \
      :underline => 0
  end
end

class FileMenu < Dispatcher
  attr_reader :handle

  def initialize(main_window)
    super()
    @handle = TkMenu.new main_window.root
    @handle.tearoff 0
    @handle.add \
      :command, \
      :label => "Open...", \
      :command => proc {main_window.signal :fmt_open}, \
      :underline => 0
    @handle.add \
      :command, \
      :label => "Close", \
      :command => proc {main_window.signal :fmt_close}, \
      :underline => 0
    @handle.add :separator
    @handle.add \
      :command, \
      :label => "Exit", \
      :command => proc {main_window.signal :exit}, \
      :underline => 3
    main_window.listeners.push self
    @slots = {
      :enable_open => proc {
        @handle.entryconfigure "Open...", :state => 'normal'
      },
      :disable_open => proc {
        @handle.entryconfigure "Open...", :state => 'disabled'
      },
      :enable_close => proc {
        @handle.entryconfigure "Close", :state => 'normal'
      },
      :disable_close => proc {
        @handle.entryconfigure "Close", :state => 'disabled'
      }
    }
  end
end

class ViewMenu < Dispatcher
  attr_reader :handle

  def initialize(main_window)
    super()
    @handle = TkMenu.new main_window.root
    @handle.tearoff 0
    hexview_var = TkVariable.new(0)
    hexview_var.trace("w", proc {
      main_window.signal :show_hexview, hexview_var.value == '1', true
    })
    log_var = TkVariable.new(0)
    log_var.trace("w", proc {
      main_window.signal :show_log, log_var.value == '1', true
    })
    error_log_var = TkVariable.new(0)
    error_log_var.trace("w", proc {
      main_window.signal :show_error_log, error_log_var.value == '1', true
    })
    memview_var = TkVariable.new(0)
    memview_var.trace("w", proc {
      main_window.signal :show_memview, memview_var.value == '1', true
    })
    eqtbview_var = TkVariable.new(0)
    eqtbview_var.trace("w", proc {
      main_window.signal :show_eqtbview, eqtbview_var.value == '1', true
    })
    @handle.add \
      :checkbutton, \
      :label => "Hex View", \
      :variable => hexview_var, \
      :onvalue => 1, \
      :offvalue => 0
    @handle.add \
      :checkbutton, \
      :label => "Log", \
      :variable => log_var, \
      :onvalue => 1, \
      :offvalue => 0
    @handle.add \
      :checkbutton, \
      :label => "Error Log", \
      :variable => error_log_var, \
      :onvalue => 1, \
      :offvalue => 0
    @handle.add \
      :checkbutton, \
      :label => "TeX Main Memory Viewer", \
      :variable => memview_var, \
      :onvalue => 1, \
      :offvalue => 0
    @handle.add \
      :checkbutton, \
      :label => "Eqtb Viewer", \
      :variable => eqtbview_var, \
      :onvalue => 1, \
      :offvalue => 0
    main_window.listeners.push self
    @slots = {
      :set_hexview_var => proc {
        |v|
        if hexview_var.value != v.to_s
          hexview_var.value = v
        end
      },
      :set_log_var => proc {
        |v|
        if log_var.value != v.to_s
          log_var.value = v
        end
      },
      :set_error_log_var => proc {
        |v|
        if error_log_var.value != v.to_s
          error_log_var.value = v
        end
      },
      :set_memview_var => proc {
        |v|
        if memview_var.value != v.to_s
          memview_var.value = v
        end
      },
      :set_eqtbview_var => proc {
        |v|
        if eqtbview_var.value != v.to_s
          eqtbview_var.value = v
        end
      },
      :enable_hexview => proc {
        @handle.entryconfigure "Hex View", :state => 'normal'
      },
      :disable_hexview => proc {
        main_window.signal :set_hexview_var, 0
        @handle.entryconfigure "Hex View", :state => 'disabled'
      },
      :enable_log => proc {
        @handle.entryconfigure "Log", :state => 'normal'
      },
      :disable_log => proc {
        main_window.signal :set_log_var, 0
        @handle.entryconfigure "Log", :state => 'disabled'
      },
      :enable_error_log => proc {
        @handle.entryconfigure "Error Log", :state => 'normal'
      },
      :disable_error_log => proc {
        main_window.signal :set_error_log_var, 0
        @handle.entryconfigure "Error Log", :state => 'disabled'
      },
      :enable_memview => proc {
        @handle.entryconfigure "TeX Main Memory Viewer", :state => 'normal'
      },
      :disable_memview => proc {
        main_window.signal :set_memview_var, 0
        @handle.entryconfigure "TeX Main Memory Viewer", :state => 'disabled'
      },
      :enable_eqtbview => proc {
        @handle.entryconfigure "Eqtb Viewer", :state => 'normal'
      },
      :disable_eqtbview => proc {
        main_window.signal :set_eqtbview_var, 0
        @handle.entryconfigure "Eqtb Viewer", :state => 'disabled'
      }
    }
  end
end

class MainArea < Dispatcher
  attr_reader :handle

  def initialize(main_window)
    super()
    @main_window = main_window
    @handle = TkFrame.new @main_window.root
    @handle.relief 'groove'
    @handle.borderwidth 1
    @tabs = nil
    @hexviewer = HexViewer.new(
      @main_window, @main_window.shex, @main_window.bhex
    )
    @log_w = LogViewer.new(@main_window, @main_window.slog)
    @error_log_w = LogViewer.new(@main_window, @main_window.serr)
    @memviewer = MemoryViewer.new(@main_window, @main_window.smem)
    @eqtbviewer = EqtbViewer.new(@main_window, @main_window.seqtb)
    @main_window.listeners.push self
    @slots = {
      :show_hexview => proc {
        |*args|
        show_hexview(*args)
      },
      :destroy_hexview => proc {
        @main_window.signal :disable_hexview
        @hexviewer.clear
        show_hexview(false, false)
        GC.start
      },
      :show_log => proc {
        |*args|
        show_log(*args)
      },
      :show_error_log => proc {
        |*args|
        show_error_log(*args)
      },
      :show_memview => proc {
        |*args|
        show_memview(*args)
      },
      :destroy_memview => proc {
        @main_window.signal :disable_memview
        @memviewer.clear
        show_memview(false, false)
        GC.start
      },
      :show_eqtbview => proc {
        |*args|
        show_eqtbview(*args)
      },
      :destroy_eqtbview => proc {
        @main_window.signal :disable_eqtbview
        @eqtbviewer.clear
        show_eqtbview(false, false)
        GC.start
      },
      :xv_label => proc {
        |s|
        @hexviewer.label(s)
      },
      :xv_send => proc {
        |data|
        @hexviewer.send(data)
      },
      :xv_flush => proc {
        @hexviewer.flush
      },
      :xv_refresh => proc {
        @hexviewer.refresh
      },
      :log_start => proc {
        @log_w.log_start
      },
      :log_write => proc {
        |msg|
        @log_w << msg
      },
      :log_end => proc {
        @log_w.log_end
      },
      :log_refresh => proc {
        @log_w.refresh
      },
      :error_log_start => proc {
        @error_log_w.log_start
      },
      :error_log_write => proc {
        |msg|
        @error_log_w << msg
      },
      :error_log_end => proc {
        @error_log_w.log_end
      },
      :error_log_refresh => proc {
        @error_log_w.refresh
      },
      :mv_start => proc {
        @memviewer.log_start
      },
      :mv_write => proc {
        |msg|
        @memviewer << msg
      },
      :mv_end => proc {
        @memviewer.log_end
      },
      :mv_refresh => proc {
        @memviewer.refresh
      },
      :ev_start => proc {
        @eqtbviewer.log_start
      },
      :ev_write => proc {
        |msg|
        @eqtbviewer << msg
      },
      :ev_end => proc {
        @eqtbviewer.log_end
      },
      :ev_refresh => proc {
        @eqtbviewer.refresh
      }
    }
  end

  def show_hexview(visible = true, selected = true)
    if not visible
      @main_window.signal :set_hexview_var, 0
      if @tabs and @tabs.tabs.include? @hexviewer.handle
        @tabs.forget @hexviewer.handle
        @hexviewer.destroy
        if @tabs.tabs.empty?
          @tabs.unpack
          @tabs.destroy
          @tabs = nil
        end
      end
      return
    end
    @main_window.signal :set_hexview_var, 1
    create_tabs if not @tabs
    @hexviewer.create @tabs
    if not @tabs.tabs.include? @hexviewer.handle
      @tabs.add @hexviewer.handle, :text => "Hex View"
    end
    @tabs.select @hexviewer.handle if selected
  end

  def show_log(visible = true, selected = true)
    if not visible
      @main_window.signal :set_log_var, 0
      if @tabs and @tabs.tabs.include? @log_w.handle
        @tabs.forget @log_w.handle
        @log_w.destroy
        if @tabs.tabs.empty?
          @tabs.unpack
          @tabs.destroy
          @tabs = nil
        end
      end
      return
    end
    @main_window.signal :set_log_var, 1
    create_tabs if not @tabs
    @log_w.create @tabs
    if not @tabs.tabs.include? @log_w.handle
      @tabs.add @log_w.handle, :text => "Log"
    end
    @tabs.select @log_w.handle if selected
  end

  def show_error_log(visible = true, selected = true)
    if not visible
      @main_window.signal :set_error_log_var, 0
      if @tabs and @tabs.tabs.include? @error_log_w.handle
        @tabs.forget @error_log_w.handle
        @error_log_w.destroy
        if @tabs.tabs.empty?
          @tabs.unpack
          @tabs.destroy
          @tabs = nil
        end
      end
      return
    end
    @main_window.signal :set_error_log_var, 1
    create_tabs if not @tabs
    @error_log_w.create @tabs
    if not @tabs.tabs.include? @error_log_w.handle
      @tabs.add @error_log_w.handle, :text => "Error Log"
    end
    @tabs.select @error_log_w.handle if selected
  end

  def show_memview(visible = true, selected = true)
    if not visible
      @main_window.signal :set_memview_var, 0
      if @tabs and @tabs.tabs.include? @memviewer.handle
        @tabs.forget @memviewer.handle
        @memviewer.destroy
        if @tabs.tabs.empty?
          @tabs.unpack
          @tabs.destroy
          @tabs = nil
        end
      end
      return
    end
    @main_window.signal :set_memview_var, 1
    create_tabs if not @tabs
    @memviewer.create @tabs
    if not @tabs.tabs.include? @memviewer.handle
      @tabs.add @memviewer.handle, :text => "Tex Main Memory Viewer"
    end
    @tabs.select @memviewer.handle if selected
  end

  def show_eqtbview(visible = true, selected = true)
    if not visible
      @main_window.signal :set_eqtbview_var, 0
      if @tabs and @tabs.tabs.include? @eqtbviewer.handle
        @tabs.forget @eqtbviewer.handle
        @eqtbviewer.destroy
        if @tabs.tabs.empty?
          @tabs.unpack
          @tabs.destroy
          @tabs = nil
        end
      end
      return
    end
    @main_window.signal :set_eqtbview_var, 1
    create_tabs if not @tabs
    @eqtbviewer.create @tabs
    if not @tabs.tabs.include? @eqtbviewer.handle
      @tabs.add @eqtbviewer.handle, :text => "Eqtb Viewer"
    end
    @tabs.select @eqtbviewer.handle if selected
  end

  def create_tabs
    @tabs = Tk::Tile::Notebook.new @handle
    @tabs.pack :side => 'top', :fill => 'both', :expand => true
  end
end

class StatusBar < Dispatcher
  attr_reader :handle

  def initialize(main_window)
    super()
    @tips = []
    @handle = TkFrame.new main_window.root
    @handle.relief 'ridge'
    @handle.borderwidth 2
    self.push ""
    main_window.listeners.push self
    @slots = {
      :status => proc {
        |msg|
        clear
        push msg
      }
    }
  end

  def push(value)
    if not @tips.empty?
      @tips.push Tk::Tile::Separator.new @handle
      @tips.last.orient 'vertical'
      @tips.last.pack \
        :side => 'left', :fill => 'y', \
        :padx => 4, :pady => 2, \
        :anchor => 'w'
    end
    @tips.push TkLabel.new @handle
    @tips.last.relief 'flat'
    @tips.last.borderwidth 2
    @tips.last.text value
    @tips.last.pack :side => 'left', :anchor => 'w'
  end

  def clear
    while not @tips.empty?
      tip = @tips.last
      tip.unpack
      tip.destroy
      @tips.pop
      tip = nil
    end
  end
end

class ProgressBar < Dispatcher
  attr_reader :handle

  def initialize(main_window, owner)
    super()
    @main_window = main_window
    @owner = owner
    @handle = nil
    @progressbar = nil
    @main_window.listeners.push self
    @slots = {
      :get_max_perc => proc {
        400
      },
      :progress => proc {
        |v|
        @progressbar.value v
        @main_window.signal :update
      }
    }
  end

  def start
    @handle = TkFrame.new @owner.handle
    @handle.relief 'flat'
    @handle.borderwidth 0
    @handle.pack :side => 'top', :fill => 'both', :expand => true
    @progressbar = Tk::Tile::Progressbar.new @handle
    @progressbar.orient 'horizontal'
    @progressbar.length @main_window.signal :get_max_perc
    @progressbar.maximum @main_window.signal :get_max_perc
    @progressbar.mode 'determinate'
    @progressbar.place :relx => 0.5, :rely => 0.5, :anchor => 'center'
  end

  def finish
    @handle.unpack
    @progressbar.destroy
    @handle.destroy
    @handle = @progressbar = nil
    GC.start
  end
end

class MainWindow < Dispatcher
  VERSION = "0.1.0"
  MIN_WIDTH = 800
  MIN_HEIGHT = 500

  attr_reader :serr, :slog, :shex, :bhex, :smem, :seqtb, :root, :tex

  def initialize
    super()
    @serr = Viewer::Storage.new
    @slog = Viewer::Storage.new
    @shex = Viewer::Storage.new
    @bhex = HexViewer::LineBuffer.new
    @smem = Viewer::Storage.new
    @seqtb = Viewer::Storage.new
    @fmt_fd = nil
    @tex = PdfTeX::Data.new self

    setup_tk

    @root = TkRoot.new
    @root.title title
    @root.protocol "WM_DELETE_WINDOW", proc {on_exit}
    adjust_minsize

    @menu_bar = MenuBar.new self
    @root.menu @menu_bar.handle
    @main_area = MainArea.new self
    @status_bar = StatusBar.new self
    @progress_bar = ProgressBar.new self, @main_area
    @size_grip = Tk::Tile::SizeGrip.new @root
    adjust_widgets

    @listeners.push self
    @slots = {
      :redirect => proc {
        |r|
        @transtab = r
      },
      :fmt_open => proc {
        open_fmt_file
      },
      :fmt_close => proc {
        signal :destroy_hexview
        signal :destroy_memview
        signal :destroy_eqtbview
        @tex.cleanup
        signal :status, "No .fmt file loaded"
        GC.start
      },
      :exit => proc {
        on_exit
      },
      :update => proc {
        @root.update
      }
    }

    signal :disable_hexview
    signal :disable_memview
    signal :disable_eqtbview
    signal :status, "No .fmt file loaded."
  end

  def setup_tk
  end
  private :setup_tk

  def adjust_minsize
    @root.minsize \
      [@root.winfo_width, MIN_WIDTH].max, \
      [@root.winfo_height, MIN_HEIGHT].max
  end
  private :adjust_minsize

  def adjust_widgets
    TkGrid.configure @main_area.handle, \
      :column => 0, :row => 0, \
      :columnspan => 2, :rowspan => 1, \
      :sticky => 'snew'
    TkGrid.configure @status_bar.handle, \
      :column => 0, :row => 1, \
      :columnspan => 1, :rowspan => 1, \
      :sticky => 'snew'
    TkGrid.configure @size_grip, \
      :column => 1, :row => 1, \
      :columnspan => 1, :rowspan => 1,
      :sticky => 'se'

    TkGrid.columnconfigure @root, 0, :weight => 1
    TkGrid.rowconfigure @root, 0, :weight => 1
  end
  private :adjust_widgets

  def title
    "pdfTeX .fmt file viewer (version #{VERSION})"
  end

  def run
    Tk.mainloop
  end

  def on_exit
    @root.destroy
  end

  def open_fmt_file
    filename = Tk::getOpenFile \
      :filetypes => [
        ["TeX Format Files", "*.fmt"],
        ["All Files", "*.*"]
      ], \
      :multiple => false, \
      :title => "Choose a TeX format file"
    if not filename or filename.empty?
      return
    end
    close_fmt_file
    begin
      @fmt_fd = File.open filename, "rb"
    rescue
      alert "File \"#{filename}\" cannot be opened."
      return
    end
    signal :disable_open
    signal :disable_close
    signal :destroy_hexview
    signal :disable_log
    signal :disable_error_log
    signal :destroy_memview
    signal :destroy_eqtbview
    @shex.clear
    @tex.cleanup
    @progress_bar.start
    result = @tex.load_fmt_file @fmt_fd
    @progress_bar.finish
    close_fmt_file
    if not result
      @tex.cleanup
      signal :status, "No .fmt file loaded."
      signal :enable_open
      signal :enable_close
      signal :destroy_hexview
      signal :enable_log
      signal :enable_error_log
      @shex.clear
      GC.start
      return
    end
    signal :enable_open
    signal :enable_close
    signal :enable_hexview
    signal :enable_log
    signal :enable_error_log
    signal :enable_memview
    signal :enable_eqtbview
    GC.start
  end

  def close_fmt_file
    @fmt_fd.close if @fmt_fd
    @fmt_fd = nil
  end

  def alert(msg)
    signal :error_log_start
    signal :error_log_write, msg
    signal :error_log_end
    Tk::messageBox \
      :type => 'ok', \
      :message => msg, \
      :title => "Error", \
      :icon => 'error', \
      :default => 'ok'
  end
end

MainWindow.new.run
