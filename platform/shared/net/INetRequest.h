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

#pragma once

#include "common/RhoStd.h"
#include "common/InputStream.h"
#include "common/AutoPointer.h"
#include "common/RhoMutexLock.h"
#include "common/RhoTime.h"

namespace rho {
namespace common {
class CRhoFile;
}

namespace net {

struct INetResponse
{
    virtual ~INetResponse(void){;}
    virtual const char* getCharData() = 0;
    virtual unsigned int getDataSize() = 0;
    virtual int getRespCode() = 0;
    virtual String getCookies() = 0;
    virtual String getErrorMessage() = 0;

    virtual void setCharData(const char* szData) = 0;
};

struct IRhoSession
{
	virtual void logout()=0;
	virtual const String& getSession()=0;
    virtual const String& getContentType()=0;
};

struct CMultipartItem
{
    //mutually exclusive
    String m_strFilePath;
    String m_strBody;
    //

    String m_strName, m_strFileName, m_strContentType;

    String m_strDataPrefix;
};

class INetRequestCallback;

struct INetRequestImpl
{
    virtual ~INetRequestImpl(void){;}

    virtual INetResponse* doRequest( const char* method, const String& strUrl, const String& strBody, IRhoSession* oSession, Hashtable<String,String>* pHeaders )=0;
    virtual INetResponse* pullFile(const String& strUrl, common::CRhoFile& oFile, IRhoSession* oSession, Hashtable<String,String>* pHeaders)=0;
    virtual INetResponse* pushMultipartData(const String& strUrl, VectorPtr<CMultipartItem*>& arItems, IRhoSession* oSession, Hashtable<String,String>* pHeaders)=0;

    virtual void cancel() = 0;

    virtual boolean getSslVerifyPeer() = 0;
    virtual void setSslVerifyPeer(boolean mode) = 0;

    virtual INetResponse* createEmptyNetResponse() = 0;
    
    virtual void setCallback(INetRequestCallback*) = 0;
};

typedef rho::common::CAutoPtr<rho::net::INetResponse> NetResponsePtr;

class CNetResponseWrapper
{
    NetResponsePtr m_netResp;
public:
    CNetResponseWrapper( INetResponse* resp = 0) : m_netResp(resp)  {}

    const char* getCharData(){ return m_netResp->getCharData(); }
    void setCharData(const char* szData){ return m_netResp->setCharData(szData); }
    unsigned int getDataSize(){ return m_netResp->getDataSize(); }
    int getRespCode(){ return m_netResp->getRespCode(); }
    String getCookies(){ return m_netResp->getCookies(); }
    String getErrorMessage() { return m_netResp->getErrorMessage(); }

	boolean isOK()
	{
		return getRespCode() == 200 || getRespCode() == 206;
	}

    boolean isUnathorized()
    {
        return getRespCode() == 401;
    }

    boolean isRedirect()
    {
       return getRespCode() == 301 || getRespCode() ==302;
    }

    boolean isSuccess()
    {
        return getRespCode() > 0 && getRespCode() < 400;
    }

    boolean isResponseRecieved(){ return getRespCode() != -1; }
};

class CNetRequestHolder
{
    common::CMutex m_mxReq;
    INetRequestImpl*   m_pReq;
    boolean        m_bCancel;
    boolean        m_sslVerifyPeer;

public:

    CNetRequestHolder() : m_pReq(0), m_bCancel(false), m_sslVerifyPeer(true){}

    void setRequest(INetRequestImpl* pReq);
    void cancel();
    boolean isCancelled();
    static String resolveUrl(const String& strUrl);

    boolean getSslVerifyPeer() {return m_sslVerifyPeer;}
    void setSslVerifyPeer(boolean mode) {m_sslVerifyPeer = mode;}
    
    bool isInsideRequest() const;
};

class CNetRequestWrapper
{
    common::CAutoPtr<INetRequestImpl>  m_pReqImpl;
    CNetRequestHolder*                 m_pHolder;
public:
    CNetRequestWrapper(INetRequestImpl* pImpl, CNetRequestHolder* pHolder);
    ~CNetRequestWrapper();

    rho::net::CNetResponseWrapper pullData(const String& strUrl, IRhoSession* oSession );
    rho::net::CNetResponseWrapper pushData(const String& strUrl, const String& strBody, IRhoSession* oSession);
    rho::net::CNetResponseWrapper pullCookies(const String& strUrl, const String& strBody, IRhoSession* oSession);
    rho::net::CNetResponseWrapper doRequest( const char* method, const String& strUrl, const String& strBody, IRhoSession* oSession, Hashtable<String,String>* pHeaders );
    rho::net::CNetResponseWrapper pushMultipartData(const String& strUrl, VectorPtr<CMultipartItem*>& arItems, IRhoSession* oSession, Hashtable<String,String>* pHeaders);
    rho::net::CNetResponseWrapper pushMultipartData(const String& strUrl, CMultipartItem& oItem, IRhoSession* oSession, Hashtable<String,String>* pHeaders);
    rho::net::CNetResponseWrapper pullFile(const String& strUrl, const String& strFilePath, IRhoSession* oSession, Hashtable<String,String>* pHeaders,bool overwriteFile,bool createFolders, bool* pFileExistsFlag = 0 );

    String resolveUrl(const String& strUrl);
    void cancel();
    
    void setCallback(INetRequestCallback*);

};



}
}

typedef rho::net::CNetResponseWrapper NetResponse;
typedef rho::net::CNetRequestHolder NetRequest;

rho::net::CNetRequestWrapper getNetRequest(rho::net::CNetRequestHolder* pHolder = 0);

namespace rho
{

namespace common
{
    class CRhoThread;
}

namespace net
{

class INetRequestCallback
{
  public:
    virtual ~INetRequestCallback() {}

    virtual void didReceiveResponse(NetResponse&, const Hashtable<String,String>* headers) = 0;
    virtual void didReceiveData(const char*, int) = 0;
    virtual void didFinishLoading() = 0;
    virtual void didFail(NetResponse&) = 0;

};

class CAsyncNetRequest : public INetRequestCallback, private common::CRhoTimer::ICallback
{

private:
  String m_method;
  String m_url;
  String m_body;
  net::IRhoSession* m_pSession;
  Hashtable<String,String> m_headers;
  INetRequestCallback* m_pCallback;

  /*net::CNetRequestWrapper*/NetRequest  m_request;

  common::CMutex m_mxCallbackAccess;

public:

  CAsyncNetRequest()
    : m_pSession(0)
    , m_pCallback(0)
    //, m_request(::getNetRequest())
  {
  }

  ~CAsyncNetRequest();
  
  void setMethod(const String& method) { m_method = method; }
  void setUrl(const String& url) { m_url = url; }
  void setBody(const String& body) { m_body = body; }
  void setSession( IRhoSession* pSession ) { m_pSession = pSession; }
  void setCallback( INetRequestCallback* pCallback )
  { 
    synchronized(m_mxCallbackAccess)
    {
      m_pCallback = pCallback; 
    }
  }
  void setHeaders( const Hashtable<String, String> headers ) { m_headers = headers; }

  void run(common::CRhoThread &);
  void cancel();
  void requestCancel(); //will perform cancel in timer thread

  virtual void didReceiveResponse(NetResponse& resp, const Hashtable<String,String>* headers);
  virtual void didReceiveData(const char* ptr, int len);
  virtual void didFinishLoading();
  virtual void didFail(NetResponse& resp);

private:
  virtual bool onTimer();

};

}
}


