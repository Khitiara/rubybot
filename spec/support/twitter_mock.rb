require 'twitter'

# Mock twitter service
module Twitter
  class MockUser
    attr_accessor :screen_name

    def initialize(name)
      @screen_name = name
    end
  end

  class MockTweet
    attr_accessor :full_text, :user

    def initialize(text, user)
      @user = MockUser.new user
      @full_text = text
    end
  end

  module REST
    class Client
      def initialize
      end

      def status(_uri)
        MockTweet.new 'asdf', 'AUser'
      end
    end
  end
end
