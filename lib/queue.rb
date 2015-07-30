require 'thread'
require 'monitor'
require 'net/http'


module Currency

  class Task

    def initialize(&block)
      @block = block if block_given?

    end

    def work
      @block.call
    end

  end


  class Queue
    attr_accessor :max_currency_num

    def initialize(jobs,max_currency_num=5)
      @max_currency_num = max_currency_num
      @jobs = jobs
      yield if block_given?
    end

    def start

      thread_count = [@jobs.length, @max_currency_num].min
      threads = Array.new(thread_count)
      work_queue = SizedQueue.new(thread_count)

      threads.extend(MonitorMixin)
      threads_available = threads.new_cond

      sys_exit = false

      consumer_thread = Thread.new do
        loop do

          break if sys_exit && work_queue.length == 0
          found_index = nil

          threads.synchronize do

            threads_available.wait_while do
              threads.select { |thread| thread.nil? || thread.status == false  ||
                  thread["finished"].nil? == false}.length == 0
            end

            found_index = threads.rindex { |thread| thread.nil? || thread.status == false ||
                thread["finished"].nil? == false }
          end

          task = work_queue.pop
          threads[found_index] = Thread.new(task) do

            task.work

            Thread.current["finished"] = true

            threads.synchronize do
              threads_available.signal
            end
          end
        end
      end

      producer_thread = Thread.new do

        @jobs.each do |task|
          work_queue << task

          threads.synchronize do
            threads_available.signal
          end
        end
        sys_exit = true
      end

      producer_thread.join
      consumer_thread.join #TODO: `join': No live threads left. Deadlock? (fatal)

      threads.each do |thread|
        thread.join unless thread.nil?
      end

    end

  end

end



