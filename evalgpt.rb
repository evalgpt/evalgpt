require 'rest-client'
require 'json'
require 'colorize'
require 'optparse'

class EvalGPT
  API_URL = 'https://api.openai.com/v1/chat/completions'

  def initialize(api_key, verbose)
    @api_key = api_key
    @verbose = verbose
    @headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    }
    @messages = [
      {
        'role' => 'system',
        'content' => 'You are a senior engineering assistant.'
      }
    ]
    @model = select_model
  end

  def chat
    loop do
      print 'User: '.colorize(:blue)
      user_message = gets.chomp
      break if user_message.downcase == 'exit'
  
      @messages << {
        'role' => 'user',
        'content' => user_message
      }
  
      response = call_chatgpt
      puts response.colorize(:gray) if @verbose
      code_response = extract_code(response)
      if code_response
        puts ""
        puts code_response.colorize(:green)
        puts ""
        print "Do you want to evaluate this code? (yes/no): ".colorize(:white)
        if gets.chomp.downcase == 'yes'
          begin
            eval_result = eval(code_response)
            puts "#{eval_result}".colorize(:yellow)
          rescue Exception => e
            puts "An error occurred while evaluating the code: #{e}".colorize(:red)
          end
        end
      end
    end
  end

  private

  def clear_screen
    puts "\e[H\e[2J"
  end
  
  def extract_code(response)
    response[/```.*?\n(.+)\n```/m, 1]
  end  

  def select_model
    models = get_models
    puts "Available models:".colorize(:white)
    models.each_with_index do |model, index|
      puts "#{index + 1}. #{model}".colorize(:green)
    end
    print "Enter the number of the model you want to use: ".colorize(:white)
    chosen_model = gets.chomp.to_i - 1
    clear_screen
    models[chosen_model]
    
  end

  def get_models 
    begin
      response = RestClient.get('https://api.openai.com/v1/models', @headers)
      parsed_response = JSON.parse(response)
      parsed_response = parsed_response['data']
      parsed_response.map { |model| model['id'] }
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
  end

  def call_chatgpt
    data = {
      'max_tokens' => 150,
      'temperature' => 0.7,
      'model' => @model,
      'messages' => @messages
    }
  
    begin
      response = RestClient.post(API_URL, data.to_json, @headers)
      parsed_response = JSON.parse(response)
      parsed_response['choices'].first['message']['content']
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on('-v', '--verbose', 'Run in verbose mode') do |v|
    options[:verbose] = v
  end
end.parse!

EvalGPT.new(ENV['GPT_API_KEY'], options[:verbose]).chat
