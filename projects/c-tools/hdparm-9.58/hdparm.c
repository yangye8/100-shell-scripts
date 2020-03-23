/*
 * hdparm.c - Command line interface to get/set hard disk parameters.
 *          - by Mark Lord (C) 1994-2018 -- freely distributable.
 */
#define HDPARM_VERSION "v9.58"

#define _LARGEFILE64_SOURCE /*for lseek64*/
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>
#include <sys/types.h>
#include <sys/mount.h>
#include <sys/mman.h>
#include <sys/user.h>
#include <linux/types.h>

static int    argc;
static char **argv;
static char  *argp;
static int    num_flags_processed = 0;

#ifndef O_DIRECT
#define O_DIRECT	040000	/* direct disk access, not easily obtained from headers */
#endif

#define TIMING_BUF_MB		2
#define TIMING_BUF_BYTES	(TIMING_BUF_MB * 1024 * 1024)

char *progname;
static int do_defaults = 0, do_flush = 0, do_ctimings, do_timings = 0;

static int   noisy = 1;

const int timeout_15secs = 15;
const int timeout_60secs = 60;
const int timeout_5mins  = (5 * 60);
const int timeout_2hrs   = (2 * 60 * 60);

static int open_flags = O_RDONLY|O_NONBLOCK;

const char *BuffType[4]		= {"unknown", "1Sect", "DualPort", "DualPortCache"};

void process_dev (char *devname);

static void flush_buffer_cache (int fd)
{
	sync();
	fsync(fd);				/* flush buffers */
	fdatasync(fd);				/* flush buffers */
	sync();
	if (ioctl(fd, BLKFLSBUF, NULL))		/* do it again, big time */
		perror("BLKFLSBUF failed");
	sync();
}

static int seek_to_zero (int fd)
{
	if (lseek(fd, (off_t) 0, SEEK_SET)) {
		perror("lseek() failed");
		return 1;
	}
	return 0;
}

static int read_big_block (int fd, char *buf)
{
	int i, rc;
	if ((rc = read(fd, buf, TIMING_BUF_BYTES)) != TIMING_BUF_BYTES) {
		if (rc) {
			if (rc == -1)
				perror("read() failed");
			else
				fprintf(stderr, "read(%u) returned %u bytes\n", TIMING_BUF_BYTES, rc);
		} else {
			fputs ("read() hit EOF - device too small\n", stderr);
		}
		return EIO;
	}
	/* access all sectors of buf to ensure the read fully completed */
	for (i = 0; i < TIMING_BUF_BYTES; i += 512)
		buf[i] &= 1;
	return 0;
}

static void *prepare_timing_buf (unsigned int len)
{
	unsigned int i;
	__u8 *buf;

	buf = mmap(NULL, len, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, -1, 0);
	if (buf == MAP_FAILED) {
		perror("could not allocate timing buf");
		return NULL;
	}
	for (i = 0; i < len; i += 4096)
		buf[i] = 0; /* guarantee memory is present/assigned */
	if (-1 == mlock(buf, len)) {
		perror("mlock() failed on timing buf");
		munmap(buf, len);
		return NULL;
	}
	mlockall(MCL_CURRENT|MCL_FUTURE); // don't care if this fails on low-memory machines
	sync();

	/* give time for I/O to settle */
	sleep(3);
	return buf;
}

static void time_cache (int fd)
{
	char *buf;
	struct itimerval e1, e2;
	double elapsed, elapsed2;
	unsigned int iterations, total_MB;

	buf = prepare_timing_buf(TIMING_BUF_BYTES);
	if (!buf)
		return;

	/*
	 * getitimer() is used rather than gettimeofday() because
	 * it is much more consistent (on my machine, at least).
	 */
	setitimer(ITIMER_REAL, &(struct itimerval){{1000,0},{1000,0}}, NULL);
	if (seek_to_zero (fd)) return;
	if (read_big_block (fd, buf)) return;
	printf(" Timing %scached reads:   ", (open_flags & O_DIRECT) ? "O_DIRECT " : "");
	fflush(stdout);

	/* Clear out the device request queues & give them time to complete */
	flush_buffer_cache(fd);
	sleep(1);

	/* Now do the timing */
	iterations = 0;
	getitimer(ITIMER_REAL, &e1);
	do {
		++iterations;
		if (seek_to_zero (fd) || read_big_block (fd, buf))
			goto quit;
		getitimer(ITIMER_REAL, &e2);
		elapsed = (e1.it_value.tv_sec - e2.it_value.tv_sec)
		 + ((e1.it_value.tv_usec - e2.it_value.tv_usec) / 1000000.0);
	} while (elapsed < 2.0);
	total_MB = iterations * TIMING_BUF_MB;

	elapsed = (e1.it_value.tv_sec - e2.it_value.tv_sec)
	 + ((e1.it_value.tv_usec - e2.it_value.tv_usec) / 1000000.0);

	/* Now remove the lseek() and getitimer() overheads from the elapsed time */
	getitimer(ITIMER_REAL, &e1);
	do {
		if (seek_to_zero (fd))
			goto quit;
		getitimer(ITIMER_REAL, &e2);
		elapsed2 = (e1.it_value.tv_sec - e2.it_value.tv_sec)
		 + ((e1.it_value.tv_usec - e2.it_value.tv_usec) / 1000000.0);
	} while (--iterations);

	elapsed -= elapsed2;

	if (total_MB >= elapsed)  /* more than 1MB/s */
		printf("%3u MB in %5.2f seconds = %6.2f MB/sec\n",
			total_MB, elapsed,
			total_MB / elapsed);
	else
		printf("%3u MB in %5.2f seconds = %6.2f kB/sec\n",
			total_MB, elapsed,
			total_MB / elapsed * 1024);

	flush_buffer_cache(fd);
	sleep(1);
quit:
	munlockall();
	munmap(buf, TIMING_BUF_BYTES);
}

