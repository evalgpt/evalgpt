class JekyllApp
  attr_accessor :title, :ga_tracker, :style_sheet

  def initialize(title, ga_tracker, style_sheet)
    @title = title
    @ga_tracker = ga_tracker
    @style_sheet = style_sheet
  end
end

# Create 5 Jekyll apps
app1 = JekyllApp.new("App 1", "UA-12345678-1", "style1.css")
app2 = JekyllApp.new("App 2", "UA-12345678-2", "style2.css")
app3 = JekyllApp.new("App 3", "UA-12345678-3", "style3.css")
app4 = JekyllApp.new("App 4", "UA-12345678-4", "style4.css")
app5 = JekyllApp.new("App 5", "UA-12345678-5", "style5.css")

# Print out the Jekyll apps
puts "Jekyll Apps:"
puts "Title \t\t GA Tracker \t\t Style Sheet"
puts "-----------------------------------------------"
puts "#{app1.title} \t #{app1.ga_tracker} \t\t #{app1.style_sheet}"
puts "#{app2.title} \t #{app2.ga_tracker} \t\t #{app2.style_sheet}"
puts "#{app3.title} \t #{app3.ga_tracker} \t\t #{app3.style_sheet}"
puts "#{app4.title} \t #{app4.ga_tracker} \t\t #{app4.style_sheet}"
puts "#{app5.title} \t #{app5.ga_tracker} \t\t #{app5.style_sheet}"