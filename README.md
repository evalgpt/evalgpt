```
███████ ██    ██  █████  ██       ██████  ██████  ████████ 
██      ██    ██ ██   ██ ██      ██       ██   ██    ██    
█████   ██    ██ ███████ ██      ██   ███ ██████     ██    
██       ██  ██  ██   ██ ██      ██    ██ ██         ██    
███████   ████   ██   ██ ███████  ██████  ██         ██    
```

> Ruby OpenAI client with support for executing code generated from prompts

## Language Support

* Languages in the table have varying support for writing & running code generated from prompts.
* Note that the language support depends on the language being installed locally and in the users `$PATH`

| Language  | Write Generated Code | Execute Generated Code |
|---| --- | --- |
| Ruby  | ✅ |  ✅ |
| Swift  | ✅ |  ✅ |
| Bash  | ✅ |  ✅ |
| Javascript  |  ✅ | ❌|
| Python  |  ✅ | ❌|
| Go  | ❓|  ❓ |
| Rust  | ❓ | ❓ |
| C  | ❓ | ❓ |
| C++  | ❓ | ❓ |
| Java  | ❓ | ❓ |

## Installation

```
bundle install

mkdir output

cp .env.example .env # Add your openai api key to the .env file

```

## Dockerfile

See comments in Dockerfile for info on configuring which languages are installed

```
docker build -t evalgpt . && docker run -it evalgpt
```

## Local Usage

* Assumes you have ruby installed locally in $PATH along with any languages you want to use

```
source .env
./evalgpt.rb
```

* You'll be prompted to select a model by number (`davinci-search-query` works best currently and some models don't support `/v1/chat/completions`)

* Write a prompt using a language flag (e.g. `Write a ruby game of tic-tac-toe`, `Write a bash script to print the current date`, `Write a swift program that asks for 2 numbers and returns gcd`)

* Only code responses are displayed by default. If you aren't seeing responses use `--verbose` flag to debug and see what the api is responding with

* When a code response is detected you'll be prompted if you want to evaluate it (TODO: better support for switching detected language)

* If your responses are being cut off, you can increase the `max_tokens` in the `.env` file (see [model token limits](https://platform.openai.com/docs/guides/rate-limits/what-are-the-rate-limits-for-our-api) for more info)

### Example

![Example](https://github.com/philipbroadway/evalgpt/blob/main/example.png)
