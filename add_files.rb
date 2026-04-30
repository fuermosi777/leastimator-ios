require 'xcodeproj'

project_path = 'Leastimator.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Leastimator group
group = project.main_group['Leastimator']

# Files to add
files_to_add = [
  'HistoryRangePicker.swift',
  'ReadingRowView.swift',
  'HistoryLineChart.swift',
  'VehicleHistoryView.swift'
]

# Target
target = project.targets.find { |t| t.name == 'Leastimator' }

files_to_add.each do |file_name|
  file_ref = group.find_file_by_path(file_name)
  if file_ref.nil?
    file_ref = group.new_file(file_name)
    target.add_file_references([file_ref])
    puts "Added #{file_name} to project"
  else
    puts "#{file_name} already in project"
  end
end

project.save
