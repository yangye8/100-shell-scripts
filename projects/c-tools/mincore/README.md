mincore
=======

Just a wrapper of the `mincore` syscall

How To
=======

<pre>
$ make
$ ./mincore -h
mincore [options] <-p file or directory>
-h
--help
  print this message.
-p
--path
  path to file or directory you want to inspect.
-t
--touch
  whether to touch pages of the file, in order to load them into memory.
$ ./mincore -p <file or directory> \[-t\]
</pre>
