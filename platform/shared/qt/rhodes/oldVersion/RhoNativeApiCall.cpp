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

#include "RhoNativeApiCall.h"
#include "logging/RhoLog.h"
#include "net/URI.h"
#include "api_generator/js_helpers.h"

void RhoNativeApiCall::populateJavaScriptWindowObject()
{
    m_frame->addToJavaScriptWindowObject("__rhoNativeApi", this);
}

const QString RhoNativeApiCall::apiCall(const QString& msg)
{
    //RAWLOGC_INFO1("RhoNativeApiCall", "JS API call: %s", msg.toStdString().c_str());
    const QByteArray asc = msg.toLatin1();  
    rho::String res = rho::apiGenerator::js_entry_point( std::string(asc.constData(), asc.length()).c_str() );
    return QString(res.c_str());
    // how to return JS-object instance: (QVariant) return m_frame->evaluateJavascript("__rhoNativeApi;");
}

const QString RhoNativeApiCall::toLowerCase(const QString& msg)
{
    return msg.toLower();
}
