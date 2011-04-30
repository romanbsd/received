ReceiveD
========
Yet another way for receiving mail with Rails. ReceiveD is almost RFC2033 compliant LMTP server.
The receive daemon will listen on TCP or UNIX socket, and write the mail to the backend storage.

Currently only MongoDB is supported, but writing another backend (MySQL, Redis, etc.) is trivial.

Installation
------------
`sudo gem install received`

Modify your postfix configuration to deliver mail to unix socket.
Create a YAML configuration file which has the following parameters:
    {'production'=>{'host'=>hostname, 'database'=>db, 'collection'=>col}}

The mongoid.yml will do, just add the name of collection, i.e.
<pre>
production:
  <<: *defaults
  database: foo_production
  collection: inbox
</pre>

The default environment is 'production', you can specify other environment using RAILS_ENV environment variable.
In this case, make sure you have the relevant key in your configuration file.

Running
-------
Check -h for help, port/unix socket path and config file are required.

Bugs and missing features
-------------------------

* ReceiveD wasn't really tested for compliance with RFC2033
* As such, it doesn't perform validation of the provided input, e.g. LHLO, MAIL FROM, RCPT TO

Copyright (c) 2011 Roman Shterenzon, released under the MIT license