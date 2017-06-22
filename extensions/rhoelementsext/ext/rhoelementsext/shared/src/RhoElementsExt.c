#include "common/app_build_capabilities.h"
#ifdef __cplusplus
extern "C" {
#endif

// declare Ruby registration method generated by SWIG in rhoelementsext_wrap.c
#ifndef RHO_NO_RUBY_API
extern void Init_RhoElementsExt(void);
extern int  rho_ruby_is_started();
#endif
extern void registerRhoExtension();
// this method executed once on start of program
void Init_RhoElementsExt_extension(void) {
#ifndef RHO_NO_RUBY_API
	// execute initialization of Ruby registration (generated by SWIG)
    if (rho_ruby_is_started())
    {
        Init_RhoElementsExt();
    }
#endif
	// You can add some code to this place:
	registerRhoExtension();

}

#ifdef __cplusplus
} //extern "C"
#endif