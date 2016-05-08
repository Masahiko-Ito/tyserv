install:
	cp -fr rundir1 $(HOME)/
	cp -fr rundir2 $(HOME)/
	cp -fr typhoon $(HOME)/
	cp -fr tyserv $(HOME)/
	chmod 600 $(HOME)/tyserv/etc/passwd
