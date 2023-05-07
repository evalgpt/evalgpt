> Ruby OpenAI client with support for generating code from prompts and running the generated code

## Dependancies

* [OpenAI API key](https://platform.openai.com/account/api-keys)
* [Ruby 3+](https://www.ruby-lang.org/en/) (run locally w/out docker)
* [Docker](https://www.docker.com/products/docker-desktop) (run locally/remote w/ docker)

## How It Works

* You'll be prompted to select a model by number (`davinci-search-query` works best currently)

* Write a prompt using a language flag (e.g. `Write a ruby game of tic-tac-toe`, `Write a bash script to print the current date & hostname`, `Write a swift program that asks for 2 numbers and returns gcd`)

* Only code responses are displayed by default. If you aren't seeing responses use `--verbose` flag to debug and see what the api is responding with

* When a code response is detected you'll be prompted if you want to evaluate it (TODO: better support for switching detected language)

* If your responses are being cut off, you can increase the `max_tokens` in the `.env` file (see [model token limits](https://platform.openai.com/docs/guides/rate-limits/what-are-the-rate-limits-for-our-api) for more info)

## Language Support

* Languages in the table have varying support for writing & running code generated from prompts.
* Note that the language support depends on the language being installed locally and in the users `$PATH`
* Edit [Dockerfile](https://github.com/philipbroadway/evalgpt/blob/main/Dockerfile#L8) to install specific languages and also update [evalgpt.rb](https://github.com/philipbroadway/evalgpt/blob/main/evalgpt.rb#L11)

| Language  | Write Generated Code | Execute Generated Code |
|---| --- | --- |
| Ruby  | ✅ |  ✅ |
| Swift  | ✅ |  ✅ |
| Bash  | ✅ |  ✅ |
| Node/Javascript  |  ✅ | ✅
| Python  |  ✅ | ✅

## Initialization

```
mkdir output

cp .env.example .env # Add your openai api key to the .env file

```

## Docker Startup

See comments in [Dockerfile](https://github.com/philipbroadway/evalgpt/blob/main/Dockerfile#L8) for info on configuring which languages are installed

```
git clone git@github.com:philipbroadway/evalgpt.git && cd evalgpt
docker build -t evalgpt . && docker run -it evalgpt
```

## Local Startup

* Ruby 3+ installed locally in $PATH
* To generate and eval code in other languages locally the language must be installed locally in $PATH
```

bundle install

source .env
ruby evalgpt.rb
```

## Known Issues

* Some language interpreters behave differently launching code and running code output may be duplicated or missing. If you eval code and expect a prompt to be shown assume its being shown and enter a value. Investigating way to consistently handle tty io.


## Examples

## Model Selection

![model-selection](https://github.com/philipbroadway/evalgpt/blob/main/example1.png)

## Generating code via prompt & running code

** Prompts can take a long time to finish - be patient or use ctrl+c to exit & return to prompt
![prompt](https://github.com/philipbroadway/evalgpt/blob/57aba855b2cd53c651319e92fd4c5643e88a20e9/prompt.png)
