# evalgpt

> Ruby OpenAI client capable of evalutating ruby code generated from prompt responses

## Language Support

* Languages in the table have varying support for writing & running code generated from prompts.
* Note that the language support depends on the language being installed locally and in the users `$PATH`

| Language  | Write Generated Code | Execute Generated Code |
|---| --- | --- |
| Ruby  | ✅ |  ✅ |
| Swift  | ✅ |  ✅ |
| Javascript  |  ✅ | ❌|
| Python  |  ✅ | ❌|
| Bash  | ✅ |  ✅ |
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

## Usage

```
source .env
./evalgpt.rb
```

* You'll be prompted to select a model by number (gpt variants work best)

* Only code responses are displayed by default. If you aren't seeing responses use `--verbose` flag to debug and see what the api is responding with

* When a ruby code response is detected you'll be prompted if you want to evaluate it

* If your responses are being cut off, you can increase the `max_tokens` in the `.env` file

### Example

![Example](https://github.com/philipbroadway/evalgpt/blob/main/example.png)