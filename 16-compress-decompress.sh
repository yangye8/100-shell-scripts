# Pack
tar cf - paths-to-archive |pv | pigz -9 -p 32 > archive.tar.gz

tar -I pigz -cf bigbackup.tar.gz  paths-to-archive
#Unpack
tar -I pigz -xf backup_web.tar.gz -C path

pigz -dc target.tar.gz | pv | tar xf -
unpigz < /path/to/archive.tar.gz | tar -xvC /where/to/unpack/it/
