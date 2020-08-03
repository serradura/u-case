# μ-case - Calculator example

This example uses [rake](http://rubygems.org/gems/rake) to expose a CLI calculator.

## Installation instructions
```sh
gem install rake
gem install u-case -v 3.0.0.rc4
```

*Note:*

If zsh is your shell, use: [`unsetopt nomatch`](https://thoughtbot.com/blog/how-to-use-arguments-in-a-rake-task) to avoid errors when invoking rake tasks with arguments.

### Usage

![gif](https://github.com/serradura/u-case/blob/master/examples/calculator/assets/usage.gif?raw=true)

#### Listing the available rake tasks
```sh
rake -T

# rake calc:add[a,b]       # adds two numbers
# rake calc:divide[a,b]    # divides two numbers
# rake calc:multiply[a,b]  # multiplies two numbers
# rake calc:subtract[a,b]  # subtracts two numbers
```

#### Calculating integer numbers
```sh
bundle exec rake calc:add[3,2]
# 3 + 2 = 5

bundle exec rake calc:subtract[3,2]
# 3 - 2 = 1

bundle exec rake calc:multiply[3,2]
# 3 x 2 = 6

bundle exec rake calc:divide[3,2]
# 3 / 2 = 1
```

#### Calculating float numbers
```sh
bundle exec rake calc:divide[3.0,2.0]
# 3.0 / 2.0 = 1.5

bundle exec rake calc:divide[-3.0,2.0]
# -3.0 / 2.0 = -1.5
```

#### Calculation errors
```sh
bundle exec rake calc:divide[4,0]
# ERROR: divided by 0

bundle exec rake calc:add[1,a]
# ERROR: The arguments must contain only numeric values

bundle exec rake calc:add[-\ 1,2]
# ERROR: Arguments can't have spaces: a: "- 1", b: "2"
```
