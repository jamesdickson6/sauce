## Sauce
The goal of this is to make installing and deploying lots applications easy.

Sauce is just a wrapper for Capistrano.
It allows you to define your applications and environments in a concise way, within .sauce files.
Capistrano does all the heavy lifting.

Executables installed:
* saucify
* sauce


## Dependencies
* Ruby 1.8.7 or newer
* Capistrano
* HighLine

## Installation
```sh
  git clone https://github.com/sixjameses/sauce.git
  cd sauce
  gem install sauce-0.1.0.gem
```
## Usage

### saucify
**NOT IMPLEMENTED YET**

**Saucify you application**
```sh
  cd myCoolApp
  saucify myCoolApp
```
This creates a ''myCoolApp.sauce'' file in the current directory.
Now open this file and modify it to meet your deployment specific needs.

Nothing is done if '.sauce' already exists

Now configure your application's environment file(s), and add any extra tasks if you like.


### sauce
This command really just masquerades as **cap**, 
It creates tasks based on the *.sauce* files it finds beneath the current directory. It will search 3 levels deep.

## Recipes

### Grails
A new standard Grails app recipe...
