SOURCES ?=
SOURCES += $(wildcard DerivePass/DerivePass/*.m)
SOURCES += $(wildcard DerivePass/DerivePass/*.h)
SOURCES += $(wildcard DerivePass/DerivePassTests/*.m)
SOURCES += $(wildcard DerivePass/DerivePassTests/*.h)
SOURCES += $(wildcard DerivePass/DerivePassUITests/*.m)
SOURCES += $(wildcard DerivePass/DerivePassUITests/*.h)

format:
	clang-format -i $(SOURCES)

.PHONY: format
