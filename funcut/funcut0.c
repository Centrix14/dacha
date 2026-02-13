#include <stdio.h>
#include <stdlib.h>

typedef unsigned int uint;
typedef unsigned char byte;

int main(int argc, char *argv[]) {
    if (argc < 4 || argc > 5) {
        fprintf(stderr, "usage: fc0 object-file start end [offset]\n");
        return 1;
    }

    FILE *source = fopen(argv[1], "rb");
    if (!source) {
        fprintf(stderr, "Error: unable to open file %s\n", argv[1]);
        return 2;
    }

    uint offset = 0;
    if (argc == 5) {
        offset = (uint)atoi(argv[4]);

        if (!offset)
            fprintf(stderr, "Warning: offset = 0, assume it`s right\n");
    }

    uint start = (uint)atoi(argv[2]) + offset;
    uint end = (uint)atoi(argv[3]) + offset;

    if (start > end) {
        fprintf(stderr, "Error: invalid positions. Perhaps you confused start and end?\n");
        return 4;
    }

    if (!start)
        fprintf(stderr, "Warning: start = 0, assume it`s right\n");

    int seek_fail = fseek(source, start, SEEK_SET);
    if (seek_fail) {
        fprintf(stderr, "Error: unable to find position 0x%x (%d) in a file %s\n",
                start, start, argv[1]);
        return 5;
    }

    uint length = end - start;

    byte *buffer = (byte*)malloc(sizeof(byte) * length);
    if (!buffer) {
        fprintf(stderr, "Error: unable to allocate 0x%x bytes\n", length);
        return 6;
    }

    printf("Read 0x%x bytes from 0x%x to 0x%x\n", length, start, end);
    size_t readed = fread(buffer, sizeof(byte), length, source);
    if (readed != (size_t)length) {
        if (feof(source)) {
            fprintf(stderr, "Error: EOF reached before end (0x%x)\n", end);
            return 7;
        }

        int error = ferror(source);
        if (error) {
            fprintf(stderr, "Error: error 0x%x occured\n", error);
        }
    }

    printf("Ok\n");

    free(buffer);
    fclose(source);
    
    return 0;
}
