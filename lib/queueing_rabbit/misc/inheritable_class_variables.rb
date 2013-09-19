module QueueingRabbit

  module InheritableClassVariables
    
    def inheritable_variables(*args)
      @inheritable_variables ||= [:inheritable_variables]
      @inheritable_variables += args
    end

    def inherited(subclass)
      @inheritable_variables ||= []
      @inheritable_variables.each do |var|
        if !subclass.instance_variable_get("@#{var}") ||
           subclass.instance_variable_get("@#{var}").empty?
          subclass.instance_variable_set("@#{var}",
                                         instance_variable_get("@#{var}"))
        end
      end
    end

  end

end