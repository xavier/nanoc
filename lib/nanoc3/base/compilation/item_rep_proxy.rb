# encoding: utf-8

require 'forwardable'

module Nanoc3

  # Represents an item representation, but provides an interface that is
  # easier to use when writing compilation and routing rules. It is also
  # responsible for fetching the necessary information from the compiler, such
  # as assigns.
  #
  # The API provided by item representation proxies allows layout identifiers
  # to be given as literals instead of as references to {Nanoc3::Layout}.
  class ItemRepProxy

    extend Forwardable

    def_delegators :@item_rep, :item, :name, :binary, :binary?, :compiled_content, :has_snapshot?, :raw_path, :path
    def_delegator  :@item_rep, :snapshot

    # @param [Nanoc3::ItemRep] item_rep The item representation that this
    #   proxy should behave like
    #
    # @param [Nanoc3::Compiler] compiler The compiler that will provide the
    #   necessary compilation-related functionality.
    def initialize(item_rep, compiler)
      @item_rep = item_rep
      @compiler = compiler
    end

    # Runs the item content through the given filter with the given arguments.
    # This method will replace the content of the `:last` snapshot with the
    # filtered content of the last snapshot.
    #
    # This method is supposed to be called only in a compilation rule block
    # (see {Nanoc3::CompilerDSL#compile}).
    #
    # @see Nanoc3::ItemRep#filter
    #
    # @param [Symbol] filter_name The name of the filter to run the item
    #   representations' content through
    #
    # @param [Hash] filter_args The filter arguments that should be passed to
    #   the filter's #run method
    #
    # @return [void]
    def filter(name, args={})
      set_assigns
      @item_rep.filter(name, args)
    end

    # Lays out the item using the given layout. This method will replace the
    # content of the `:last` snapshot with the laid out content of the last
    # snapshot.
    #
    # This method is supposed to be called only in a compilation rule block
    # (see {Nanoc3::CompilerDSL#compile}).
    #
    # @see Nanoc3::ItemRep#layout
    #
    # @param [String] layout_identifier The identifier of the layout to use
    #
    # @return [void]
    def layout(layout_identifier)
      set_assigns

      layout = layout_with_identifier(layout_identifier)
      filter_name, filter_args = @compiler.filter_for_layout(layout)

      @item_rep.layout(layout, filter_name, filter_args)
    end

  private

    def set_assigns
      @item_rep.assigns = @compiler.assigns_for(@item_rep)
    end

    def layout_with_identifier(layout_identifier)
      layout ||= @compiler.site.layouts.find { |l| l.identifier == layout_identifier.cleaned_identifier }
      raise Nanoc3::Errors::UnknownLayout.new(layout_identifier) if layout.nil?
      layout
    end

  end

end
