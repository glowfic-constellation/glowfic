[![Build Status](https://travis-ci.org/Marri/glowfic.svg?branch=master)](https://travis-ci.org/Marri/glowfic) [![Test Coverage](https://codeclimate.com/github/Marri/glowfic/badges/coverage.svg)](https://codeclimate.com/github/Marri/glowfic/coverage)

## README

### Dependencies

*   [Ruby](https://www.ruby-lang.org/en/) 2.4.2
*   [Rails](http://rubyonrails.org/) 4.2.9
*   [Redis](https://redis.io/topics/quickstart)
*   [PostgreSQL](https://www.postgresql.org/) (guide to set this up [later](#setting-up-postgresql))

If you are not acquainted with Rails, it may help to go through the [Getting Started with Rails](http://guides.rubyonrails.org/v4.2/getting_started.html) tutorial for Rails 4.2.
If you wish to learn Ruby, try out the [quickstart](https://www.ruby-lang.org/en/documentation/quickstart/) guide provided on their website, or if you are already acquainted with various programming languages, try the [Learn X in Y minutes](https://learnxinyminutes.com/docs/ruby/) tutorial for Ruby.

This README mostly focuses on how to get started developing this project with Ubuntu – commands including `apt` or `apt-get` use the Debian/Ubuntu package manager.
If you are using another flavor of UNIX (another Linux, such as Arch Linux, or macOS), you may find that a lot of the commands are similar but specifics will likely vary – the links to the individual dependency manuals may help you in this case.

If you're using Windows, you may find your best bet – for a variety of reasons – is to set up a virtual machine running Ubuntu where you can do your development.
This is not completely trivial, but if you choose to do so it would be worth looking into [Oracle VirtualBox](https://www.virtualbox.org/).

It should be possible to develop this project otherwise on a Windows machine, but the steps to install all the dependencies on Windows are quite different, and a lot of the steps will differ from those listed here.

### Setup Process

#### Cloning the repository

*   Ensure you have Git installed:

    `sudo apt-get install git` on Ubuntu

    `sudo pacman -S git` on Arch Linux

*   Clone the repository
    *   Enter a folder you want to clone the code to:

        `cd ~/Documents`

    *   Copy the code:

        `git clone https://github.com/Marri/glowfic.git`

(More specific details, such as if you have write permission and wish to use SSH instead of HTTPS, may be found on the GitHub site.)

#### Setting up Ruby

Ruby is required for this project.
If you plan on developing multiple Ruby projects, or want to more easily install a particular version of Ruby, you may find it easier to use [RVM](https://rvm.io/rvm/install), or [rbenv](https://github.com/rbenv/rbenv) combined with [ruby-build](https://github.com/rbenv/ruby-build#readme).
It's recommended you install one of these.

##### RVM

The setup process is described on [the RVM website](https://rvm.io/).
After doing so, you will probably want to restart your terminal.
A more complete description can be found [here](https://rvm.io/rvm/install), some details from which have been reproduced below for convenience.

After installing RVM, you will want to add a line to your shell's profile script:

`export PATH="$PATH:$HOME/.rvm/bin"`

On Ubuntu, if you've not changed your shell from the default Bash, this can be added to the end of `~/.bashrc`; if you're using Zsh instead of Bash, it should be added to `~/.zshrc`.
(You can find out what shell is your default by executing `echo $SHELL` and looking at the last component of the output.)

In addition, if you're using a terminal emulator (which, if you're using Ubuntu Desktop, you likely are – GNOME Terminal), you may need to tell it to run as a login shell.
With GNOME Terminal, go to Edit > Profile Preferences, Command, and then check 'Run command as a login shell' and reopen Terminal.

Now go to the 'glowfic' directory (`cd ~/Documents/glowfic`), and to get the appropriate version of Ruby, run:

*   `rvm get master`
*   `rvm install 2.4.2`
*   `rvm use 2.4.2`

##### rbenv

The process for rbenv has not yet been documented in more depth.
It has [a README with an installation section](https://github.com/rbenv/rbenv#installation), which may be sufficient to get you up and running.

#### Setting up PostgreSQL

If you have not yet set up PostgreSQL:

*   Ensure you have it installed:

    On Ubuntu, `sudo apt install postgresql libpq-dev`

    On Arch Linux, follow [the installation guide on the Arch Linux wiki](https://wiki.archlinux.org/index.php/PostgreSQL#Installing_PostgreSQL)

*   Run the PostgreSQL interactive terminal and create a user account:

    `sudo -u postgres psql`

    Then in the prompt that follows, run the following commands:

    -   `create user <USERNAME> createdb superuser password '<PASSWORD>';`, replacing `<USERNAME>` and `<PASSWORD>` appropriately.
        It's recommended that you not use a standard password, in case you accidentally check it into version control and share it publically.
    -   `\q` to exit
*   Save your credentials somewhere so the application can access the database. Either:
    -   Alter the `config/database.yml` file to have the appropriate username and password, by adding under the `development:` header two lines:

        ```yaml
        username: <USERNAME>
        password: <PASSWORD>
        ```
        **(Ensure you do not check this in when you commit something, or it will be released publically.)**
    -   Or create a file in your home directory named `.pgpass` (`~/.pgpass`) and enter as contents something of the following format:

        `domain:port:database:username:password`

        e.g. `localhost:*:*:username:password` (connects to all local databases with a username of 'username' and a password of 'password')

        You must then modify the permissions to access the file with the command:

        `chmod 0600 ~/.pgpass`

#### Install Redis

##### Using the quickstart guide

Redis has a [quickstart guide](https://redis.io/topics/quickstart) to get you up and running relatively quickly – read the 'Installing Redis' section and do as instructed there.
You may need to first install some dependencies:

*   `sudo apt-get install build-essential tcl8.5`

To set Redis up to run as a daemon (a background server), first install it as instructed and then, on Ubuntu/Debian, run `cd utils && sudo ./install_server.sh` from the 'redis-stable' directory.

##### Using a package manager

Alternatively, you might be able to install Redis using your system's package manager.

On Arch Linux, [as described on the wiki](https://wiki.archlinux.org/index.php/Redis#Installation):

*   `sudo pacman -S redis` to install the `redis` package
*   `sudo systemctl enable redis && sudo systemctl start redis` to enable and start the redis server

#### Installing the gems

Once you've installed Ruby, you need to install the necessary dependencies.
Enter the appropriate folder (`cd ~/Documents/glowfic`) and then execute:

*   `gem install bundler`
*   `bundler`

In addition, the 'execjs' library requires a 'JavaScript runtime'.
For a full list, look at the [ExecJS README](https://github.com/rails/execjs).
Otherwise (and it may be overkill), you can install [NodeJS](https://nodejs.org/en/download/package-manager/).
On Ubuntu this can be done with `sudo apt-get install nodejs`.

#### Setting up the database

Once you've taken these steps, you should be able to set up the contents of the glowfic database with some example data:

*   `rake db:create`
*   `rake db:migrate`
*   `rake db:seed`

This will set up the database and add some sample information – currently these are users, continuities, characters, galleries, icons and templates; no posts will be created.

If you encounter an error involving the 'citext' extension:

*   Execute `sudo -u postgres psql`, and then in the prompt that appears:
*   `CREATE EXTENSION IF NOT EXISTS citext;`

You will need to re-run `rake db:migrate`.

### Executing the server

To execute the server, run `script/rails s` in the glowfic directory.
When it's started, go to [http://localhost:3000/](http://localhost:3000/), where you should see a local copy of the Constellation.
To stop the server, either close the Terminal or use `Ctrl+C` to stop the process.

### Running tests

To run tests, go to the root of the directory (the 'glowfic' folder) and execute the command:

*   `rake spec`.

This will go through the [rspec](http://rspec.info/) tests.

If you encounter a `PG::UndefinedTable` error, mentioning that a relation doesn't exist, ensure you've also migrated your test database.
This can be done with:

*   `RAILS_ENV=test rake db:migrate`

After this, you should be able to re-run the tests.

### Staying up to date

The code updates quite frequently.
To make sure you're using and developing against the latest version, you'll need to download the updated copy, update the gems, and possibly even update your version of Ruby.

First, go to the glowfic folder and download the latest code:

*   `git pull`

Then look at this README again, to make sure the version of Ruby hasn't changed; alternatively, in case this file is not up to date, look at the top of the `Gemfile` file, where it states the version of ruby.
As of writing, this is `ruby '2.4.2'`.
If it has changed, install the latest version along with `bundler`. With RVM, this is done with:

*   `rvm install x.y.z`, replacing `x.y.z` with the numbers shown in the file
*   `rvm use x.y.z`
*   `gem install bundler`

Now, update the gems used for the project:

*   `bundler`

And finally, run any database migrations that might have been added in the meantime:

*   `rake db:migrate`

You should now be able to execute the server, as before but now with the latest updates.

### Attribution

We make use of the [famfamfam silk](http://www.famfamfam.com/lab/icons/silk/) pack of icons, which is licensed under a Creative Commons Attribution license, including some icons that have been modified from the originals.
These can be found in various locations, including in the dropdown menu in posts.
