require 'spec_helper'

describe MutexPool do
  it 'can be created with a size' do
    expect(MutexPool.new(5)).to be_a(MutexPool)
  end

  it 'can be created without a size and will have size of 1' do
    pool = MutexPool.new
    expect(pool).to be_a(MutexPool)
    expect(pool.size).to eq 1
  end

  it 'allows for up to n locks to be allocated' do
    pool = MutexPool.new(3)
    expect(pool.synchronize do
             pool.synchronize do
               pool.synchronize do
                 1
               end
             end
           end).to eq 1
  end

  it 'can be locked so no one can obtain locks' do
    pool = MutexPool.new(2)
    pool.lock
    thread = Thread.new { pool.synchronize { true } }
    sleep 0.1
    expect(thread.status).to eq 'sleep'
    thread.exit
  end

  it 'can be unlocked allowing consumers to obtain locks again' do
    pool = MutexPool.new(2)
    pool.lock
    thread = Thread.new { pool.synchronize { true } }
    sleep 0.1
    expect{pool.unlock; sleep 0.1}.to change{thread.status}.from('sleep').to(false)
  end
end