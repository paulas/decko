format do
  def render_erb locals={}, template=nil, a_binding=nil, &block
    template ||= block.call
    a_binding ||= binding
    locals.each do |k,v|
      #a_binding.local_variable_set(k, v) # needs ruby 2.1
      a_binding.eval("@#{k}=v")
    end
    ERB.new(template,nil,'-').result(a_binding)
  end
end
