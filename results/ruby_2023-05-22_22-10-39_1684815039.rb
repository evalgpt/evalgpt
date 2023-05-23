class JekyllApp
  attr_accessor :title, :ga_tracker, :style_sheet

  def initialize(title, ga_tracker, style_sheet)
    @title = title
    @ga_tracker = ga_tracker
    @style_sheet = style_sheet
  end
end

# Create an array of 5 Jekyll apps
apps = [
  JekyllApp.new("App 1", "UA-12345678-1", "style1.css"),
  JekyllApp.new("App 2", "UA-12345678-2", "style2.css"),
  JekyllApp.new("App 3", "UA-12345678-3", "style3.css"),
  JekyllApp.new("App 4", "UA-12345678-4", "style4.css"),
  JekyllApp.new("App 5", "UA-12345678-5", "style5.css")
]

# Print out the Jekyll apps
puts "Jekyll Apps:"
puts "Title \t\t GA Tracker \t\t Style Sheet"
puts "-----------------------------------------------"
apps.each do |app|
  puts "#{app.title} \t #{app.ga_tracker} \t\t #{app.style_sheet}"
end