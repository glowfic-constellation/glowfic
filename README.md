[![Build Status](https://travis-ci.org/Marri/glowfic.svg?branch=master)](https://travis-ci.org/Marri/glowfic) [![Test Coverage](https://codeclimate.com/github/Marri/glowfic/badges/coverage.svg)](https://codeclimate.com/github/Marri/glowfic/coverage)

## README

### Dependencies

*   [Ruby](https://www.ruby-lang.org/en/) 2.3.3
*   [Rails](http://rubyonrails.org/) 3.2.22.5
*   [Redis](https://redis.io/topics/quickstart)
*   [PostgreSQL](https://www.postgresql.org/) (guide to set this up [later](#setting-up-postgresql))

If you are not acquainted with Rails, it may help to go through the [Getting Started with Rails](http://guides.rubyonrails.org/v3.2/getting_started.html) tutorial for Rails 3.2.
If you wish to learn Ruby, try out the [quickstart](https://www.ruby-lang.org/en/documentation/quickstart/) guide provided on their website, or if you are already acquainted with various programming languages, try the [Learn X in Y minutes](https://learnxinyminutes.com/docs/ruby/) tutorial for Ruby.

For Redis, follow [the quickstart guide](https://redis.io/topics/quickstart) (installing Redis).
You may need to first: `sudo apt-get install build-essential tcl8.5`.
To set it up as a daemon (background server), on Ubuntu/Debian run `cd utils && sudo ./install_server.sh` from the 'redis-stable' directory, as in the quickstart guide.

### Setup Process

#### Cloning the repository

*   Ensure you have Git installed – `sudo apt-get install git` on Ubuntu
*   Clone the repository – e.g. with `git clone https://github.com/Marri/glowfic.git`

More specific details may be found on the GitHub site.

#### Language dependencies

Ruby is required for this project. [RVM](https://rvm.io/rvm/install) and [rbenv](https://github.com/rbenv/rbenv) allow you to have multiple versions of Ruby installed at a time, so it's recommended you get one of those if you plan on doing much Ruby work.

Once you've done so, you need to install the necessary dependencies.
This can be done with:

*   `gem install bundler`
*   `bundler`

In addition, the 'execjs' library requires a 'JavaScript runtime'.
For a full list, look at the [ExecJS README](https://github.com/rails/execjs).
Otherwise (and it may be overkill), you can install [NodeJS](https://nodejs.org/en/download/package-manager/).
On Ubuntu this is done with `sudo apt-get install nodejs`.

##### RVM

If you decide to install RVM and you're on Ubuntu, you may need to add a line to `~/.bashrc`:
`export PATH="$PATH:$HOME/.rvm/bin"`.
In addition, you may need to open Terminal and go to Edit > Preferences, Profiles, Edit, Command, and then check 'Run command as a login shell'.
Then go to the 'glowfic' directory, and to get the appropriate version of Ruby, run:

*   `rvm get master`
*   `rvm install 2.3.3`
*   `rvm use 2.3.3`

After this you can continue to use the `gem install bundler` command and then `bundler` to install other dependencies.

There may be similar steps necessary in other versions of Linux with RVM.
The process for rbenv has not yet been documented in more depth.

#### Setting up PostgreSQL

If you have not yet set up PostgreSQL:

*   Ensure you have it installed with (on Ubuntu): `sudo apt install postgresql`.
*   Run `sudo -u postgres psql` and create a user account
    -   `create user <USERNAME> createdb createuser password '<PASSWORD>';` should do this, replacing the appropriate parts. The password does not have to be super secure, and it's recommended that you not use a standard password, in case you accidentally check it into version control.
*   Save your credentials somewhere so the application can access the database. Either:
    -   Alter the `config/database.yml` file to have the appropriate username and password (**do not check this in when you commit something**), or
    -   Create a file in your home directory named `.pgpass` (`~/.pgpass`) and write in something of the following format:
        `domain:port:database:username:password`
        e.g. `localhost:*:*:username:password` (connects to all local databases with a username of 'username' and a password of 'password')

If you encounter an issue while building the pg 'native extensions', ensure you have the `libpq-dev` package installed (`sudo apt-get install libpq-dev` on Ubuntu).

#### Setting up the database

Once you've taken these steps, you should be able to go into the 'glowfic' folder and execute:

*   `rake db:create`
*   `rake db:migrate`
*   `rake db:seed`

This will set up the database and add some sample information, though no posts will be created.

#### Executing the server

You should now be able to run `script/rails s` in the glowfic directory. When it's started, go to [http://localhost:3000/](http://localhost:3000/), where you should see a local copy of the Constellation.

#### Running tests

To run tests, go to the root of the directory (the 'glowfic' folder) and execute the command `rake spec`. This will go through the [rspec](http://rspec.info/) tests.
