UNAME_S := $(shell uname -s)
CFLAGS = -Wall -Wextra -Werror -I../ext/stb/
SRCS = src/stb_image.c
NAME = ../sysroot/lib/libclib.a

ifeq ($(UNAME_S),Linux)
    CFLAGS += -D LINUX
endif
ifeq ($(UNAME_S),Darwin)
    CFLAGS += -D OSX
	SRCS += src/macos_surface.m
endif

OFILES = $(patsubst %.c, %.o, $(patsubst %.m, %.o, $(SRCS)))

all: $(NAME) headers clean

headers:
	mkdir -p ../sysroot/include/clib/
	cp include/*.h ../sysroot/include/clib/

$(NAME): $(OFILES)
	ar rcs $(NAME) $(OFILES)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

clean:
	rm -v src/*.o

.PHONY: all headers clean 