require 'rest-client'
require 'json'
require 'colorize'
require 'optparse'
require 'tty-spinner'
require 'terrapin'
require 'pty'

class EvalGPT
  
  SUPPORTED_LANGUAGES = ['ruby', 'javascript', 'python', 'swift', 'bash']
  SUPPORTED_EXTENSIONS = ['rb', 'js', 'py', 'swift', 'sh']
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
    @spinner = TTY::Spinner.new("[:spinner] Waiting for API response ...", format: :pulse_2)
    @model = select_model
  end

  def chat
    loop do
      print 'User: '.colorize(:blue)
      user_message = gets.chomp
      break if user_message.downcase == 'exit'
      language = detect_language(user_message)
      @messages << {
        'role' => 'user',
        'content' => user_message
      }
      @spinner.auto_spin
      response = call_chatgpt
      @spinner.stop('')
      puts response&.colorize(:gray) if @verbose
      code_response = extract_code(response)
      if code_response
        puts ""
        puts code_response&.colorize(:green)
        puts ""
        print "Do you want to evaluate this code? (yes/no): ".colorize(:white)
        if gets.chomp.downcase == 'yes'
          begin
            # eval_result = eval(code_response)
            eval_result = execute_code(code_response, language)
            puts "#{eval_result}"&.colorize(:yellow)
          rescue Exception => e
            puts "An error occurred while evaluating the code: #{e}".colorize(:red)
          end
        end
      end
    end
  end

  def write_code(code, language)
    timestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    ext = SUPPORTED_EXTENSIONS[SUPPORTED_LANGUAGES.index(language)]
    filename = "#{language}_#{timestamp}.#{ext}"

    File.open( "output/#{filename}", "w") do |file|
      file.write(code)
    end
    puts "Code written to #{filename}"
    "#{Dir.pwd}/output/#{filename}"
  end

  def execute_code(code, language)
    location = write_code(code, language)
    lang = Terrapin::CommandLine.new("which", language == 'javascript' ? 'node' : language)
    lang = lang.run
    puts "File saved to: #{location}"
    case language
    when 'ruby'
      eval(code)
    when 'python', 'swift', 'javascript', 'bash'

      PTY.spawn("#{language == 'javascript' ? 'node' : language}", location) do |stdout, stdin, pid|
      begin
        # Create a separate thread to handle user input
        input_thread = Thread.new do
          begin
            while line = $stdin.gets
              stdin.puts(line)
            end
          rescue Errno::EIO
            # End of input reached
          end
        end
    
        # Print output from the script
        stdout.each { |line| print line }
    
        # Wait for the input thread to finish before exiting the PTY block
        input_thread.join
      rescue Errno::EIO
        # End of input reached
      end
    end
    else
      raise "Unsupported language: #{language}"
    end
  end

  private

  def detect_language(message)
    SUPPORTED_LANGUAGES.find { |lang| message.downcase.include?(lang) }
  end

  def print_two_columns(items)
    items.each_slice(2).with_index(1) do |(item1, item2), index|
      puts "#{items.index(item1)}.#{item1}\t\t\t\t\t\t#{items.index(item2)}.#{item2}"
    end
  end
  
  def clear_screen
    puts "\e[H\e[2J"
  end
  
  def extract_code(response)
    response[/```.*?\n(.+)\n```/m, 1]
  end  

  def select_model
    models = get_models
    puts "Available models:".colorize(:white)
    filtered = models.select { |model| model.include?('gpt') || model.include?('davinci') }
    filtered.each_with_index do |model, index|
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
      'max_tokens' => ENV['MAX_TOKENS']&.to_i,
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
