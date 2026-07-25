require 'xcodeproj'

# Registers new source files with the Xcode project and assigns target membership.
# Xcode will not pick up files created outside the IDE, so this must be run from the
# repo root after adding any .swift file:
#
#   ruby add_files.rb
#
# Re-running is safe: both the file reference and the target membership are idempotent.

project_path = 'Leastimator.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Leastimator group
group = project.main_group['Leastimator']

# Files to add to main app target only
app_only_files = [
  'OdoReadingWriter.swift',
  'OdometerIntents.swift'
]

# Files to add to both app and widget targets.
# Anything an App Intent or the widget configuration touches belongs here.
shared_files = [
  'VehicleEntity.swift'
]

app_target = project.targets.find { |t| t.name == 'Leastimator' }
widget_target = project.targets.find { |t| t.name == 'EstimateWidgetExtension' }

def add_file_to_targets(project, group, file_name, targets)
  # Skip files not yet written to disk so a partial run doesn't register a
  # dangling reference that breaks the build.
  unless File.exist?(File.join('Leastimator', file_name))
    puts "Skipping #{file_name} (not found on disk)"
    return
  end

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
puts "Saved #{project_path}"
