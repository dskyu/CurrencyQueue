require_relative 'lib/queue'

tasks = []
20.times do |i|
  tasks.push Currency::Task.new {puts i; sleep(1)}
end

Currency::Queue.new(tasks).start