# encoding: utf-8

module Nanoc3

  # Nanoc3::CodeSnippet represent a piece of custom code of a nanoc site. It
  # contains the textual source code as well as a mtime, which is used to
  # speed up site compilation.
  class CodeSnippet

    # The Nanoc3::Site this code snippet belongs to.
    attr_accessor :site

    # A string containing the actual code in this code snippet.
    attr_reader :data

    # The filename corresponding to this code snippet.
    attr_reader :filename

    # The time where this code snippet was last modified.
    attr_reader :mtime

    # Creates a new code snippet.
    #
    # +data+::     The raw source code which will be executed before compilation.
    #
    # +filename+:: The filename corresponding to this code snippet.
    #
    # +mtime+::    The time when the code was last modified (can be nil).
    def initialize(data, filename, mtime=nil)
      @data     = data
      @filename = filename
      @mtime    = mtime
    end

    # Loads the code by executing it.
    def load
      eval(@data, TOPLEVEL_BINDING, @filename)
    end

  end

end
