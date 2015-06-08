CFLAGS ?=
CFLAGS += -O0 -g3 -Wall -Wextra
CFLAGS += -I.
LDFLAGS ?=

OBJECTS =
OBJECTS += src/derivepass.o
OBJECTS += src/crypto.o
OBJECTS += src/crypto-osx.o

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

derivepass: $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJECTS) -o $@
