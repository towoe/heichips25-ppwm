all: gds/logo.gds

gds/eggpwm.gds: img/eggpwm.png
	@mkdir -p $(dir $@)
	# TopMetal2.drawing 134:0
	python3 make_gds.py $< $@ --cellname egg_logo --scale 1.0 --pixel-size 2 --threshold 128 --merge --layer 134 --datatype 0 --invert

gds/eggpwm_nofill.gds: img/eggpwm_nofill.png
	@mkdir -p $(dir $@)
	# TopMetal2.nofill 134:23
	python3 make_gds.py $< $@ --cellname egg_logo --scale 1.0 --pixel-size 2 --threshold 128 --merge --layer 134 --datatype 23 --invert

gds/logo.gds: gds/eggpwm.gds gds/eggpwm_nofill.gds
	python3 combine_gds.py $^ $@

clean:
	rm -f gds/*.gds

.PHONY: all clean
