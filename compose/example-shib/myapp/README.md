Shibboleth Example: MyApp Application
======================================

This is a very simple Django application to use as an example to demonstrate Shibboleth authentication.

The app has two views: `/` and `/app/`.

Accessing `/` just gives a "Hello World" page.

Accessing `/app/` displays a page which lists all of the HTTP headers in the `META` list built into Django. This allows the headers set by the Shibboleth SP to be accessed easily, which is useful both for demonstration purposes and testing during development.
