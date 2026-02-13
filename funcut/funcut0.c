#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

typedef unsigned int uint;
typedef unsigned char byte;

byte *init_buffer(size_t size);
void deinit_buffer(byte *buffer, size_t size);

void print_hex(byte *buffer, uint length);

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
        return 7;
    }

    uint length = end - start;

    byte *buffer = init_buffer(sizeof(byte) * length);
    if (!buffer) {
        fprintf(stderr, "Error: unable to allocate %x bytes\n", length);
        return 8;
    }

    printf("Read %x bytes from %x to %x\n", length, start, end);
    size_t readed = fread(buffer, sizeof(byte), length, source);
    if (readed != (size_t)length) {
        if (feof(source)) {
            fprintf(stderr, "Error: EOF reached before end (%x)\n", end);
            return 9;
        }

        int error = ferror(source);
        if (error) {
            fprintf(stderr, "Error: error %x occured\n", error);
        }
    }

    printf("Ok\n\n");
    print_hex(buffer, length);

    uint (*func)(uint,uint) = (uint (*)(uint,uint))buffer;
    uint result = func(2, 5);
    printf("\n> %x\n", result);

    deinit_buffer(buffer, sizeof(byte) * length);
    fclose(source);
    
    return 0;
}

byte *init_buffer(size_t size) {
    void *result = mmap(NULL, size,
                        PROT_READ | PROT_WRITE | PROT_EXEC,
                        MAP_PRIVATE | MAP_ANON,
                        -1, 0);
    if (result == MAP_FAILED)
        return NULL;
    return result;
}

void deinit_buffer(byte *buffer, size_t size) {
    munmap(buffer, size);
}

void print_hex(byte *buffer, uint length) {
    for (uint i = 0; i < length; i++) {
        printf("%x ", buffer[i]);

        if ((i+1) % 8 == 0)
            fputc('\n', stdout);
    }
    fputc('\n', stdout);
}
