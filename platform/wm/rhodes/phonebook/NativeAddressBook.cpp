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

#include "stdafx.h"

#include "ext/phonebook/phonebook.h" 
#include "NativeAddressBook.h"
#include "OutlookApp.h"
#include <common/RhoStd.h>

#define INITGUID
#include <pimstore.h>
#include <comutil.h>

using namespace rho;
using namespace rho::common;

IMPLEMENT_LOGCLASS(CABRecord,"ABRecord");
IMPLEMENT_LOGCLASS(CABOutlookRecord,"ABOutlookRecord");
IMPLEMENT_LOGCLASS(CABSimRecord,"ABSimRecord");
IMPLEMENT_LOGCLASS(CNativeAddressBook,"NativeAddressBook");

LPFN_SIM_DEINITIALIZE_T lpfn_sim_deinitialize;
LPFN_SIM_INITIALIZE_T lpfn_sim_initialize;
LPFN_SIM_READ_PHONEBOOK_ENTRY_T lpfn_sim_read_phonebook_entry;
LPFN_SIM_GET_DEV_CAPS_T lpfn_sim_get_dev_caps;

// Note that return type is std::string, not LPCSTR!!!
// It is required to get live object even after function exit
// In case if it is LPCSTR we actually get pointer to the
// dead object internal member
std::string bstr2str(BSTR s) {
	_bstr_t bstr(s);
	return (LPCSTR)bstr;
}

std::string& CABRecord::getValue(std::string field) {
	return m_props[field];
}

int CABRecord::setValue(std::string field,std::string value) {
	m_props[field] = value;
	return 1;
}

void CABRecord::enumValues(ab_callback_t proc,void* param) {
	std::map<std::string,std::string>::iterator it;
	for ( it = m_props.begin(); it != m_props.end(); it++ ) {
		(*proc)((*it).first.c_str(),(*it).second.c_str(),param);
	}
}

void CABRecord::dump() {
	LOG(INFO) + "Record dump ================================================";
	std::map<std::string,std::string>::iterator it;
	for ( it = m_props.begin(); it != m_props.end(); it++ ) {
		LOG(INFO) + "[" + (*it).first.c_str() + "] -> [" + (*it).second.c_str() + "]";
	}
	LOG(INFO) + "End of record dump =========================================";
}

//=============================================================================

CABOutlookRecord::CABOutlookRecord(IContact* pContact) :
m_pContact(pContact) {  
	m_type = eOutlookContact; 
	m_modifyed = false; 
}

CABOutlookRecord::~CABOutlookRecord() {
	if (m_pContact) {
		m_pContact->Release();
	}
}

int CABOutlookRecord::load() {
	if (m_pContact) {
		long oid;
		if(SUCCEEDED(m_pContact->get_Oid(&oid) ) ) {
			char buf[128];
			sprintf(buf,"{outlook %ld}",oid);
			setValue(RUBY_PB_ID,buf);
		}

		BSTR pwsz = NULL;
		if(SUCCEEDED(m_pContact->get_MobileTelephoneNumber(&pwsz) ) ) {
			if(pwsz[0]!=0) {
				std::string const &number = bstr2str(pwsz);
				setValue(RUBY_PB_MOBILE_NUMBER,number);
			}
			::SysFreeString( pwsz);
		}
		
		if(SUCCEEDED(m_pContact->get_HomeTelephoneNumber(&pwsz) ) ) {
			if(pwsz[0]!=0) {
				std::string const &number = bstr2str(pwsz);
				setValue(RUBY_PB_HOME_NUMBER,number);
			}
			::SysFreeString( pwsz);
		}	
		
		if(SUCCEEDED(m_pContact->get_BusinessTelephoneNumber(&pwsz) ) ) {
			if(pwsz[0]!=0) {
				std::string const &number = bstr2str(pwsz);
				setValue(RUBY_PB_BUSINESS_NUMBER,number);
			}
			::SysFreeString( pwsz);
		}

		if(SUCCEEDED(m_pContact->get_FirstName(&pwsz) ) ) {
			if(pwsz[0]!=0) {
				std::string const &name = bstr2str(pwsz);
				setValue(RUBY_PB_FIRST_NAME,name);
			}
			::SysFreeString(pwsz);
		}

		if(SUCCEEDED(m_pContact->get_LastName(&pwsz) ) ) {
			if(pwsz[0]!=0) {
				std::string const &name = bstr2str(pwsz);
				setValue(RUBY_PB_LAST_NAME,name);
			}
			::SysFreeString(pwsz);
		}

		if(SUCCEEDED(m_pContact->get_CompanyName(&pwsz) ) ) {
			if(pwsz[0]!=0) {
				std::string const &name = bstr2str(pwsz);
				setValue(RUBY_PB_COMPANY_NAME,name);
			}
			::SysFreeString(pwsz);
		}
		
		if(SUCCEEDED(m_pContact->get_Email1Address(&pwsz) ) ) {
			if(pwsz[0]!=0) {
				std::string const &address = bstr2str(pwsz);
				setValue(RUBY_PB_EMAIL_ADDRESS,address);
			}
			::SysFreeString(pwsz);
		}

	}
	return 1;
}

