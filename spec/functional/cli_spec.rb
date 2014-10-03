require 'unit_spec_helper'
require 'fakefs/spec_helpers'

describe Rpush::CLI do
  include FakeFS::SpecHelpers

  let(:cli) { Rpush::CLI.new }

  before do
    cli.stub(load: nil)
    Rpush::CLI.stub(new: cli)
    Rpush::Daemon.stub(:start)
    FakeFS.activate!
  end

  after do
    ENV.delete('RAILS_ENV')
    FakeFS.deactivate!
  end

  describe 'start' do
    describe 'rails' do
      before do
        ['bin/rails', 'config/environment.rb'].each do |path|
          FileUtils.mkdir_p(File.dirname(path))
          FileUtils.touch(path)
        end
      end

      it 'boots the Rails environment' do
        Rpush::CLI.start(['start'])
        expect(ENV['RAILS_ENV']).to eql('development')
      end
    end
  end
end
