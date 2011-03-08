# postadmin

A CLI tool for administering a database-backed Postfix mail server.
postadmin is developped with the [workaround.org ISP tutorial][1] in mind, but is designed to be database and schema agnostic.
If you haven't [followed this tutorial yet][1], you'll find usefull to have a look at the [default-schema.mysql][2] file.

## Configuration

The [postadmin.conf.sample][3] file is a plain old bash file. You'll find all defaults commented.
postadmin expect to find a configuration file 

    {,postadmin/}postadmin.conf 
    
in

    .
    /etc
    /usr/local/etc
    /opt/etc


## Usage

### Add a new domain

    postadmin add domain mydomain.tld

### Add an email

    postadmin add email me@mydomain.tld

### Add an alias

    postadmin add alias myalias@mydomain.tld bob@google.com

### Remove a domain, all emails and aliases

    postadmin delete domain mydomain.tld

## Help

    postadmin --help

For a specific help

    postadmin [action] [command] --help


[1]: http://workaround.org/ispmail/lenny
[2]: https://github.com/zanshine/postadmin/blob/master/default-schema.mysql
[3]: https://github.com/zanshine/postadmin/blob/master/postadmin.conf.sample
