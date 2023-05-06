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

You'll be prompted to select a model by number

Only code responses are displayed by default. To see the prompt and response, pass the `--verbose` flag

When a ruby code response is detected you'll be prompted if you want to evaluate it

### Example

![Example](https://github.com/philipbroadway/evalgpt/blob/main/example.png)