void CABOutlookRecord::saveValues() {
	const char* value = getValue(RUBY_PB_MOBILE_NUMBER).c_str();
	if (value!=NULL) {
		m_pContact->put_MobileTelephoneNumber(_bstr_t(value));
	}
	value = getValue(RUBY_PB_HOME_NUMBER).c_str();
	if (value!=NULL) {
		m_pContact->put_HomeTelephoneNumber(_bstr_t(value));
	}
	value = getValue(RUBY_PB_BUSINESS_NUMBER).c_str();
	if (value!=NULL) {
		m_pContact->put_BusinessTelephoneNumber(_bstr_t(value));
	}

	value = getValue(RUBY_PB_FIRST_NAME).c_str();
	if (value!=NULL) {
		m_pContact->put_FirstName(_bstr_t(value));
	}
	value = getValue(RUBY_PB_LAST_NAME).c_str();
	if (value!=NULL) {
		m_pContact->put_LastName(_bstr_t(value));
	}
	value = getValue(RUBY_PB_COMPANY_NAME).c_str();
	if (value!=NULL) {
		m_pContact->put_CompanyName(_bstr_t(value));
	}
	value = getValue(RUBY_PB_EMAIL_ADDRESS).c_str();
	if (value!=NULL) {
		m_pContact->put_Email1Address(_bstr_t(value));
	}
}

int CABOutlookRecord::save() {
	if (m_pContact) {
		saveValues();
		m_pContact->Save();
	}
	return 1;
}

int CABOutlookRecord::remove() {
	if (m_pContact) {
		m_pContact->Delete();
	}
	return 1;
}

//=============================================================================

CNativeAddressBook::CNativeAddressBook() :
    m_outlookItems(NULL), m_hSim(0) 
{
}

CNativeAddressBook::~CNativeAddressBook() 
{
	if(m_outlookItems) {
		m_outlookItems->Release();
	}

	if (m_hSim)
		closeSimAB();
}

int CNativeAddressBook::openAB() 
{
	initSimAB();

    COutlookApp* pApp = COutlookApp::Create();
	return pApp->getApp() != 0;
}

int CNativeAddressBook::getAllRecords(std::vector<CABRecord*>& records) {
	getAllSimPhonebookRecords(records);

	return getAllOutlookRecords(records);
}

CABRecord* CNativeAddressBook::getRecord(char* id) 
{
	char recordType[20];
	long recordId;
	if ( sscanf(id, "{%s %ld}", recordType, &recordId) == 2 ) {
		LOG(INFO) + "get Record " + recordId + " of " + recordType +" type";
		if (strcmp(recordType,"outlook")==0) {
			return getOutlookRecord(recordId);
		} else if (strcmp(recordType,"sim")==0) {
			return getSimRecord(recordId);
		}
	}
	return NULL;
}
	
int CNativeAddressBook::addRecord(CABRecord* record) {
	return addOutlookRecord((CABOutlookRecord*)record);
}

