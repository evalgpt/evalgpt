require 'rest-client'
require 'json'
require 'colorize'
require 'optparse'
require 'tty-spinner'
require 'terrapin'
require 'pty'
require 'excon'

# MODEL='gpt-3.5-turbo-0301'
MODEL = 'gpt-3.5-turbo'
# MODEL='gpt-4'
API_URL = 'https://api.openai.com/v1/chat/completions'
class EvalGPT
  SUPPORTED_LANGUAGES = %w[text ruby javascript python swift bash node]
  SUPPORTED_EXTENSIONS = %w[txt rb js py swift sh js]

  def initialize(api_key, verbose, input = nil, output_folder = nil, commit = false)
    @selected_model = MODEL
    @api_key = api_key
    @verbose = verbose
    @commit = commit
    @headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    }
    @messages = [
      {
        'role' => 'system',
        'content' => 'You are a helpful programming assistant. Solve the problems with only code responses in the format the user requests. Do not comment code. If you cannot solve the problem, respond with "I cannot solve this problem".'
        # 'content' => 'You are a helpful programming assistant, complete each task responding with complete code that accomplishes each task. Only respond with code. Do not comment code.'
      }
    ]
    @in = input
    @out = output_folder

    @spinner = TTY::Spinner.new("[:spinner] Prompting #{@selected_model}@OpenAI", format: :spin)
    @model = MODEL
  end

  def chat

    if @commit
      commit_to_pull_request([], Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
    end

    if @in && @out
      input = ''
      puts "\[prommpt] ".colorize(:green) + @in.colorize(:red) + ":\n"
      puts '```'
      open @in do |f|
        f.each_line do |line|
          input = "#{input}#{line}"
          puts "#{line}"
        end
      end
      puts '```'
      @messages << {
        'role' => 'user',
        'content' => 'Always respond with text format that indates path if relevant, filename (markdown bold) a new line then content for the file(s) the user will create. Ex: **file_1**\n```\n content\n```  **file_2**\n```\n content\n``` ' + input
      }

      puts "\n"

      puts "\n"
      response = stream_chatgpt
      # response = call_chatgpt
      @spinner.stop('[response parsed]')
      puts ''
      puts response
      puts ''
      response = extract_code(response)
      # puts "\n\extract_code: #{response}\n\n"
      locations = []
      if response
        response.each do |k|
          puts k
          key = k[0]
          v = k[1]
          detected = detect_language(v) || 'text'
          # puts "k: #{key} v:#{v}"
          write_code(v, detected, key)
          locations.push(key)
        end
      else
        puts 'No code response found'
      end
      commit_to_pull_request(locations, Time.now.strftime('%Y-%m-%d_%H-%M-%S')) unless !@commit
    end
    return if @in && @out || @commit
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
      # @spinner.auto_spin
      response = stream_chatgpt
      @spinner.stop("[response]: #{response}")

      if @verbose
        puts ''
        puts response&.colorize(:gray)
        puts ''
      end

      code_response = response # extract_code(response)
      next unless code_response

      puts ''
      puts 'Language detected: '.colorize(:white) + language&.colorize(:pink)
      puts ''
      puts code_response&.colorize(:green)
      puts ''
      print "Evaluate code with (#{SUPPORTED_LANGUAGES.join('/')}/no): ".colorize(:white)
      evaluate = gets.chomp.downcase
      next unless evaluate != 'no'

      new_language = evaluate != 'yes' ? evaluate : language
      begin
        eval_result = execute_code(code_response, new_language)
        puts "#{eval_result}"&.colorize(:yellow)
      rescue Exception => e
        puts "An error occurred while evaluating the code: #{e}".colorize(:red)
      end
    end
  end

  def commit_to_pull_request(_files, now)
    name = now
    token = ENV['GH_ACCESS_TOKEN']
    repo_user =  ENV['GH_REPO'].split('/')[0].split(':')[1]
    repo_name =  ENV['GH_REPO'].split('/')[1].split('.')[0]   
    repo = "#{repo_user}/#{repo_name}"
    `echo "Completed @#{now}\n$(cat #{@in})" > #{@in}` #
    output_folder = File.absolute_path("output")
    input_file = File.absolute_path(@in)
    Dir.mktmpdir do |d|
      Dir.chdir d do
        `git clone https://#{repo_user}:#{token}@github.com/#{repo} repo`
        Dir.chdir 'repo' do
        `git checkout -b #{name}`
        `cp -r #{output_folder}/* .`
        `git add .`
        `git commit --file "#{input_file}"`
        `git push origin #{name}`
        end
      end
    end
  end

  def write_code(code, language, filename = nil)
    # puts "write_code: language: #{language} filename: #{filename}"
    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    ext = SUPPORTED_EXTENSIONS[SUPPORTED_LANGUAGES.index(language)]
    filename ||= "#{language}_#{timestamp}_#{Time.now.to_i}.#{ext}"
    # puts "ext: #{ext} filename: #{filename}"
    if @out
      full_path = File.join(@out, filename)
      dir = File.dirname(full_path)
      create_directory_if_not_exists(@out)
      FileUtils.mkdir_p(@out) unless File.directory?(@out)
      paths = full_path.split('/')
      paths.pop
      paths = paths.join('/')
      FileUtils.mkdir_p(paths) if paths && !File.directory?(paths)
      # puts ":write: #{full_path}"
      File.open(full_path, 'w') do |file|
        file.write(code)
      end
      full_path
    else
      create_directory_if_not_exists('output')
      File.open("output/#{filename}", 'w') do |file|
        file.write(code)
        return "#{Dir.pwd}/output/#{filename}"
      end
    end
  end

  def execute_code(code, language)
    location = write_code(code, language)
    lang = Terrapin::CommandLine.new('which', language == 'javascript' ? 'node' : language)
    lang = lang.run
    puts ''
    puts 'File saved to: '.colorize(:white) + location.colorize(:red)
    puts ''
    case language
    when 'ruby'
      eval(code)
    when 'python', 'swift', 'javascript', 'bash', 'node'
      $stdin.sync = true
      PTY.spawn("#{language == 'javascript' ? 'node' : language}", "#{location}") do |stdout, stdin, _pid|
        input_thread = Thread.new do
          while line = $stdin.gets
            stdin.puts(line)
          end
        rescue Errno::EIO
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
    ascii = ''"
███████ ██    ██  █████  ██       ██████  ██████  ████████ 
██      ██    ██ ██   ██ ██      ██       ██   ██    ██    
█████   ██    ██ ███████ ██      ██   ███ ██████     ██ 
██       ██  ██  ██   ██ ██      ██    ██ ██         ██ 
███████   ████   ██   ██ ███████  ██████  ██         ██ 
    "''
    puts ascii.colorize(:green)
    puts 'Options:'
    puts ''
    puts "1. Type a prompt for #{@selected_model} mentioning language to use `ex: write a ruby program that..`"
    puts '2. Type `help` to show this message'
    puts '3. Type `exit` to exit'
    puts ''
  end

  private

  def detect_language(message)
    message = message&.strip
    if message&.start_with?('#!')
      return 'bash' if message&.include?('bash') || message&.include?('sh')
      return 'python' if message&.include?('python')
      return 'ruby' if message&.include?('ruby')
    end

    case message
    when /def .* end/ # Ruby function
      'ruby'
    when /class .* end/ # Ruby class
      'ruby'
    when /def .*:/ # Python function
      'python'
    when /class .*:/ # Python class
      'python'
    when /let .* =/ # Swift variable declaration
      'swift'
    when /func .* {/ # Swift function
      'swift'
    when /\$[A-Za-z0-9_]+/ # Bash variable
      'bash'
    when /echo .*/ # Bash echo command
      'bash'
    else
      'text'
    end
  end

  def print_two_columns(items)
    items.each_slice(2).with_index(1) do |(item1, item2), _index|
      puts "#{items.index(item1)}.#{item1}\t\t\t\t\t\t#{items.index(item2)}.#{item2}"
    end
  end

  def clear_screen
    puts "\e[H\e[2J"
  end

  def extract_code(response)
    matches = response.scan(/(\*\*(.*?)\*\*)\n```.*?\n?([\s\S]*?)\n```/m)
    files = {}
    # puts "matches: #{matches}"

    matches.each do |match|
      files[match[1]] = match[2].strip
    end

    # puts "files: #{files}"
    files
  end

  def create_directory_if_not_exists(relative_path)
    absolute_path = File.expand_path(relative_path)
    # puts "absolute_path: #{absolute_path}"
    FileUtils.mkdir_p(absolute_path) unless File.directory?(absolute_path)
  end

  def select_model
    models = get_models
    clear_screen
    @selected_model = MODEL
  end

  def get_models
    response = RestClient.get('https://api.openai.com/v1/models', @headers)
    parsed_response = JSON.parse(response)
    parsed_response = parsed_response['data']

    parsed_response.map { |model| model['id'] }
  rescue RestClient::ExceptionWithResponse => e
    e.response
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
      puts "\n\n[RESPONSE] #{response}\n".colorize(:green)
      parsed_response['choices'].first['message']['content']
    rescue RestClient::ExceptionWithResponse => e
      e.response
      puts 'Error:' + " #{e.response}"
    end
  end

  def stream_chatgpt
    data = {
      'max_tokens' => ENV['MAX_TOKENS']&.to_i,
      'temperature' => 0.7,
      'model' => @model,
      'messages' => @messages,
      'stream' => true
    }
    result = '**'
    response = Excon.post(
      API_URL,
      body: data.to_json,
      headers: @headers.merge('Content-Type' => 'application/json'),
      response_block: lambda { |chunk, _remaining_bytes, _total_bytes|
        parsed_chunk = begin
          JSON.parse(chunk.gsub('data: ', ''))
        rescue StandardError
          nil
        end
        if parsed_chunk&.key?('choices')
          result = "#{result}#{parsed_chunk['choices'].first['delta']['content']}"
          clear_screen
          puts result
        end
      }
    )

    puts "Error: #{response.status} #{response.body}" if response.status != 200
    result
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
end
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: evalgpt.rb [options]'

  opts.on('-i', '--input INPUT', 'Input to send to prompt') do |i|
    options[:input] = i
  end
  opts.on('-o', '--output OUTPUT', 'Output folder') do |o|
    options[:output] = o
  end
  opts.on('-v', '--verbose', 'Run in verbose mode') do |v|
    options[:verbose] = v
  end

  opts.on('-c', '--commit', 'create a feature branch with the output folder contents') do |c|
    options[:commit] = true
  end
end.parse!

api_key = ENV['GPT_API_KEY'] || 'Your API Key here'
verbose = options[:verbose] || false
input = options[:input] || nil
output = options[:output] || nil
commit = options[:commit] || nil

EvalGPT.new(api_key, verbose, input, output, commit).chat
