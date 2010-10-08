require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'ceml'

COMPLIMENT_SCRIPT = <<END_OF_SCRIPT
"Overwhelm a specific person with compliments"
gather 5-20 players within 4 blocks
ask organizer re target: Describe their appearance and location
tell agents: Look for |otherguy.target| and compliment them briefly, then move on.
END_OF_SCRIPT

ASKCHAIN_SCRIPT = <<ENDOFSCRIPT
"Meet your neighbor"
gather 2 players within 1 block
ask players re color: what's your favorite color?
ask players re observation: find someone near you with the color |otherguy.color|. what are they wearing?
ask players re rightmatch: are you wearing |otherguy.observation|?
ask players re task: take your new partner and see if you can find something beautiful in the park.

ENDOFSCRIPT



class Test::Unit::TestCase
  def play script
    @e = CEML::Engine.new(script)
  end

  def player id, *roles
    @e.add id, *roles
    @e.run
  end

  def asked id, rx
    p = @e.parts[id]
    assert_equal :ask, p[:said]
    assert_match rx, p[:q]
    p.delete :said
  end

  def told id, rx
    p = @e.parts[id]
    assert_match rx, p[:msg]
    p.delete :said
  end

  def says id, str
    @e.parts[id][:received] = str
    @e.run
    @e.parts[id][:received] = nil
  end
end
