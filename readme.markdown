sportle (working title)
======

a sinatra webapp to store, organize and share sport schedules. A Redis Database is used as Backend

Dependencies
----

Dependencies are all handled through bundler.

    $ bundle install

See http://redis.io for directions on installing and configuring a redis server.

Setup
----

To run the server:
    $ rackup -p 4567

Database
----

Sportle will connect to Redis on localhost on the default port. You can specify an other setup if you set REDIS_URL in your environment, i.e.:

    $ REDIS_URL='redis://:secret@1.2.3.4:9000/3' ruby service.rb

This would connect to host 1.2.3.4 on port 9000, uses database number 3 using the password 'secret'.

Meta
----

Created by Eger Andreas

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">sportle</span> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/">Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License</a>.
