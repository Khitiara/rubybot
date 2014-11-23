class MacroSemanticError < Exception
  attr_accessor :msg

  def initialize(msg = '')
    @msg = msg
  end
end