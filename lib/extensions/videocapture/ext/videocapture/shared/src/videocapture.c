
#include <ruby.h>
#include "ruby/ext/rho/rhoruby.h"



#ifdef __cplusplus
extern "C" {
#endif

// declare Ruby registration method generated by SWIG in videocapture_wrap.c
extern void Init_VideoCaptureNative(void);

// this method executed once on start of program
void Init_Videocapture_extension(void) {
	// execute initialization of Ruby registration (generated by SWIG)
	Init_VideoCaptureNative();

	// You can add some code to this place:
	
	rb_require("videocapture");


}

#ifdef __cplusplus
} //extern "C"
#endif