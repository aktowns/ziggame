dawn:
	$(MAKE) -f ../Makefile.dawn -C dawn build
	$(MAKE) -f ../Makefile.dawn -C dawn install

openal:
	$(MAKE) -f ../Makefile.openal -C openal-soft build
	$(MAKE) -f ../Makefile.openal -C openal-soft install

imgui:
	$(MAKE) -f ../Makefile.imgui -C cimgui build
	$(MAKE) -f ../Makefile.imgui -C cimgui install

nuklear:
	$(MAKE) -f ../Makefile.nuklear -C Nuklear build
	$(MAKE) -f ../Makefile.nuklear -C Nuklear install

stb:
	$(MAKE) -f ../Makefile.stb -C stb build
	$(MAKE) -f ../Makefile.stb -C stb install

glfw:
	$(MAKE) -f ../Makefile.glfw -C glfw build
	$(MAKE) -f ../Makefile.glfw -C glfw install

update:
	$(MAKE) -f ../Makefile.dawn -C dawn update
	$(MAKE) -f ../Makefile.openal -C openal-soft update
	$(MAKE) -f ../Makefile.imgui -C cimgui update
	$(MAKE) -f ../Makefile.stb -C stb update
	$(MAKE) -f ../Makefile.glfw -C glfw update

.PHONY: dawn imgui openal stb glfw