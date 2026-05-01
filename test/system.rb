# Test system features needed for ccm

# ENV
puts ENV['HOME'] != nil  # true

# Dir.home
home = Dir.home
puts home.length > 0  # true

# system()
# Explicit flush so the child process's output doesn't race ahead of
# our buffered puts on platforms whose Ruby (e.g. mingw64) doesn't
# auto-flush before forking.
$stdout.flush
system("echo hello_from_system")  # hello_from_system

# backtick
result = `echo backtick_test`.strip
puts result  # backtick_test

# trap (just register, don't trigger)
trap('INT') { }
puts "trap set"

# $stdin — skip interactive test
# File.readlink — skip (needs symlink)

puts "done"
