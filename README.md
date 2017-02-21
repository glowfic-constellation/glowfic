[![Build Status](https://travis-ci.org/Marri/glowfic.svg?branch=master)](https://travis-ci.org/Marri/glowfic) [![Test Coverage](https://codeclimate.com/github/Marri/glowfic/badges/coverage.svg)](https://codeclimate.com/github/Marri/glowfic/coverage)

## README

### Dependencies

This application currently uses [Ruby](https://www.ruby-lang.org/en/) 2.3.3 and [Rails](http://rubyonrails.org/) 3.2.22.3.
If you are not acquainted with Rails,it may help to go through the '[Getting Started with Rails](http://guides.rubyonrails.org/v3.2/getting_started.html)' tutorial for Rails 3.2.
If you wish to learn Ruby, try out the '[quickstart](https://www.ruby-lang.org/en/documentation/quickstart/)' guide provided on their website, or if you are already acquainted with various programming languages, try the '[Learn X in Y minutes](https://learnxinyminutes.com/docs/ruby/)' tutorial for Ruby.

You also need to have [Redis](https://redis.io/) installed.
To get this done quickly, follow [the quickstart guide](https://redis.io/topics/quickstart) (installing Redis).
In order to perform this task properly, you may need to first: `sudo apt-get install build-essential tcl8.5`.
To set it up as a daemon (background server), on Ubuntu/Debian you will also want to run `cd utils && sudo ./install_server.sh` from the 'redis-stable' directory – the default settings should work.

### Setup Process

#### Cloning the repository

In order to get up and running, clone the repository (get Git if you don't already have it – `sudo apt-get install git` on Ubuntu) with a command such as `git clone https://bitbucket.org/MarriNikari/glowfic`.
More specific details may be found on the Bitbucket site.

#### Language dependencies

Install Ruby (probably with something such as [RVM](https://rvm.io/rvm/install) or [rbenv](https://github.com/rbenv/rbenv) so as to manage your version appropriately), and the necessary dependencies (`gem install bundler`, `bundler`).

In addition, the 'execjs' library requires a 'JavaScript runtime'.
For a full list, look at the [ExecJS README](https://github.com/rails/execjs), but otherwise (and it may be overkill), you can install [NodeJS](https://nodejs.org/en/download/package-manager/) – on Ubuntu this is done with `sudo apt-get install nodejs`, which should allow it to function properly.

##### RVM

If you decide to install RVM and you're on Ubuntu, you may need to add a line to `~/.bashrc`: `export PATH="$PATH:$HOME/.rvm/bin"`.
In addition, you may need to open Terminal and go to Edit > Preferences, Profiles, Edit, Command, and then check 'Run command as a login shell', which should allow you to use RVM properly.
Then go to the 'glowfic' directory, run `rvm get master`, `rvm install 2.0.0`, `rvm use 2.0.0`, after which you can continue to use the `gem install bundler` command and then `bundler`.

There may be similar steps necessary in other versions of Linux with RVM.
The process for rbenv has not yet been documented in more depth.

#### Setting up PostgreSQL

If you have not yet set up PostgreSQL, ensure you have it installed with (on Ubuntu) `sudo apt install postgresql`.
Then run `sudo -u postgres psql` and create a user account – `create user <USERNAME> createdb createuser password '<PASSWORD>';` should do this, replacing the appropriate parts.
Then, either alter the `config/database.yml` file to have the appropriate username and password (ensure not to check this in if you commit something), or alternatively create a file in your home directory named `.pgpass` (`~/.pgpass`) and write in something of the following format:
`domain:port:database:username:password` – for example, `localhost:*:*:username:password` would connect to all databases on the local machine with a username of 'username' and a password of 'password'.

If you encounter an issue while building the pg 'native extensions', ensure you have the `libpq-dev` package installed (`sudo apt-get install libpq-dev` on Ubuntu).

#### Setting up the database

Once you've taken these steps, you should be able to go into the 'glowfic' folder and execute `rake db:create`, `rake db:migrate`, `rake db:seed`, which will set up the database and add some sample information, though no posts will be created.

#### Executing the server

You should now be able to run `script/rails s`, and when it is loaded go to [http://localhost:3000/](http://localhost:3000/) where you should see a local copy of the Constellation.

#### Running tests

To run tests, go to the root of the directory (the 'glowfic' folder) and execute the command `rake`, which will go through the '[rspec](http://rspec.info/)' tests.
