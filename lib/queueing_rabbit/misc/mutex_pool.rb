class MutexPool
  attr_reader :size

  def initialize(size = 1)
    @pool = Queue.new
    @size = size
    @pop_mutex = Mutex.new
    @lock_mutex = Mutex.new
    @locked_pool = []
    @size.times { @pool << Mutex.new }
  end

  def synchronize(&block)
    mutex = @pop_mutex.synchronize { @pool.pop }
    mutex.synchronize(&block)
  ensure
    @pool << mutex if mutex
  end

  def lock
    @lock_mutex.lock
    @pop_mutex.lock
    @locked_pool = @size.times.map { |i| @pool.pop }
  end

  def unlock
    raise ThreadError, 'The pool is not locked' unless @lock_mutex.locked?
    @locked_pool.each { |m| @pool << m }
    @locked_pool = []
    @pop_mutex.unlock
    @lock_mutex.unlock
  end
end

