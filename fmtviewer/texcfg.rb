#                                                         -*- coding: utf-8 -*-
#! \file    ./fmtviewer/texcfg.rb
#! \author  Jiří Kučera, <sanczes@gmail.com>
#! \stamp   2014-09-09 08:58:32 (UTC+01:00, DST+01:00)
#! \project textools: Utilities for debugging TeX/LaTeX output.
#! \license MIT
#! \version 0.1.0
#! \fdesc   Some TeX/pdfTeX texmf.cnf variables settings.
#

# Do fine tuning here. The values of defined constants affect .fmt file loading
# time or .fmt file loading crash.

module TeXLiveConfig

  TEXMF_CNF = {
    #:main_memory => 5000000,
    #:extra_mem_top => 0,
    #:extra_mem_bot => 0,

    #:font_mem_size => 8000000,

    #:font_max => 9000,

    #:hash_extra => 600000,

    #:pool_size => 6250000,

    #:string_vacancies => 90000,

    #:max_strings => 500000,

    #:pool_free => 47500,

    #:buf_size => 200000,

    :trie_size => 1000000,

    :hyph_size => 8191,

    :nest_size => 500,
    :max_in_open => 15,

    :param_size => 10000,
    :save_size  => 100000,
    :stack_size => 5000,

    :ocp_buf_size => 500000,
    :ocp_stack_size => 10000,
    :ocp_list_size => 1000,

    :dvi_buf_size => 16384,

    :error_line => 79,
    :half_error_line => 50,
    :max_print_line => 79
  }

  def self.setvar(name, dflt)
    if TEXMF_CNF[name] == nil
      return dflt
    end
    TEXMF_CNF[name]
  end

end
