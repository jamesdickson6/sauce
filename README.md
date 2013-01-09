== Sauce
The goal of this is to make installing and deploying lots applications easy.

Sauce is just a wrapper for Capistrano.
It allows you to define your applications and environments in a concise way, within .sauce files.
Capistrano does all the heavy lifting.

Executables installed:
* saucify
* sauce


== Dependencies
* Ruby 1.8.7 or newer
* Capistrano
* HighLine

== Installation
  gem install sauce-0.1.0.gem

== Usage

=== saucify
;NOT IMPLEMENTED YET

;Saucify you application
  cd myCoolApp
  saucify myCoolApp
This creates a ''.sauce'' directory in the current directory.
It also creates:
  .sauce/myCoolApp.sauce
  .sauce/

Nothing is done if '.sauce' already exists

Now configure your application's environment file(s), and add any extra tasks if you like.


=== sauce
This command really just masquerades as ''cap'', 
It creates tasks based on the .sauce directories it finds beneath the current directory.

== Recipes

=== Grails
A new standard Grails app recipe
  load sauce/recipes/grails