int CNativeAddressBook::deleteRecord(CABRecord* record) {
	return 1;
}

//=============================================================================

bool CNativeAddressBook::getOutlookItems() 
{
    IPOutlookApp* pApp = COutlookApp::getInstance()->getApp();
	if( (pApp!=NULL)&&(m_outlookItems==NULL)) 
    {
		//
		IFolder* polFolder;
		HRESULT res = pApp->GetDefaultFolder(olFolderContacts, &polFolder);
		if (res != S_OK) {
			// QueryInterface failed.
			LOG(ERROR) + "GetDefaultFolder failed.";
			return false;
		}

		res = polFolder->get_Items(&m_outlookItems);
		if (res != S_OK) {
			// QueryInterface failed.
			polFolder->Release();
			LOG(ERROR) + "get_Items failed.";
			return false;
		}

		polFolder->Release();
	}
	return true;
}

int CNativeAddressBook::getAllOutlookRecords(std::vector<CABRecord*>& records) 
{
    IPOutlookApp* pApp = COutlookApp::getInstance()->getApp();

	if(pApp && getOutlookItems()) 
    { 
		int size; 
		m_outlookItems->get_Count(&size);

		IContact * pContact;
		CABOutlookRecord *pRecord;
		for(int index = 1; index <= size; ++index) {
			m_outlookItems->Item(index, (IDispatch**)&pContact);
			pRecord = new CABOutlookRecord(pContact);
			if(pRecord) {
				pRecord->load();
				records.push_back(pRecord);
			} else {
				pContact->Release();
			}
		}
	}
	return 1;
}

CABRecord* CNativeAddressBook::getOutlookRecord(long oid) 
{
    IPOutlookApp* pApp = COutlookApp::getInstance()->getApp();

	if(pApp && getOutlookItems()) 
    { 
		DWORD index;
		HINSTANCE hPimStore = LoadLibrary(L"PIMSTORE.dll");
		typedef LRESULT (WINAPI* LPFN_GET_ITEM_INDEX_FROM_OID_T) (IPOutlookItemCollection*, CEOID, DWORD*);
		LPFN_GET_ITEM_INDEX_FROM_OID_T lpfn_getItemIndexFromOid = NULL;
		if (hPimStore)
			lpfn_getItemIndexFromOid = (LPFN_GET_ITEM_INDEX_FROM_OID_T)
				GetProcAddress(hPimStore, L"GetItemIndexFromOid");	
		if (hPimStore && lpfn_getItemIndexFromOid)
		{
			if(S_OK==lpfn_getItemIndexFromOid(m_outlookItems,oid,&index)) {
				IContact * pContact;
				CABOutlookRecord *pRecord;
				if (SUCCEEDED(m_outlookItems->Item(1+index, (IDispatch**)&pContact))) {
					pRecord = new CABOutlookRecord(pContact);
					if(pRecord) {
						pRecord->load();
						return pRecord;
					} else {
						pContact->Release();
					}
				}
			}
		}
		if (hPimStore)
			FreeLibrary(hPimStore);
	}
	return NULL;
}

int CNativeAddressBook::addOutlookRecord(CABOutlookRecord* record) 
{
    IPOutlookApp* pApp = COutlookApp::getInstance()->getApp();

	if(pApp && getOutlookItems()) 
    { 
		if(SUCCEEDED(m_outlookItems->Add((IDispatch**)&record->m_pContact))) {
			record->save();
		}
	}
	return 1;
}

