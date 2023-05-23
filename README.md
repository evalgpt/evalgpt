## What You Need

* [OpenAI API key](https://platform.openai.com/account/api-keys)
* [Ruby 3+](https://www.ruby-lang.org/en/) or [Docker](https://www.docker.com/products/docker-desktop)

## How It Works

* ~~You'll be prompted to select a model by number (`davinci-search-query` works best currently)~~ [gpt-3-turbo branch](https://github.com/evalgpt/evalgpt/tree/gpt3-turbo) should be used

* Write a prompt using a language flag (e.g. `Write a ruby game of tic-tac-toe`, `Write a bash script to print the current date & hostname`, `Write a swift program that asks for 2 numbers and returns gcd`)

* Only code responses are displayed by default. `--verbose` flag displays entire api response

* Code responses will trigger a prompt to type a language to evaluate with (or type no to skip & return to prompt)

* If your responses are being cut off, you can increase the `max_tokens` in the `.env` file (see [model token limits](https://platform.openai.com/docs/guides/rate-limits/what-are-the-rate-limits-for-our-api) for more info)

## Languages It Supports

* Languages in the table have varying support for writing & running code generated from prompts.
* Note that the language support depends on the language being installed locally and in the users `$PATH`
* Edit [Dockerfile](https://github.com/philipbroadway/evalgpt/blob/main/Dockerfile#L8) see also: [evalgpt.rb](https://github.com/philipbroadway/evalgpt/blob/main/evalgpt.rb#L11)

| Language  | Write Generated Code | Execute Generated Code |
|---| --- | --- |
| Ruby  | ✅ |  ✅ |
| Swift  | ✅ |  ✅ |
| Bash  | ✅ |  ✅ |
| Node/Javascript  |  ✅ | ✅
| Python  |  ✅ | ✅

## Getting Started

```
mkdir output

cp examples/.env-example .env # Add your openai api key to the .env file

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

![model-selection](https://github.com/philipbroadway/evalgpt/blob/main/examples/example1.png)

## Generating code via prompt & running code

** Prompts can take a long time to finish - be patient or use ctrl+c to exit & return to prompt
![prompt](https://github.com/philipbroadway/evalgpt/blob/main/examples/prompt.png)


## Contributing

This is a weekend project for me & contributions are welcome!

Please see [contributing guide](https://github.com/evalgpt/evalgpt/blob/main/docs/CONTRIBUTING.md) for more details.
