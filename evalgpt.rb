require 'rest-client'
require 'json'
require 'colorize'
require 'optparse'
require 'tty-spinner'
require 'terrapin'
require 'pty'

class EvalGPT
  
  SUPPORTED_LANGUAGES = ['ruby', 'javascript', 'python', 'swift', 'bash', 'node']
  SUPPORTED_EXTENSIONS = ['rb', 'js', 'py', 'swift', 'sh', 'js']
  API_URL = 'https://api.openai.com/v1/chat/completions'

  def initialize(api_key, verbose)
    @selected_model = 'davinci-search-query'
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
    @spinner = TTY::Spinner.new("[:spinner] Prompting #{@selected_model}@OpenAI", format: :spin)
    @model = select_model
  end

  def chat
    help
    loop do
      print 'User: '.colorize(:blue)
      user_message = gets.to_s.chomp
      break if user_message.downcase == 'exit'
      if user_message.downcase == 'select_model'
        select_model
        chat
        break
      end
      if user_message.downcase == 'help'
        clear_screen
        help
        chat
        break
      end
      language = detect_language(user_message)
      @messages << {
        'role' => 'user',
        'content' => user_message
      }
      @spinner.auto_spin
      response = call_chatgpt
      @spinner.stop('[response parsed]')

      if @verbose
        puts ""
        puts response&.colorize(:gray) 
        puts ""
      end
      
      code_response = extract_code(response)
      if code_response
        puts ""
        puts "Language detected: ".colorize(:white) + language&.colorize(:pink)
        puts ""
        puts code_response&.colorize(:green)
        puts ""
        print "Evaluate code with (#{SUPPORTED_LANGUAGES.join('/')}/no): ".colorize(:white)
        evaluate = gets.chomp.downcase
        if evaluate != 'no'
          new_language = evaluate != 'yes' ? evaluate : language
          begin
            eval_result = execute_code(code_response, new_language)
            puts "#{eval_result}"&.colorize(:yellow)
          rescue Exception => e
            puts "An error occurred while evaluating the code: #{e}".colorize(:red)
          end
        end
      end
    end
  end

  def write_code(code, language)
    create_directory_if_not_exists('output')
    timestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    ext = SUPPORTED_EXTENSIONS[SUPPORTED_LANGUAGES.index(language)]
    filename = "#{language}_#{timestamp}.#{ext}"

    File.open( "output/#{filename}", "w") do |file|
      file.write(code)
    end
    "#{Dir.pwd}/output/#{filename}"
  end

  def execute_code(code, language)
    location = write_code(code, language)
    lang = Terrapin::CommandLine.new("which", language == 'javascript' ? 'node' : language)
    lang = lang.run
    puts ""
    puts "File saved to: ".colorize(:white) + location.colorize(:red)
    puts ""
    case language
    when 'ruby'
      eval(code)
    when 'python', 'swift', 'javascript', 'bash', 'node'
      $stdin.sync = true
      PTY.spawn("#{language == 'javascript' ? 'node' : language}", "#{location}") do |stdout, stdin, pid|
      input_thread = Thread.new do
        begin
          while line = $stdin.gets
            stdin.puts(line)
          end
        rescue Errno::EIO

        end
      end

      stdout.each do |line|
        print line
        $stdout.flush
      end

      input_thread.join
    end

    else
      raise "Unsupported language: #{language}"
    end
  end

  def help
    ascii = """
███████ ██    ██  █████  ██       ██████  ██████  ████████ 
██      ██    ██ ██   ██ ██      ██       ██   ██    ██    
█████   ██    ██ ███████ ██      ██   ███ ██████     ██    
██       ██  ██  ██   ██ ██      ██    ██ ██         ██    
███████   ████   ██   ██ ███████  ██████  ██         ██ 
    """
    puts ascii.colorize(:pink)
    puts "Options:"
    puts ""
    puts "1. Type a prompt for #{@selected_model} mentioning language to use `ex: write a ruby program that..`"
    puts "2. Type `select_model` to select a different model"
    puts "3. Type `help` to show this message"
    puts "4. Type `exit` to exit"
    puts ""
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

  def create_directory_if_not_exists(relative_path)
    absolute_path = File.expand_path(relative_path)
    unless Dir.exist?(absolute_path)
      Dir.mkdir(absolute_path)
    end
  end
  

  def select_model
    models = get_models
    puts ""
    puts "Available models:".colorize(:white)
    puts ""
    #filtered = models.select { |model| @verbose ? true :  model.include?('davinci-search-query')}
    models.each_with_index do |model, index|
      puts "#{index}. #{model}".colorize(:green)
    end
    puts ""
    print "Enter the number of the model you want to use: ".colorize(:white)
    chosen_model = gets.chomp.to_i - 1
    clear_screen
    @selected_model = models[chosen_model]
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
  opts.banner = "Usage: evalgpt.rb [options]"

  opts.on('-v', '--verbose', 'Run in verbose mode') do |v|
    options[:verbose] = v
  end
end.parse!

EvalGPT.new(ENV['GPT_API_KEY'], options[:verbose]).chat
