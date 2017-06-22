/*
#-------------------------------------------------------------------------------
# (The MIT License)
#
# Copyright (c) 2013 Rhomobile, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# http://rhomobile.com
#-------------------------------------------------------------------------------
*/

#include "Push.h"
#include "common/RhoStd.h"
#include "logging/RhoLog.h"
#include "sync/RhoconnectClientManager.h"

namespace rho {
namespace push {

//----------------------------------------------------------------------------------------------------------------------
CPushManager* CPushManager::getInstance()
{
    return reinterpret_cast<CPushManager*>(CPushFactoryBase::getInstance()->getModuleSingleton());
}

//----------------------------------------------------------------------------------------------------------------------
class CPushSingleton: public CPushManager, public CPushFactoryBase {
    VectorPtr<CPushClient*> m_clients;
    DEFINE_LOGCLASS;
public:
    virtual ~CPushSingleton()
    {
        m_pInstance.ReleasePtr();
    }
    String getInitialDefaultID();
    void enumerate(rho::apiGenerator::CMethodResult& oResult);
    void addClient(CPushClient* pClient)
    {
        m_clients.addElement(pClient);
        LOG(INFO) + "New push client has added: " + pClient->getId();
    }
    void setDeviceId(const String& id, const String& deviceId);
    void callBack(const String& id, const String& json);

    IPushSingleton* createModuleSingleton()
    {
        return this;
    }
    CPushClient* getClient(const String& strID);
    IPush* getModuleByID(const String& strID) { return getClient(strID); }

};

//----------------------------------------------------------------------------------------------------------------------
IMPLEMENT_LOGCLASS(CPushSingleton, "CPushSingleton");

//----------------------------------------------------------------------------------------------------------------------
String CPushSingleton::getInitialDefaultID()
{
    if (m_clients.empty())
    {
        return "";
    }
    else
    {
        return m_clients.front()->getId();
    }
}

//----------------------------------------------------------------------------------------------------------------------
void CPushSingleton::enumerate(rho::apiGenerator::CMethodResult& oResult)
{
    Vector<String> ids;
    for(VectorPtr<CPushClient*>::const_iterator it = m_clients.begin(); it != m_clients.end(); ++it)
    {
        ids.push_back((*it)->getId());
    }
    oResult.set(ids);
}

//----------------------------------------------------------------------------------------------------------------------
void CPushSingleton::setDeviceId(const String& id, const String& deviceId)
{
    CPushClient* pClient = getClient(id);
    if(pClient == 0)
    {
        LOG(ERROR) + "CPushSingleton::setDeviceId: Unknown push client: " + id;
    }
    else
    {
        if(rho::sync::RhoconnectClientManager::haveRhoconnectClientImpl())
        {
            rho::sync::RhoconnectClientManager::clientRegisterCreate(deviceId.c_str());
        }
        pClient->setDeviceId(deviceId);
    }
}

//----------------------------------------------------------------------------------------------------------------------
void CPushSingleton::callBack(const String& id, const String& json)
{
    CPushClient* pClient = getClient(id);
    if(pClient == 0)
    {
        LOG(ERROR) + "CPushSingleton::callBack: Unknown push client: " + id;
    }
    else
    {
        pClient->callBack(json);
    }
}

//----------------------------------------------------------------------------------------------------------------------
CPushClient* CPushSingleton::getClient(const rho::String& id)
{
    LOG(TRACE) + "Looking for push client: " + id;
    for(VectorPtr<CPushClient*>::iterator it = m_clients.begin(); it != m_clients.end(); ++it)
    {
        const String& curId = (*it)->getId();

        LOG(TRACE) + "Push client: " + curId;

        if(curId == id)
        {
            LOG(TRACE) + "Returning push client: " + curId;
            return *it;
        }
    }
    LOG(TRACE) + "Push client has not found";
    return 0;
}

//----------------------------------------------------------------------------------------------------------------------

}}

extern "C" void Init_Push()
{
    RAWTRACEC("Init_Push", "Creating CPushSingleton...");
    rho::CPushFactoryBase::setInstance( new rho::push::CPushSingleton() );
    rho::Init_Push_API();
}
//----------------------------------------------------------------------------------------------------------------------