static int time_device (int fd)
{
	char *buf;
	double elapsed;
	struct itimerval e1, e2;
	int err = 0;
	unsigned int max_iterations = 1024, total_MB, iterations;

	/*
	 * get device size
	 */
	if (do_ctimings || do_timings) {
		__u64 nsectors;
		do_flush = 1;
        nsectors =4788224;
		max_iterations = nsectors / (2 * 1024) / TIMING_BUF_MB;
        printf("max_iterations: %d\n",max_iterations);
	}
	buf = prepare_timing_buf(TIMING_BUF_BYTES);
	if (!buf)
		err = ENOMEM;
	if (err)
		goto quit;

	printf(" Timing %s disk reads", (open_flags & O_DIRECT) ? "O_DIRECT" : "buffered");
	printf(": ");
	fflush(stdout);

	/*
	 * getitimer() is used rather than gettimeofday() because
	 * it is much more consistent (on my machine, at least).
	 */
	setitimer(ITIMER_REAL, &(struct itimerval){{1000,0},{1000,0}}, NULL);

	/* Now do the timings for real */
	iterations = 0;
	getitimer(ITIMER_REAL, &e1);
	do {
		++iterations;
		if ((err = read_big_block(fd, buf)))
			goto quit;
		getitimer(ITIMER_REAL, &e2);
		elapsed = (e1.it_value.tv_sec - e2.it_value.tv_sec)
		 + ((e1.it_value.tv_usec - e2.it_value.tv_usec) / 1000000.0);
	} while (elapsed < 3.0 && iterations < max_iterations);

	total_MB = iterations * TIMING_BUF_MB;
	if ((total_MB / elapsed) > 1.0)  /* more than 1MB/s */
		printf("%3u MB in %5.2f seconds = %6.2f MB/sec\n",
			total_MB, elapsed, total_MB / elapsed);
	else
		printf("%3u MB in %5.2f seconds = %6.2f kB/sec\n",
			total_MB, elapsed, total_MB / elapsed * 1024);
quit:
	munlockall();
	if (buf)
		munmap(buf, TIMING_BUF_BYTES);
	return err;
}

static __u16 *id;

static void usage_help (int clue, int rc)
{
	FILE *desc = rc ? stderr : stdout;

	fprintf(desc,"\n%s - get/set hard disk parameters - version " HDPARM_VERSION ", by Mark Lord.\n\n", progname);
	if (1) if (rc) fprintf(desc, "clue=%d\n", clue);
	fprintf(desc,"Usage:  %s  [options] [device ...]\n\n", progname);
	fprintf(desc,"Options:\n"
	" -t   Perform device read timings\n"
	" -T   Perform cache read timings\n"
	"\n");
	exit(rc);
}

void process_dev (char *devname)
{
	int fd;
	int err = 0;

	id = NULL;
	fd = open(devname, open_flags);
	if (fd < 0) {
		err = errno;
		perror(devname);
		exit(err);
	}
	printf("\n%s:\n", devname);

	if (do_ctimings)
		time_cache(fd);
	if (do_timings)
		err = time_device(fd);

	close (fd);
	if (err)
		exit (err);
}

#define      DO_FLAG(CH,VAR)              CH:VAR=1;noisy=1;break

int main (int _argc, char **_argv)
{
	int no_more_flags = 0;
	char c;

	argc = _argc;
	argv = _argv;
	argp = NULL;

	if  ((progname = (char *) strrchr(*argv, '/')) == NULL)
		progname = *argv;
	else
		progname++;
	++argv;

	if (!--argc)
		usage_help(6,EINVAL);
	while (argc--) {
		argp = *argv++;
		if (no_more_flags || argp[0] != '-') {
			if (!num_flags_processed)
				do_defaults = 1;
			process_dev(argp);
			continue;
		}
		if (0 == strcmp(argp, "--")) {
			no_more_flags = 1;
			continue;
		}
		if (!*++argp)
			usage_help(8,EINVAL);
		while (argp && (c = *argp++)) {
			switch (c) {
				case      DO_FLAG('t',do_timings);
				case      DO_FLAG('T',do_ctimings);
				default:
					usage_help(10,EINVAL);
			}
			num_flags_processed++;
		}
		if (!argc)
			usage_help(11,EINVAL);
	}
	return 0;
}
