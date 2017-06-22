/*------------------------------------------------------------------------
* (The MIT License)
*
* Copyright (c) 2008-2012 Rhomobile, Inc.
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

#ifndef GCMPUSHCLIENT_H_
#define GCMPUSHCLIENT_H_

//#include "common/push/IRhoPushClient.h"
#include "Push.h"

#include "logging/RhoLog.h"
#include "common/RhoStd.h"


namespace rho { namespace gcm {

using namespace rho::common;

class GcmPushClient: public push::CPushClient
{
    class SyncLoginListener;
private:
    static const char* const s_GCM_FACADE_CLASS;
    static const String s_Type;
    CMethodResult m_oResult;
    CMethodResult m_deviceIdResult;

public:
    DEFINE_LOGCLASS;

    GcmPushClient();
    virtual ~GcmPushClient() {}

    virtual const String& getId() const { return s_Type; }
    virtual void setDeviceId(const String& deviceId);
    virtual void getDeviceId(CMethodResult& result);
    virtual void startNotifications(CMethodResult& result);
    virtual void stopNotifications(CMethodResult& result);
    virtual bool callBack(const String& json);

    void doRegister();
    void doUnregister();
};


}}

#endif /* GCMPUSHCLIENT_H_ */