BOOL CNativeAddressBook::LoadSimMgr()
{
	bool bReturnValue = FALSE;
	m_hSimMgrDLL = LoadLibrary(L"cellcore.dll");
	if (!m_hSimMgrDLL)
	{
		//  Error loading CellCore.dll (used for Connection Manager)
		LOG(INFO) + "Failed to load CellCore.dll, Sim functionality will not be available";
	}
	else
	{
		lpfn_sim_deinitialize = 
			(LPFN_SIM_DEINITIALIZE_T)GetProcAddress(m_hSimMgrDLL, _T("SimInitialize"));
		lpfn_sim_initialize = 
			(LPFN_SIM_INITIALIZE_T)GetProcAddress(m_hSimMgrDLL, _T("SimDeinitialize"));
		lpfn_sim_read_phonebook_entry = 
			(LPFN_SIM_READ_PHONEBOOK_ENTRY_T)GetProcAddress(m_hSimMgrDLL, _T("SimReadPhonebookEntry"));
		lpfn_sim_get_dev_caps = 
			(LPFN_SIM_GET_DEV_CAPS_T)GetProcAddress(m_hSimMgrDLL, _T("SimGetDevCaps"));

		if (!lpfn_sim_deinitialize)
		{
			LOG(ERROR) + "Unable to load SimDeinitialize";
			bReturnValue = FALSE;
		}
		else if (!lpfn_sim_initialize)
		{
			LOG(ERROR) + "Unable to load SimInitialize";
		}
		else
			bReturnValue = TRUE;
	}
	return bReturnValue;
}

bool CNativeAddressBook::initSimAB()
{
	if(!LoadSimMgr()) 
	{
		LOG(INFO)  + "SimMgr is not found";
		return false;;
	}
	
	HRESULT h = lpfn_sim_initialize(0, NULL, 0, &m_hSim);
	if (SUCCEEDED(h))
	{
		if (SUCCEEDED(lpfn_sim_get_dev_caps(m_hSim, SIM_CAPSTYPE_ALL, &m_SimCaps))) 
		{
				return true;				
		}
		LOG(ERROR) + "Failed to get SIM capabilities.";
		lpfn_sim_deinitialize(m_hSim);
		m_hSim = NULL;
	}
	LOG(ERROR) + "Failed to init SIM. Error=" + (int)h;

	return false;
}

bool CNativeAddressBook::closeSimAB()
{
	lpfn_sim_deinitialize(m_hSim);
	return false;
}

CABRecord* CNativeAddressBook::getSimRecord(int id)
{
	CABSimRecord *pRecord;
	HRESULT hr = 0;

	pRecord = new CABSimRecord(id, m_hSim);

	if(pRecord) {
		if (SUCCEEDED(hr = pRecord->load())) {
			return pRecord;
		} else {
			if (SIM_E_NOTFOUND)
				LOG(ERROR) + "Failed to get SIM entry";
		}
	} else {
		LOG(ERROR) + "No more memory";
	}
	return NULL;
}

int CNativeAddressBook::getAllSimPhonebookRecords(std::vector<CABRecord*>& records)
{
	CABSimRecord *pRecord;
	HRESULT hr = 0;

	for(DWORD i = m_SimCaps.dwMinPBIndex; i <= m_SimCaps.dwMaxPBIndex; i++) {
		pRecord = new CABSimRecord(i, m_hSim);
		if(pRecord) {
			if (SUCCEEDED(hr = pRecord->load()))
				records.push_back(pRecord);
			else {
				if (SIM_E_NOTFOUND)
					break;
				LOG(ERROR) + "Failed to get SIM entry";
			}
		} else {
			LOG(ERROR) + "No more memory";
		}
	}

	
	return SUCCEEDED(hr) ? 1 : 0;
}

CABSimRecord::CABSimRecord(int index, HSIM hSim)
{
	m_hSim = hSim;
	m_index = index;
}

CABSimRecord::~CABSimRecord()
{
}

int CABSimRecord::load()
{
	SIMPHONEBOOKENTRY entry;
	
	String name, address;
	HRESULT hr = lpfn_sim_read_phonebook_entry(m_hSim, SIM_PBSTORAGE_SIM, m_index, &entry);
	if (SUCCEEDED(hr))
	{
		char buf[128];
		sprintf(buf,"{sim %ld}", m_index);
		setValue(RUBY_PB_ID,buf);

		setValue(RUBY_PB_FIRST_NAME, convertToStringA(entry.lpszText));
		setValue(RUBY_PB_MAIN_MUMBER, convertToStringA(entry.lpszAddress));
	}

	return hr;
}

int CABSimRecord::save()
{
	return 0;
}

int CABSimRecord::remove()
{
	return 0;
}

void CABSimRecord::saveValues()
{
}