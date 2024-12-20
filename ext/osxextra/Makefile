CFLAGS = -Wall -Wextra -Werror
SRCS = osxextra.m
OFILES = $(SRCS:.m=.o)
NAME = libosxextra.a

all: $(NAME) clean

$(NAME): $(OFILES)
	ar rcs $(NAME) $(OFILES)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

clean:
	rm *.o

.PHONY: all clean 