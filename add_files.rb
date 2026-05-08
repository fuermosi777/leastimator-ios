require 'xcodeproj'

project_path = 'Leastimator.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Leastimator group
group = project.main_group['Leastimator']

# Files to add to main app target only
app_only_files = [
  'HistoryRangePicker.swift',
  'ReadingRowView.swift',
  'HistoryLineChart.swift',
  'VehicleHistoryView.swift',
  'GuidingMessageBoard.swift',
  'StatsSection.swift',
  'ProjectedMileageExplanationView.swift',
  'CoachMessageView.swift'
]

# Files to add to both app and widget targets
shared_files = [
  'ICloudManager.swift'
]

app_target = project.targets.find { |t| t.name == 'Leastimator' }
widget_target = project.targets.find { |t| t.name == 'EstimateWidgetExtension' }

def add_file_to_targets(project, group, file_name, targets)
  file_ref = group.find_file_by_path(file_name)
  if file_ref.nil?
    file_ref = group.new_file(file_name)
  end
  
  targets.each do |target|
    unless target.source_build_phase.files_references.include?(file_ref)
      target.add_file_references([file_ref])
      puts "Added #{file_name} to target #{target.name}"
    end
  end
end

app_only_files.each { |f| add_file_to_targets(project, group, f, [app_target]) }
shared_files.each { |f| add_file_to_targets(project, group, f, [app_target, widget_target]) }

project.save
