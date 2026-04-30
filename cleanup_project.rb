require 'xcodeproj'

project_path = 'Leastimator.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Files to remove
files_to_remove = [
  'ChartSheetView.swift',
  'GraphPoint.swift'
]

# Target
target = project.targets.find { |t| t.name == 'Leastimator' }

files_to_remove.each do |file_name|
  # Search in all files
  file_ref = project.files.find { |f| f.path.end_with?(file_name) }
  
  if file_ref
    # Remove from target
    target.source_build_phase.remove_file_reference(file_ref)
    # Remove from project
    file_ref.remove_from_project
    puts "Removed #{file_name} from project"
  else
    puts "#{file_name} not found in project"
  end
end

project.save
