
#include <ruby.h>
#include "ruby/ext/rho/rhoruby.h"


#ifdef __cplusplus
extern "C" {
#endif

// declare Ruby registration method generated by SWIG in rawsensors_wrap.c
extern void Init_RawSensorsNative(void);

// this method executed once on start of program
void Init_RawSensors_extension(void) {
	// execute initialization of Ruby registration (generated by SWIG)
	Init_RawSensorsNative();

	// You can add some code to this place:
    rb_require("rawsensors");

}

#ifdef __cplusplus
} //extern "C"
#endif