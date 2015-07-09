require 'spec_helper'
require 'rubybot/plugins/tweet'
require 'support/twitter_mock'

RSpec.describe Rubybot::Plugins::Tweet do
  include Cinch::Test

  describe '#commands' do
    subject { described_class.new(make_bot).commands }

    it('returns a single command') { is_expected.to have_exactly(1).items }
  end

  let(:bot) { make_bot described_class, get_plugin_configuration(described_class) }

  it 'doesn\'t match an unrelated url' do
    expect(get_replies make_message(bot, 'asdf')).to have_exactly(0).items
  end

  it 'gives tweet data for a twitter url' do
    replies = get_replies make_message(bot,
                                       'https://twitter.com/AUser/status/43212344123',
                                       channel: 'a')
    expect(replies).to have_exactly(1).items
    expect(replies.first.event).to eq :message
    expect(replies.first.text).to eq '@AUser: asdf'
  end
end
