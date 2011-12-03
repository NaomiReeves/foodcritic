rule "FC002", "Avoid string interpolation where not required" do
  description "When setting a resource value avoid string interpolation where not required."
  recipe do |ast|
    ast.xpath(%q{//string_literal[count(descendant::string_embexpr) = 1 and
      count(string_add/tstring_content|string_add/string_add/tstring_content) = 0]}).map{|str| match(str)}
  end
end

rule "FC003", "Check whether you are running with chef server before using server-specific features" do
  description "Ideally your cookbooks should be usable without requiring chef server."
  recipe do |ast|
    checks_for_chef_solo?(ast) ? [] : searches(ast).map{|s| match(s)}
  end
end

rule "FC004", "Use a service resource to start and stop services" do
  description "Avoid use of execute to control services - use the service resource instead."
  recipe do |ast|
    find_resources(ast, 'execute').find_all do |cmd|
      cmd_str = (resource_attribute('command', cmd) || resource_name(cmd)).to_s
      cmd_str.include?('/etc/init.d') || cmd_str.start_with?('service ') || cmd_str.start_with?('/sbin/service ')
    end.map{|cmd| match(cmd)}
  end
end

rule "FC005", "Avoid repetition of resource declarations" do
  description "Where you have a lot of resources that vary in only a single attribute wrap them in a loop for brevity."
  recipe do |ast|
    matches = []
    # do all of the attributes for all resources of a given type match apart aside from one?
    resource_attributes_by_type(ast).each do |type, resource_atts|
        sorted_atts = resource_atts.map{|atts| atts.to_a.sort{|x,y| x.first.to_s <=> y.first.to_s }}
        if sorted_atts.all?{|att| (att - sorted_atts.inject{|atts,a| atts & a}).length == 1}
          matches << match(find_resources(ast, type).first)
        end
    end
    matches
  end
end
