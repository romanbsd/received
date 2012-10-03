require 'received/backend/base'
require 'received/backend/mongodb'

describe 'Observable' do
  subject { Received::Backend::Mongodb.new('host' => '127.0.0.1', 'database' => 'spec', 'collection' => 'inbox') }

  it "notifies observers" do
    observer = mock('observer', :after_save => true)
    Received::Backend::Base.add_observer(observer)
    mail = {
      from: 'spec@example.com',
      rcpt: ['to1@example.com', 'to2@example.com'],
      body: 'spec'
    }
    observer.should_receive(:after_save)
    subject.store(mail)
  end

end
