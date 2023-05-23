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

  def initialize(api_key, verbose, input = nil, output_folder = nil)
    @selected_model = 'gpt-3.5-turbo'
    @api_key = api_key
    @verbose = verbose
    @headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    }
    @messages = [
      {
        'role' => 'system',
        'content' => 'You are a helpful programming assistant, complete each task responding with complete code that accomplishes each task.'
      }
    ]
    @in = input
    @out = output_folder

    @spinner = TTY::Spinner.new("[:spinner] Prompting #{@selected_model}@OpenAI", format: :spin)
    @model = 'gpt-3.5-turbo'
  end

  def chat
    if @in && @out
    input = ""
      open @in do |f|
        f.each_line do |line|
          input = "#{input}#{line}"
          puts line
        end
      end
      @messages << {
        'role' => 'user',
        'content' => input
      }
      puts "\nPrompt: ".colorize(:green) + @in.colorize(:red)
      puts "\n"
      # puts "\nContent: ".colorize(:white) + @messages.join("\n").colorize(:green)
      @spinner.auto_spin
      puts "\n"
      response = call_chatgpt
      @spinner.stop('[response parsed]')
      puts ""
      puts response
      puts ""
      code_responses = extract_code(response)
      if code_responses
        code_responses.each_with_index do |code_response, index|
          write_code(code_response, 'ruby')
        end
      else
        puts "No code response found"
      end
      return
    end
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
      @spinner.stop("[response]: #{response}")

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
    timestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    ext = SUPPORTED_EXTENSIONS[SUPPORTED_LANGUAGES.index(language)]
    filename = "#{language}_#{timestamp}_#{Time.now.to_i}.#{ext}"

    if @out
      create_directory_if_not_exists(@out)
      full_path = File.join(@out, filename)
      File.open(full_path, "w") do |file|
        file.write(code)
      end
      return full_path
    else
      create_directory_if_not_exists('output')
      File.open( "output/#{filename}", "w") do |file|
        file.write(code)
        return "#{Dir.pwd}/output/#{filename}"
      end
    end
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
    puts "2. Type `help` to show this message"
    puts "3. Type `exit` to exit"
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
    return nil unless response
    # capture all code blocks in an array
    response.scan(/```.*?\n(.+?)\n```/m).flatten
  end

  def create_directory_if_not_exists(relative_path)
    absolute_path = File.expand_path(relative_path)
    unless Dir.exist?(absolute_path)
      Dir.mkdir(absolute_path)
    end
  end

  def select_model
    models = get_models
    clear_screen
    @selected_model =  'gpt-3.5-turbo'
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
    puts "\n#{data}\n".colorize(:yellow)
    begin
      response = RestClient.post(API_URL, data.to_json, @headers)
      parsed_response = JSON.parse(response)
      puts "\n[RESPONSE] #{response}\n".colorize(:green)
      parsed_response['choices'].first['message']['content']
    rescue RestClient::ExceptionWithResponse => e
      e.response
      puts "Error:" + " #{e.response}"
    end
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: evalgpt.rb [options]"
  
  opts.on('-i', '--input INPUT', 'Input to send to prompt') do |i|
    options[:input] = i
  end
  opts.on('-o', '--output OUTPUT', 'Output folder') do |o|
    options[:output] = o
  end  
  opts.on('-v', '--verbose', 'Run in verbose mode') do |v|
    options[:verbose] = v
  end
end.parse!

api_key = ENV['GPT_API_KEY'] || 'Your API Key here'
verbose = options[:verbose] || false
input = options[:input] || nil
output = options[:output] || nil

EvalGPT.new(api_key, verbose, input, output).chat