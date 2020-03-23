#define  _XOPEN_SOURCE 500
#include <unistd.h>
#include <ftw.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <getopt.h>
#include <fcntl.h>
#include <assert.h>

#define  __USE_MISC
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>

typedef struct param_t param_t;

struct param_t {
    const char  *path;
    bool        touch;
};

static void     help(void);
static bool     parse_params(int argc, char **argv, param_t *param);
static bool     isdir(const char *path);
static void     inspect(const char *file, bool touch);
static int      traverse(const char *path, const struct stat *st, int type, struct FTW *);

int
main(int argc, char **args) {
    param_t     param;
    param.path = NULL;
    param.touch = false;

    if (!parse_params(argc, args, &param)) {
        exit(1);
    }

    if (!isdir(param.path)) {
        inspect(param.path, param.touch);
    } else if (nftw(param.path, traverse, 10, 0) == -1) {
        fprintf(stderr, "error on walking through %s\n", param.path);
        exit(1);
    }

    return 0;
}

bool
isdir(const char *path) {
    struct stat st;
    if (lstat(path, &st) == -1) {
        perror("lstat");
        return false; //!FIXME
    }
    return S_ISDIR(st.st_mode);
}

void
inspect(const char *file, bool touch) {
    int             fd;
    struct stat     st;
    size_t          fsize;          //~ file size
    size_t          psize;          //~ page size
    size_t          tailsize;       //~ fsize % psize
    size_t          npages;         //~ page count of file
    size_t          pincore;        //~ page count in cache
    size_t          bincore;        //~ bytes in cache
    bool            aligned;        //~ whether fsize is power of psize
    char            *base;          //~ base of mmap
    unsigned char   *hints;         //~ hints used by `mincore'

    fd = open(file, O_RDONLY);
    if (fd == -1) {
        fprintf(stderr, "%s: open: %m, omitted\n", file);
        return ;
    }
    if (fstat(fd, &st) == -1) {
        fprintf(stderr, "%s: fstat: %m, omitted\n", file);
        return ;
    }
    fsize = st.st_size;
    psize = getpagesize();
    npages = (fsize + psize - 1) / psize;
    aligned = !(fsize / psize);

    if (fsize == 0) {
        fprintf(stderr, "%s: file size is 0, omitted\n", file);
        return ;
    }
    base = mmap(NULL, fsize, PROT_READ, MAP_SHARED, fd, 0);
    close(fd);
    if (base == MAP_FAILED) {
        fprintf(stderr, "%s: mmap: %m, omitted\n", file);
        return ;
    }

    hints = (unsigned char *) malloc(npages);
    assert(hints != NULL);
    if (mincore(base, fsize, hints) == -1) {
        fprintf(stderr, "%s: mincore: %m, omitted\n", file);
        return ;
    }

    tailsize = fsize % psize;
    bool tailincore = (hints[npages-1] & 0x1);
    size_t i = 0;
    pincore = 0;
    for ( ; i < npages; ++i) {
        if (hints[i] & 0x1) {
            ++pincore;
        }
    }
    bincore = pincore * psize;
    bincore -= (tailincore && !aligned) ? psize - tailsize : 0;

    fprintf(stderr,
            "%s:\n"
            "\t page count: %lu, cached: %lu\n"
            "\t file size: %lu(%luK), cached: %lu(%luK)\n",
            file,
            npages, pincore,
            fsize, fsize/1024, bincore, bincore/1024);
    munmap(base, fsize);
    free(hints);
}

int
traverse(const char *path, const struct stat *st, int type, struct FTW *ftw) {
    if (type == FTW_F) {
        //! touch is dangerous while traversing
        inspect(path, false);
    } else {
        fprintf(stderr, "<%s>\n", path);
    }
    return 0;
}

bool
parse_params(int argc, char **argv, param_t *param) {
    int             opt;
    const char      *optstr = "htrp:";
    struct option   long_opts[] = {
        {"help", 0, NULL, 'h'},
        {"path", 1, NULL, 'p'},
        {"touch", 0, NULL, 't'},
        {NULL, 0, NULL, 0}
    };

    while ((opt = getopt_long(argc, argv, optstr, long_opts, NULL)) != -1) {
        switch (opt) {
            case 'p':
                param->path = optarg;
                break;
            case 't':
                param->touch = true;
                break;
            case '?':
            case 'h':
            default :
                help();
                exit(1);
                break;
        }
    }
    if (param->path == NULL) {
        fprintf(stderr, "babe, babe, give me the path\n");
        help();
        return false;
    }
    return true;
}

void
help() {
    fprintf(stderr,
            "mincore [options] <-p file or directory>\n"
            "-h\n"
            "--help\n"
            "\tprint this message.\n"
            "-p\n"
            "--path\n"
            "\tpath to file or directory you want to inspect.\n"
            "-t\n"
            "--touch\n"
            "\twhether to touch pages of the file, in order to load them into memory.\n");
}
