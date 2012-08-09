require 'game'

module Dominion

  def self.all_cards
    @all_cards ||= []
  end
  
  def self.all_defined_cards
    all_cards.select {|card| card.defined? }
  end
  
  def self.all_defined_kingdom_cards
    all_defined_cards.select {|card| card.kingdom? }
  end
  
  class Card
    # Game context used for cards when unassociated with a context
    BASE_CONTEXT = Game.new :no_prepare => true
    
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
          @coins = 0
          @buys = 0
          @vp = 0
        end
        
        Dominion.all_cards << subclass
      end

      define_type_attrs :base, :action, :attack, :victory, :treasure, :curse, :reaction, :duration
      define_class_attrs :set, :cost, :potion, :cards, :actions, :coins, :buys, :vp

      public

      def type(*args)
        @type = args if args.length >= 1
        @type
      end
      
      def to_s
        (name.split '::').last
      end
      
      def defined?
        !@type.empty?
      end
      
      def kingdom?
        not base?
      end
    end
    
    def initialize(game = nil, player = nil)
      @game = game || Card::BASE_CONTEXT
      @player = player
    end
    
    attr_reader :game
    attr_accessor :player

    # Hooks - empty by default
    def on_play; yield if block_given?; end                 # Lots...
    def on_buy; yield if block_given?; end                  # Mint, Farmland, Noble Brigand
    def on_gain; yield if block_given?; end                 # Cache, Border Village, Embassy, Duchy/Duchess, Ill-Gotten Gains, Inn, Mandarin, Nomad Camp
    def on_discard; yield if block_given?; end              # Tunnel
    def on_trash; yield if block_given?; end                # Dark Ages!!!
    def on_any_card_bought; yield if block_given?; end      # Contraband (validation)
    def on_any_card_gained; yield if block_given?; end      # Watchtower, Trader, Fool's Gold
    def on_setup_after_duration; yield if block_given?; end # Wharf, Tactician, Merchant Ship, Lighthouse, Haven, Fishing Village, Caravan

    # can be overridden in various cards, like Grand Market
    def can_buy
      true
    end
    
    # type is an alias for class, defined by object, so method_missing won't get called
    def type
      self.class.type
    end

    def method_missing(method, *args, &block)
      if self.class.respond_to? method
        self.class.send method, *args, &block
      elsif @player
        @player.send method, *args, &block
      else
        @game.send method, *args, &block
      end
    end
    
    def to_s
      self.class.to_s
    end

  end
end
