sample1: sample1.cob tycob.c
	cc -c tycob.c
	cobc -Wall -c -static -fmain sample1.cob
	cobc -o sample1 sample1.o tycob.o
	rm  sample1.o tycob.o
