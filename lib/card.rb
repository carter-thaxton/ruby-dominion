module Dominion

  def self.all_cards
    @all_cards ||= []
  end
  
  class Card
    # Define a DSL for cards
    class << self
      private
      
      def self.define_type_attrs(*attrs)
        attrs.each do |attr|
          method = attr.to_s + '?'
          send :define_method, method do
            @type.include? attr
          end
        end
      end
      
      def self.define_class_attrs(*attrs)
        attrs.each do |attr|
          send :define_method, attr do |*args|
            var = '@' + attr.to_s
            instance_variable_set var, args[0] if args.length >= 1
            instance_variable_get var
          end
        end
      end
    
      def inherited(subclass)
        subclass.instance_eval do
          @type = []
          @cost = 0
          @potion = false
          @cards = 0
          @actions = 0
          @buys = 0
          @coins = 0
          @vp = 0
          @vp_tokens = 0
        end
        
        Dominion.all_cards << subclass
      end

      define_type_attrs :base, :action, :attack, :victory, :treasure, :curse, :reaction, :duration
      define_class_attrs :cost, :potion, :cards, :actions, :buys, :coins, :vp, :vp_tokens

      public

      def type(*args)
        @type = args if args.length >= 1
        @type
      end
      
      def to_s
        (name.split '::').last
      end
      
      def kingdom?
        not base?
      end
    end
    
    def initialize(game = nil, player = nil)
      @game = game || Game::BASE_CONTEXT
      @player = player
    end
    
    attr_reader :game
    attr_accessor :player
    
    # type is an alias for class, defined by object, so method_missing won't get called
    def type
      self.class.type
    end

    def method_missing(method, *args)
      if self.class.respond_to? method
        self.class.send method, *args
      elsif @player
        @player.send method, *args
      else
        @game.send method, *args
      end
    end
    
    def to_s
      self.class.to_s
    end

  end
end
