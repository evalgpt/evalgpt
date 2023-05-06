# evalgpt

> A simple command line tool that connects to openai and can evaluate ruby/javascript/python/swift code responses

## Installation

```
bundle install

mkdir output

cp .env.example .env # Add your openai api key to the .env file

```

## Usage

```
source .env
./evalgpt.rb
```

* You'll be prompted to select a model by number (gpt variants work best)

* Only code responses are displayed by default. If you aren't seeing responses use `--verbose` flag to debug and see what the api is responding with

* When a ruby code response is detected you'll be prompted if you want to evaluate it

* If your responses are being cut off, you can increase the `max_tokens` in the `.env` file

* Ruby language is supported if language is installed locally

* Javascript language is supported if node is installed locally [experimental]

* Swift language is supported if swift is installed locally 

* Python language is supported if python is installed locally [experimental]

* Experimental languages are not fully supported and most likely will not run the generated code, the code will be saved in output folder for manual execution and you can use ctrl-c to exit running the program and return to prompt

### Example

![Example](https://github.com/philipbroadway/evalgpt/blob/main/example.png)