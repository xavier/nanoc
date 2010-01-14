require 'test/helper'

class Nanoc2::Helpers::HTMLEscapeTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc2::Helpers::HTMLEscape

  def test_html_escape
    assert_equal('&lt;',    html_escape('<'))
    assert_equal('&gt;',    html_escape('>'))
    assert_equal('&amp;',   html_escape('&'))
    assert_equal('&quot;',  html_escape('"'))
  end

end
