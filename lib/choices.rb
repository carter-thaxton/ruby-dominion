module Dominion
  module Choices
    attr_reader :choice_in_progress

    def ask(message, options = {})
      options[:message] = message
      options[:type] = :bool
      options[:multiple] = false
      choose(options)
    end
    
    def choose_card(message, options = {})
      options[:message] = message
      options[:type] = :card
      options[:multiple] = false
      choose(options)
    end
    
    def choose_cards(message, options = {})
      options[:message] = message
      options[:type] = :card
      options[:multiple] = true
      choose(options)
    end

    def choose_one(messages, symbols, options = {})
      if symbols.count > 1
        options[:message] = 'Choose one: ' + messages.join(' or ')
        options[:messages] = messages
        options[:type] = :symbol
        options[:multiple] = false
        options[:restrict_to] = symbols
        options[:required] = true
        choose(options)
      else
        # Don't bother asking for zero or one choices
        symbols.first
      end
    end

    def choose_two(messages, symbols, options = {})
      options[:message] = 'Choose two: ' + messages.join(' or ')
      options[:messages] = messages
      options[:type] = :symbol
      options[:multiple] = true
      options[:restrict_to] = symbols
      options[:unique] = true
      options[:count] = 2
      choose(options)
    end

    def choose(options = {})
      options[:player] = self
      options[:card] = @card_in_play
      @choice_in_progress = options

      # use choice if given directly in call to play
      # otherwise defer to strategy if available
      response = if @play_choice
        handle_response(@play_choice)
      elsif @strategy
        handle_response(@strategy.choose(options))
      else
        nil
      end

      @choice_in_progress = nil
      response
    end

    private

    def handle_response(response)
      raise "Cannot handle response unless waiting for choice" unless @choice_in_progress

      multiple = @choice_in_progress[:multiple]
      type = @choice_in_progress[:type]
      from = @choice_in_progress[:from]
      max = @choice_in_progress[:max]
      min = @choice_in_progress[:min]
      count = @choice_in_progress[:count]
      restrict_to = @choice_in_progress[:restrict_to]
      unique = @choice_in_progress[:unique]
      max_cost = @choice_in_progress[:max_cost]
      min_cost = @choice_in_progress[:min_cost]
      cost = @choice_in_progress[:cost]
      card_type = @choice_in_progress[:card_type]

      if count
        min = max = count
      end

      if cost
        max_cost = min_cost = cost
      end

      if multiple
        response = [response] unless response.is_a? Enumerable
      end
      
      # common operation of finding cards in hand by type
      if type == :card
        if from == :hand
          if multiple
            response = find_cards_in_hand(response)
          else
            response = find_card_in_hand(response)
          end
        elsif from == :supply
          raise "Cannot choose multiple cards from supply" if multiple
          response = peek_from_supply(response)
        else
          raise "Cards must be chosen from hand or supply"
        end
      end

      if type == :bool
        if multiple
          response.each do |r|
            raise "Response must be an array of true or false values" unless r == true or r == false
          end
        else
          raise "Response must be true or false" unless response == true or response == false
        end
      end

      if restrict_to
        if multiple
          response.each do |r|
            raise "Response must be an array of one of: " + restrict_to.to_s unless restrict_to.include?(r)
          end
        elsif type == :card
          raise "Response must be one of: " + restrict_to.to_s unless restrict_to.include?(response.card_class)
        else
          raise "Response must be one of: " + restrict_to.to_s unless restrict_to.include?(response)
        end
      end

      if type == :card && response
        if max_cost
          raise "Card must cost no more than #{max_cost}, but #{response} costs #{response.cost}" if response.cost > max_cost
        end

        if min_cost
          raise "Card must cost no less than #{min_cost}, but #{response} costs #{response.cost}" if response.cost < min_cost
        end

        if card_type
          raise "Card must have type #{card_type}, but #{response} has type #{response.type}" unless response.type.include?(card_type)
        end
      end

      if multiple
        if max
          raise "At most #{max} may be chosen" if response.size > max
        end

        if min
          raise "At least #{min} must be chosen" if response.size < min
        end

        if unique
          raise "Choices must be unique" if response.uniq != response
        end

        if type == :card
          response = response.select {|card| card}  # filter out any nulls
        end
      end

      response
    end

  end
end
