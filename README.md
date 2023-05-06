# evalgpt

> A simple command line tool that connects to openai and can evaluate ruby code responses

## Installation

```
bundle install
```

## Usage

```
./evalgpt.rb
```

* You'll be prompted to select a model by number (gpt variants work best)

* Only code responses are displayed by default. If you aren't seeing responses use `--verbose` flag to debug and see what the api is responding with

* When a ruby code response is detected you'll be prompted if you want to evaluate it

### Example

![Example](https://github.com/philipbroadway/evalgpt/blob/main/example.png)