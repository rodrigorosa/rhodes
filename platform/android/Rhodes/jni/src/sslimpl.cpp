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

#include "rhodes/sslimpl.h"
#include "rhodes/JNIRhodes.h"

#include "rhodes/jni/com_rhomobile_rhodes_socket_SSLImpl.h"

#include <arpa/inet.h>

#include <cstring>

#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "SSLImpl"

RHO_GLOBAL jobject JNICALL Java_com_rhomobile_rhodes_socket_SSLImpl_getRemoteSockAddr
  (JNIEnv *env, jobject, jint sock)
{
    jclass clsSockAddr = getJNIClass(RHODES_JAVA_CLASS_RHOSOCKADDR);
    if (!clsSockAddr) return NULL;
    jclass clsInetAddr = getJNIClass(RHODES_JAVA_CLASS_INETADDRESS);
    if (!clsInetAddr) return NULL;
    jmethodID midSockAddr = getJNIClassMethod(env, clsSockAddr, "<init>", "()V");
    if (!midSockAddr) return NULL;
    jmethodID midInetAddr = getJNIClassStaticMethod(env, clsInetAddr, "getByAddress", "(Ljava/lang/String;[B)Ljava/net/InetAddress;");
    if (!midInetAddr) return NULL;
    jfieldID fidInetAddr = getJNIClassField(env, clsSockAddr, "host", "Ljava/net/InetAddress;");
    if (!fidInetAddr) return NULL;
    jfieldID fidPort = getJNIClassField(env, clsSockAddr, "port", "I");
    if (!fidPort) return NULL;

    jholder<jbyteArray> array = jholder<jbyteArray>(env->NewByteArray(4));
    if (!array) return NULL;
    jbyte *arr = env->GetByteArrayElements(array.get(), NULL);
    if (!arr) return NULL;

    sockaddr_in sa;
    socklen_t salen = sizeof(sa);
    int e = ::getpeername(sock, (sockaddr*)&sa, &salen);
    if (e == -1) {
      RAWLOG_ERROR1("getpeername failed: %d", errno);
      return NULL;
    }
    uint32_t addr = ntohl(sa.sin_addr.s_addr);
    arr[3] = (jbyte)(addr & 0xFF);
    addr >>= 8;
    arr[2] = (jbyte)(addr & 0xFF);
    addr >>= 8;
    arr[1] = (jbyte)(addr & 0xFF);
    addr >>= 8;
    arr[0] = (jbyte)(addr & 0xFF);
    env->ReleaseByteArrayElements(array.get(), arr, 0);

    jhstring ipaddrObj = rho_cast<jstring>(env, ::inet_ntoa(sa.sin_addr));
    jhobject inetaddrObj = env->CallStaticObjectMethod(clsInetAddr, midInetAddr, ipaddrObj.get(), array.get() );
    if (!inetaddrObj) return NULL;

    jhobject sockaddrObj = env->NewObject(clsSockAddr, midSockAddr);
    if (!sockaddrObj) return NULL;

    env->SetObjectField(sockaddrObj.get(), fidInetAddr, inetaddrObj.get());
    env->SetIntField(sockaddrObj.get(), fidPort, ntohs(sa.sin_port));

    return sockaddrObj.release();
}

namespace rho
{
namespace net
{

SSLImpl::SSLImpl()
{
    JNIEnv *env = jnienv();
    if (!env) {
       return;
    }
    cls = getJNIClass(RHODES_JAVA_CLASS_SSLIMPL);
    if (!cls) return;
    midConstructor = getJNIClassMethod(env, cls, "<init>", "()V");
    if (!midConstructor) return;
    midConnect = getJNIClassMethod(env, cls, "connect", "(IZLjava/lang/String;)Z");
    if (!midConnect) return;
    midShutdown = getJNIClassMethod(env, cls, "shutdown", "()V");
    if (!midShutdown) return;
    midSend = getJNIClassMethod(env, cls, "send", "([B)Z");
    if (!midSend) return;
    midRecv = getJNIClassMethod(env, cls, "recv", "([B)I");
    if (!midRecv) return;
}

void* SSLImpl::createStorage()
{
    JNIEnv *env = jnienv();
    jobject obj = env->NewObject(cls, midConstructor);
    jobject objG = env->NewGlobalRef(obj);
    env->DeleteLocalRef(obj);
    return objG;
}

void SSLImpl::freeStorage(void *ptr)
{
    if (!ptr) return;
    jobject obj = (jobject)ptr;
    jnienv()->DeleteGlobalRef(obj);
}

CURLcode SSLImpl::connect(int sockfd, int nonblocking, int *done, int ssl_verify_peer, void *storage, char* host_name)
{
    if (!storage) return CURLE_SSL_CONNECT_ERROR;

    jobject obj = (jobject)storage;

    JNIEnv* env = jnienv();
    jhstring jHostname = rho_cast<jstring>(env, host_name);


    jboolean result = jnienv()->CallBooleanMethod(obj, midConnect, sockfd, (jboolean)ssl_verify_peer, (jstring)jHostname.get());
    if (!result)
        return CURLE_SSL_CONNECT_ERROR;

    *done = 1;
    return CURLE_OK;
}

void SSLImpl::shutdown(void *storage)
{
    if (!storage) return;

    RAWTRACE("shutdown");

    jobject obj = (jobject)storage;
    jnienv()->CallVoidMethod(obj, midShutdown);
}

ssize_t SSLImpl::send(const void *mem, size_t len, void *storage)
{
    if (!storage) return -1;

    JNIEnv *env = jnienv();
    jholder<jbyteArray> array = jholder<jbyteArray>(env->NewByteArray(len));
    if (!array) return -1;
    jbyte *arr = env->GetByteArrayElements(array.get(), NULL);
    if (!arr) return -1;
    std::memmove(arr, mem, len);
    env->ReleaseByteArrayElements(array.get(), arr, 0);

    jobject obj = (jobject)storage;
    jboolean result = env->CallBooleanMethod(obj, midSend, array.get());
    if (!result) return -1;
    return len;
}

ssize_t SSLImpl::recv(char *buf, size_t size, int *wouldblock, void *storage)
{
    *wouldblock = 0;
    if (!storage) return -1;

    jobject obj = (jobject)storage;
    JNIEnv *env = jnienv();

    static jfieldID fid = 0;
    if(!fid)
    {
        jclass clsSock = getJNIObjectClass(env, obj);
        if (!clsSock) return -1;

        fid = getJNIClassField(env, clsSock, "sockfd", "I");

        env->DeleteLocalRef(clsSock);
    }
    if (!fid) return -1;

    jint sock = env->GetIntField(obj, fid);

    fd_set rfd;
    FD_ZERO(&rfd);
    FD_SET(sock, &rfd);
    timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 0;
    int n = ::select(sock + 1, &rfd, NULL, NULL, &tv);
    if (n == 0) {
        *wouldblock = 1;
        return -1;
    }

    jholder<jbyteArray> array = env->NewByteArray(size);
    jint result = env->CallIntMethod(obj, midRecv, array.get());

    if (result > 0) {
        jbyte *arr = env->GetByteArrayElements(array.get(), NULL);
        if (!arr) return -1;
        std::memmove(buf, arr, result);
        env->ReleaseByteArrayElements(array.get(), arr, JNI_ABORT);
    }
    return result;
}

} // namespace net
} // namespace rho

