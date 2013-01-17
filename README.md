

## Sauce
A Ruby Gem that's objective is to make installing and deploying lots applications easy.

Sauce is just a wrapper for Capistrano.

It allows you to define your applications and environments in a concise way, within *.sauce* files.

Capistrano does all the heavy lifting.

Executables installed:
* saucify
* sauce


## Dependencies
* [Ruby &#8805; 1.8.7](http://www.ruby-lang.org/en/downloads/)
* [Capistrano](https://github.com/capistrano/capistrano)

## Installation
```sh
  git clone https://github.com/sixjameses/sauce.git
  cd sauce
  gem install sauce-0.1.1.gem
```
## Usage

### saucify

Saucify you application.

```sh
  cd yourApp
  saucify yourApp
```

This simply creates a *yourApp.sauce* file in the current directory.

Nothing is done if *yourApp.sauce* already exists

Now get brewing!  That is, open *yourApp.sauce* and define your application and its environments

### sauce
This command really just masquerades as Capistrano's **cap** command.

It creates tasks based on the *.sauce* files it finds beneath the current directory. It will search 2 levels below the current directory.

**View available applications and environments**
```sh
  sauce -T
```

**View all available applications and their environment details (server definitions)**
```sh
  sauce list
```

**View available tasks for a given application and environment**
```sh
  sauce -T yourApp:env
```

**Execute task for a given application and environment**
```sh
  sauce yourApp:env:someTask
```


## Configuration (.sauce)
Configuring your application and environments is as easy as modifying your *.sauce* file(s) with Capistrano settings and task definitions.

**Example:**
```rb
  Sauce.brew("yourApp") do |app|
    app.load do
      # Recipes
      load("some/cool/deployment/recipe")
      load("another/cool/recipe")
      # put your application specific Capistrano configuration and task definitions here
    end
    app.environment("env1") do |env|
      env.load do 
        # put environment specific Capistrano configuration and task definitions here
      end
    end
    app.environment("env2") do |env|
      # ... and so on and so forth
    end
  end
```


You can *.load()*, define and redefine, an Application as much as you want.  
So you can create multiple *.sauce* files for a single application:environment, and
you could also define several applications inside a single *.sauce* file.

The name of your *.sauce* file is not important.

View some example *.sauce* configurations [here](sauce/tree/master/examples).

For more information on configuring Capistrano, see:
* https://github.com/capistrano/capistrano/wiki/2.x-Significant-Configuration-Variables
* https://github.com/capistrano/capistrano/wiki/2.x-DSL-Documentation-Configuration-Module

## Recipes
Sauce provides some recipes for your deployment needs!

Check them out [here](sauce/tree/master/lib/sauce/recipes).

### grails_deploy.tasks.rb
A new standard Grails deployment recipe...
