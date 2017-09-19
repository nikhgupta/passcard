SimpleCov.start do
  add_filter "/spec/"
  add_group "Extensions", "lib/extensions"
  add_group "Outputters", "lib/passe/outputter"
end
