# encoding: utf-8

module Nanoc3::HashExtensions

  # Returns a new hash where all keys are recursively converted to symbols by
  # calling {Nanoc3::ArrayExtensions#symbolize_keys} or
  # {Nanoc3::HashExtensions#symbolize_keys}.
  #
  # @return [Hash] The converted hash
  def symbolize_keys
    inject({}) do |hash, (key, value)|
      hash.merge(key.to_sym => value.respond_to?(:symbolize_keys) ? value.symbolize_keys : value)
    end
  end

  # Returns a new hash where all keys are recursively converted to strings by
  # calling {Nanoc3::ArrayExtensions#stringify_keys} or
  # {Nanoc3::HashExtensions#stringify_keys}.
  #
  # @return [Hash] The converted hash
  def stringify_keys
    inject({}) do |hash, (key, value)|
      hash.merge(key.to_s => value.respond_to?(:stringify_keys) ? value.stringify_keys : value)
    end
  end

  # Freezes the contents of the hash, as well as all hash values. The hash
  # values will be frozen using {#freeze_recursively} if they respond to
  # that message, or {#freeze} if they do not.
  #
  # @see Array#freeze_recursively
  #
  # @return [void]
  def freeze_recursively
    freeze
    each_pair do |key, value|
      if value.respond_to?(:freeze_recursively)
        value.freeze_recursively
      else
        value.freeze
      end
    end
  end

end

class Hash
  include Nanoc3::HashExtensions
end
