ReceiveD
========

***
I don't use it anymore, but when it was used, it was used in production.
I consider it stable, rather than obsolete.
***

ReceiveD is yet another way for receiving mail with Rails.
Why have yet another subsystem (like IMAP), when you can deliver the mail
directly to your data store?

ReceiveD is almost [RFC2033][1] compliant LMTP server built around
[eventmachine][2] and as such should be quite fast.

The receive daemon will listen on TCP or UNIX socket, and write the mail
to the backend storage.

Currently only [MongoDB][3] and [Sidekiq][6]/Redis is supported, but writing another backend
(MySQL, Redis, etc.) is trivial.


Installation
------------
`sudo gem install received`

Modify your [Postfix][4] configuration to deliver mail via LMTP to TCP or UNIX socket.

Example main.cf:

    virtual_transport = lmtp:192.168.2.106:1111
    virtual_mailbox_domains = example.com

Create a YAML configuration file with parameters for the selected backend.

The default environment is *production*, but you can specify other environment
using RAILS_ENV environment variable.
In this case, make sure you have the relevant key in your configuration file.

### MongoDB

Create a YAML configuration file which has the following parameters:

    {'production'=>{'host'=>hostname, 'database'=>db, 'collection'=>col}}

The mongoid.yml will do, just add the name of collection, i.e.

    production:
      <<: *defaults
      database: foo_production
      collection: inbox

### Sidekiq/Redis

Example:

    production:
      redis_url: redis://localhost:6379
      namespace: resque:gitlab
      queue: email_receiver
      worker: EmailReceiverWorker


Running
-------
Check -h for help, port/unix socket path and config file are required.


Bugs and missing features
-------------------------

* When using UNIX socket the permissions/ownership are not changed. Use -u and -g when running
  as daemon or change the permissions/ownership manually.
* ReceiveD wasn't really tested for compliance with RFC2033
* It doesn't implement [RFC2034][5] (ENHANCEDSTATUSCODES), because Postfix doesn't seem to care
* It doesn't perform any validation of the provided input, e.g. LHLO, MAIL FROM, RCPT TO

[1]: http://tools.ietf.org/html/rfc2033
[2]: http://rubyeventmachine.com/
[3]: http://www.mongodb.org/
[4]: http://www.postfix.org/
[5]: http://tools.ietf.org/html/rfc2034
[6]: https://sidekiq.org/

Copyright (c) 2011 Roman Shterenzon, released under the MIT license
