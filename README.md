##Currency Queue
用ruby写的一个并发队列类.可以自己指定并发量

###Example:

	tasks = []
	20.times do |i|
  	  tasks.push Currency::Task.new {puts i; sleep(1)}
	end

	Currency::Queue.new(tasks).start

