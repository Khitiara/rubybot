require 'spec_helper'
require 'rubybot/core/acl'

# rubocop:disable Style/RescueModifier

RSpec.describe Rubybot::Core::Acl do
  let :bot do
    b = instance_double 'Rubybot::Bot', owner: 'arthurdent'
    allow(b).to receive(:bot_config).and_return(acl: {})
    allow(b).to receive(:save)
    b
  end

  subject { described_class.new bot }

  it('contains the bot owner by default') { expect(subject.levels).to eq('arthurdent' => 0) }

  describe '#set' do
    it('fails for the owner') { expect { subject.set 'arthurdent', 2 }.to raise_error 'Not allowed' }
    it 'doesn\'t change for the owner' do
      expect { subject.set 'arthurdent', 2 rescue 'Not allowed' }.not_to change(subject, :levels)
    end
    it('fails for invalid levels') { expect { subject.set 'bla', -2 }.to raise_error 'Not allowed' }
    it 'doesn\'t change for invalid levels' do
      expect { subject.set 'bla', -2 rescue 'Not allowed' }.not_to change(subject, :levels)
    end
    it 'adds a new user' do
      expect { subject.set 'bla', 2 }.to change { subject.levels.key? 'bla' }.from(false).to(true)
      expect(subject.levels['bla']).to eq 2
    end
    it 'changes an existing user' do
      subject.set 'bla', 2
      expect { subject.set 'bla', 1 }.to change { subject.levels['bla'] }.from(2).to(1)
    end
  end

  describe '#get' do
    it('returns the correct value for a valid user') { expect(subject.get 'arthurdent').to eq 0 }
    it('returns -1 for an invalid user') { expect(subject.get 'zaphodbeeblebrox').to eq(-1) }
  end

  describe '#rm' do
    it('fails for the owner') { expect { subject.rm 'arthurdent' }.to raise_error 'Not allowed' }
    it 'doesn\'t change for the owner' do
      expect { subject.rm 'arthurdent' rescue 'Not allowed' }.not_to change(subject, :levels)
    end
    it 'removes any other user' do
      subject.set 'bla', 2
      expect { subject.rm 'bla' }.to change { subject.levels.key? 'bla' }.from(true).to(false)
    end
  end

  describe '#authed?' do
    it('returns false for an unknown user') { expect(subject.authed? 'asdf').to be_falsey }
    it 'returns false for higher level' do
      subject.set 'bla', 3
      expect(subject.authed? 'bla').to be_falsey
      expect(subject.authed? 'bla', 2).to be_falsey
    end
    it 'returns true for equal or lower levels' do
      subject.set 'bla', 2
      expect(subject.authed? 'bla', 2).to eq true
      expect(subject.authed? 'bla', 4).to eq true
    end
  end

  describe '#auth_or_fail' do
    let :channel do
      channel = double 'channel'
      allow(channel).to receive(:msg).with(kind_of String)
      channel
    end

    it 'is silent for successful authentication' do
      expect(subject.auth_or_fail channel, double(name: 'arthurdent', nick: 'arthurdent')).to be_truthy
    end
    it 'replies for unsucessful authentication' do
      expect(subject.auth_or_fail channel, double(name: 'bla', nick: 'bla')).to be_falsey
      expect(channel).to have_received(:msg).with 'bla is not permitted to do that!'
    end
  end

  describe '#save' do
    it 'does\'t save the owner' do
      subject.save
      expect(subject.bot).to have_received :save
      expect(subject.bot.bot_config).to eq(acl: {})
    end
    it 'does save other users' do
      subject.set 'bla', 2
      subject.save
      expect(subject.bot).to have_received :save
      expect(subject.bot.bot_config).to eq(acl: { 'bla' => 2 })
    end
  end
end
