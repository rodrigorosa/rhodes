/*------------------------------------------------------------------------
* (The MIT License)
* 
* Copyright (c) 2008-2011 Rhomobile, Inc.
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
* 
* http://rhomobile.com
*------------------------------------------------------------------------*/

#include "rhodes/JNIRhodes.h"

#include "rhodes/jni/com_rhomobile_rhodes_RhoLogConf.h"

#include <logging/RhoLogConf.h>

RHO_GLOBAL jstring JNICALL Java_com_rhomobile_rhodes_RhoLogConf_getEnabledCategories
  (JNIEnv *env, jclass)
{
    return rho_cast<jstring>(env, LOGCONF().getEnabledCategories().c_str());
}

RHO_GLOBAL void JNICALL Java_com_rhomobile_rhodes_RhoLogConf_setEnabledCategories
  (JNIEnv *env, jclass, jstring value)
{
    if (value == NULL)
        return;
    LOGCONF().setEnabledCategories(rho_cast<std::string>(env, value).c_str());
}

RHO_GLOBAL jstring JNICALL Java_com_rhomobile_rhodes_RhoLogConf_getDisabledCategories
  (JNIEnv *env, jclass)
{
    return rho_cast<jstring>(env, LOGCONF().getDisabledCategories().c_str());
}

RHO_GLOBAL void JNICALL Java_com_rhomobile_rhodes_RhoLogConf_setDisabledCategories
  (JNIEnv *env, jclass, jstring value)
{
    if (value == NULL)
        return;
    LOGCONF().setDisabledCategories(rho_cast<std::string>(env, value).c_str());
}

RHO_GLOBAL jint JNICALL Java_com_rhomobile_rhodes_RhoLogConf_getMinSeverity
  (JNIEnv *, jclass)
{
    return LOGCONF().getMinSeverity();
}

RHO_GLOBAL void JNICALL Java_com_rhomobile_rhodes_RhoLogConf_setMinSeverity
  (JNIEnv *, jclass, jint severity)
{
    LOGCONF().setMinSeverity(severity);
}

RHO_GLOBAL void JNICALL Java_com_rhomobile_rhodes_RhoLogConf_saveToFile
  (JNIEnv *, jclass)
{
    LOGCONF().saveToFile();
}

RHO_GLOBAL void JNICALL Java_com_rhomobile_rhodes_RhoLogConf_clearLog
  (JNIEnv *, jclass)
{
    LOGCONF().clearLog();
}

RHO_GLOBAL jstring JNICALL Java_com_rhomobile_rhodes_RhoLogConf_getLogText
  (JNIEnv *env, jclass)
{
    rho::String logText;
    LOGCONF().getLogText(logText);
    return rho_cast<jstring>(env, logText.c_str());
}

RHO_GLOBAL jint JNICALL Java_com_rhomobile_rhodes_RhoLogConf_getLogTextPos
  (JNIEnv *, jclass)
{
    return LOGCONF().getLogTextPos();
}

RHO_GLOBAL jstring JNICALL Java_com_rhomobile_rhodes_RhoLogConf_getLogFileText
  (JNIEnv * env, jclass , jint linearPos, jint maxSize, jint referenceCircularPos)
{
    rho::String strRes;
    LOGCONF().getLogFileText(rho_cast<int>(env, linearPos), rho_cast<int>(env, maxSize), strRes, rho_cast<int>(env, referenceCircularPos));

    return rho_cast<jstring>(env, strRes);
}

RHO_GLOBAL jint JNICALL Java_com_rhomobile_rhodes_RhoLogConf_getLogFileSize
  (JNIEnv *, jclass)
{
    return LOGCONF().getLogFileSize();
}

RHO_GLOBAL void JNICALL Java_com_rhomobile_rhodes_RhoLogConf_sendLog
  (JNIEnv *, jclass)
{
    rho_conf_send_log("");
}

RHO_GLOBAL jboolean JNICALL Java_com_rhomobile_rhodes_RhoLogConf_hasLogView
  (JNIEnv *, jclass)
{
    return LOGCONF().hasLogView();
}
