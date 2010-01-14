require 'test/helper'

class Nanoc2::PluginTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_identifiers
    # Create plugin
    plugin = Nanoc2::Plugin.new

    # Update identifier
    plugin.class.class_eval { identifier :foo }

    # Check
    assert_equal(:foo, plugin.class.class_eval { identifier })
    assert_equal([ :foo ], plugin.class.class_eval { identifiers })

    # Update identifier
    plugin.class.class_eval { identifiers :foo, :bar }

    # Check
    assert_equal([ :foo, :bar ], plugin.class.class_eval { identifiers })
  end

  def test_named
    # Find existant filter
    filter = Nanoc2::Filter.named(:erb)
    assert(!filter.nil?)

    # Find non-existant filter
    filter = Nanoc2::Filter.named(:lksdaffhdlkashlgkskahf)
    assert(filter.nil?)
  end

  def test_find
    # Find existant filter
    filter = Nanoc2::Filter.named(:erb)
    assert(!filter.nil?)

    # Find non-existant filter
    filter = Nanoc2::Filter.named(:lksdaffhdlkashlgkskahf)
    assert(filter.nil?)
  end

end
