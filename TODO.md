
* Make thread safe: put Conn and Config objects in an instance of Confluence class 
instead of the class itself so if we use this class in a JRuby rails app where multiple
threads are used we will be happy.

* Add module for Spaces

* Add module for Permissions
