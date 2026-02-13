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
        int readed = sscanf(argv[4], "%x", &offset);

        if (readed != 1) {
            fprintf(stderr, "Error: unable to read offset. Perhaps you accidentally added 0x prefix?\n");
            return 3;
        }
    }

    uint start = 0;
    int start_readed = sscanf(argv[2], "%x", &start);
    if (start_readed != 1) {
        fprintf(stderr, "Error: unable to read start position. Perhaps you accidentally added 0x prefix?\n");
        return 4;
    }

    uint end = 0;
    int end_readed = sscanf(argv[3], "%x", &end);
    if (end_readed != 1) {
        fprintf(stderr, "Error: unable to read end position. Perhaps you accidentally added 0x prefix?\n");
        return 5;
    }

    if (start > end) {
        fprintf(stderr, "Error: invalid positions. Perhaps you confused start and end?\n");
        return 6;
    }

    start += offset;
    end += offset;

    if (!start)
        fprintf(stderr, "Warning: start = 0, assume it`s right\n");

    int seek_fail = fseek(source, start, SEEK_SET);
    if (seek_fail) {
        fprintf(stderr, "Error: unable to find position %x (%d) in a file %s\n",
                start, start, argv[1]);
        return 5;
    }

    uint length = end - start;

    byte *buffer = (byte*)malloc(sizeof(byte) * length);
    if (!buffer) {
        fprintf(stderr, "Error: unable to allocate %x bytes\n", length);
        return 6;
    }

    printf("Read %x bytes from %x to %x\n", length, start, end);
    size_t readed = fread(buffer, sizeof(byte), length, source);
    if (readed != (size_t)length) {
        if (feof(source)) {
            fprintf(stderr, "Error: EOF reached before end (%x)\n", end);
            return 7;
        }

        int error = ferror(source);
        if (error) {
            fprintf(stderr, "Error: error %x occured\n", error);
        }
    }

    printf("Ok\n");

    free(buffer);
    fclose(source);
    
    return 0;
}
