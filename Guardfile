# A sample Guardfile
# More info at https://github.com/guard/guard#readme

#guard :rspec, cmd: 'bundle exec env COVERAGE=false rspec' do
guard :rspec, cmd: 'bundle exec wagn rspec' do
  
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  # Rails example
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
#  watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
#  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  
#  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
#  watch('config/routes.rb')                           { "spec/routing" }
#  watch('app/controllers/application_controller.rb')  { "spec/controllers" }

  # Capybara features specs
#  watch(%r{^app/views/(.+)/.*\.(erb|haml|slim)$})     { |m| "spec/features/#{m[1]}_spec.rb" }

  # Wagn mods
  watch(%r{^mod/(.+)\.rb})                            { |m| "mod/spec/#{m[1]}_spec.rb" }
  watch(%r{^tmp/mod/(.+)\.rb})                            { |m| "mod/spec/#{m[1]}_spec.rb" }


  # Turnip features and steps
#  watch(%r{^spec/acceptance/(.+)\.feature$})
#  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})   { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
  
  #callback(:start_begin) { puts "guard-rspec is watching ..." }
  #callback(:run_on_modifications_begin) { puts "<script>document.body.innerHTML = '';</script>" } # use js to clear textmate's html view
end

