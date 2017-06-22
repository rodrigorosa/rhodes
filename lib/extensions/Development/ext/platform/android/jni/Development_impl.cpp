#include "rhodes.h"
#include "Development.h"

#include "logging/RhoLog.h"

#include "rhodes/JNIRhodes.h"

#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Development_impl"

#define DEVELOPMENT_FACTORY_CLASS "com.rho.development.DevelopmentFactory"
#define RHODES_SERVICE_CLASS "com.rhomobile.rhodes.RhodesService"
#define DEVELOPMENT_CLASS "com.rho.development.Development"

extern "C" void Init_Development_API(void);

extern "C" void Init_Development(void)
{
    RAWTRACE(__FUNCTION__);

    JNIEnv *env = jnienv();
    if(env)
    {
        jclass cls = rho_find_class(env, DEVELOPMENT_FACTORY_CLASS);
        if(!cls)
        {
            RAWLOG_ERROR1("Failed to find java class: %s", DEVELOPMENT_FACTORY_CLASS);
            return;
        }
        jmethodID midFactory = env->GetMethodID(cls, "<init>", "()V");
        if(!midFactory)
        {
            RAWLOG_ERROR1("Failed to get constructor for java class %s", DEVELOPMENT_FACTORY_CLASS);
            return;
        }
        jobject jFactory = env->NewObject(cls, midFactory);
        if(env->IsSameObject(jFactory, NULL))
        {
            RAWLOG_ERROR1("Failed to create %s instance", DEVELOPMENT_FACTORY_CLASS);
            return;
        }
        
        RAWTRACE("Initializing Java factory");

        rho::CDevelopmentBase::setJavaFactory(env, jFactory);

        RAWTRACE("Deleting JNI reference");

        env->DeleteLocalRef(jFactory);

        RAWTRACE("Initializing API");

        Init_Development_API();

        RAWTRACE("Init_Development succeeded");
    }
    else
    {
        RAWLOG_ERROR("Failed to initialize Development API: jnienv() is failed");
    }

}

extern "C" void Development_Init();

static int already_inited = 0;

extern "C" void Init_Development_extension() {
     Development_Init();

     JNIEnv *env = jnienv();
     jclass cls = rho_find_class(env, DEVELOPMENT_CLASS);
     if (!cls) {
    	 RAWLOG_ERROR1("Failed to create %s instance", DEVELOPMENT_CLASS);
    	 return;
     }
     jmethodID mid = getJNIClassStaticMethod(env, cls, "initExtension", "()V");
     if (!mid) {
    	 RAWLOG_ERROR1("Failed to get initExtension() method from %s class", DEVELOPMENT_CLASS);
    	 return;
     }
     if (already_inited == 0) {
    	 already_inited = 1;
    	 env->CallStaticVoidMethod(cls, mid);
     }

}

extern "C" void Bundle_update_on_triple_tap();
extern "C" void Bundle_update_on_quadro_tap();

extern "C" void JNICALL Java_com_rho_development_Development_onTripleTapNative
  (JNIEnv *env, jclass)
{
	Bundle_update_on_triple_tap();
}

extern "C" void JNICALL Java_com_rho_development_Development_onQuadroTapNative
  (JNIEnv *env, jclass)
{
	Bundle_update_on_quadro_tap();
}

extern "C" rho::String get_local_ip_adress() {

    //RhodesService.getLocalIpAddress
    //rho::String res = "";	
	
    JNIEnv *env = jnienv();
    jclass cls = getJNIClass(RHODES_JAVA_CLASS_RHODES_SERVICE);
    if (!cls) return "";
    jmethodID mid = getJNIClassStaticMethod(env, cls, "getLocalIpAddress", "()Ljava/lang/String;");
    if (!mid) return "";

    jhstring jhMenuItems = static_cast<jstring>(env->CallStaticObjectMethod(cls, mid));

    return rho_cast<rho::String>(env, jhMenuItems.get());


   //return res;
}


