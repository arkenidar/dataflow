require 'thread'

module Dataflow
  class Port  
    include Dataflow
    LOCK = Mutex.new

    class Stream
      include Dataflow
      declare :head, :tail
    
      # Defining each allows us to use the enumerable mixin
      # None of the list can be garbage collected less the head is
      # garbage collected, so it will grow indefinitely even though
      # the function isn't recursive.
      include Enumerable
      def each
        s = self
        loop do
          yield s.head
          s = s.tail
        end
      end

      # Backported Enumerable#take for any 1.8.6 compatible Ruby
      unless method_defined?(:take)
        def take(num)
          result = []
          each_with_index do |x, i|
            return result if num == i
            result << x
          end
        end
      end
    end
  
    # Create a stream object, bind it to the input variable
    # Instance variables are necessary because @tail is state
    def initialize(x)
      @tail = Stream.new
      unify x, @tail
    end
  
    # This needs to be synchronized because it uses @tail as state
    def send value
      LOCK.synchronize do
        unify @tail.head, value
        unify @tail.tail, Stream.new
        @tail = @tail.tail
      end
    end
  end
end

