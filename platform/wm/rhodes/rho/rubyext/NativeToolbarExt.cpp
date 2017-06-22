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

#include "MainWindow.h"
#include "rubyext/NativeToolbarExt.h"

extern CMainWindow& getAppWindow();

#if 0

extern "C"
{
int rho_wmsys_has_touchscreen();
void remove_native_toolbar();
void create_native_toolbar(int bar_type, rho_param *p) 
{
    if ( bar_type == NOBAR_TYPE )
        remove_native_toolbar();
    else if ( bar_type == TOOLBAR_TYPE )
    {
        getAppWindow().performOnUiThread(new CNativeToolbar::CCreateTask(p) );
    }else
    {
    	RAWLOGC_ERROR("NativeBar", "Only Toolbar control is supported.");
    }
}

void create_nativebar(int bar_type, rho_param *p) 
{
	RAWLOGC_INFO("NativeBar", "NativeBar.create() is DEPRECATED. Use Rho::NativeToolbar.create() or Rho::NativeTabbar.create().");
    create_native_toolbar(bar_type, p);
}

void remove_native_toolbar() 
{
    getAppWindow().performOnUiThread(new CNativeToolbar::CRemoveTask() );
}

void remove_nativebar() 
{
	RAWLOGC_INFO("NativeBar", "NativeBar.remove() is DEPRECATED API ! Please use Rho::NativeToolbar.remove() or Rho::NativeTabbar.remove().");
	remove_native_toolbar();
}

VALUE nativebar_started() 
{
    bool bStarted = CNativeToolbar::getInstance().isStarted();
    return rho_ruby_create_boolean(bStarted?1:0);
}

//Tabbar
void remove_native_tabbar()
{
}

void create_native_tabbar(int bar_type, rho_param *p)
{
}

void native_tabbar_switch_tab(int index)
{
}

void native_tabbar_set_tab_badge(int index,char *val)
{
}

void nativebar_set_tab_badge(int index,char* val)
{
	RAWLOGC_INFO("NativeBar", "NativeBar.set_tab_badge() is DEPRECATED. Use Rho::NativeTabbar.set_tab_badge().");
    native_tabbar_set_tab_badge(index, val);
}

int native_tabbar_get_current_tab() 
{
	return 0;
}

void nativebar_switch_tab(int index)
{
	RAWLOGC_INFO("NativeBar", "NativeBar.switch_tab() is DEPRECATED. Use Rho::NativeTabbar.switch_tab().");
	native_tabbar_switch_tab(index);
}

//NavBar - iphone only
void create_navbar(rho_param *p)
{
}

void remove_navbar()
{
}

VALUE navbar_started()
{
    return rho_ruby_create_boolean(0);
}

}
#endif
/////////////////////////
//Common API Support

bool rho_wmimpl_toolbar_isStarted()
{
    return CNativeToolbar::getInstance().isStarted();
}

void rho_wmimpl_toolbar_create( const rho::Vector<rho::String>& toolbarElements,  const rho::Hashtable<rho::String, rho::String>& toolBarProperties)
{
    CNativeToolbar::getInstance().createToolbarEx(toolbarElements, toolBarProperties);
}

void rho_wmimpl_toolbar_remove()
{
    CNativeToolbar::getInstance().removeToolbar();
}

//Tabbar
bool rho_wmimpl_tabbar_isStarted()
{
#ifdef OS_WINCE
    return getAppWindow().getTabbar().IsTabBarStarted();
#else
    return getAppWindow().isStarted();
#endif
}

void rho_wmimpl_tabbar_create( const rho::Vector<rho::String>& tabbarElements,  const rho::Hashtable<rho::String, rho::String>& tabBarProperties, rho::apiGenerator::CMethodResult& oResult)
{
#ifdef OS_WINCE
    getAppWindow().getTabbar().CreateTabbarEx(tabbarElements, tabBarProperties, oResult);
#else
    getAppWindow().createTabbarEx(tabbarElements, tabBarProperties, oResult);
#endif
}

void rho_wmimpl_tabbar_remove()
{
#ifdef OS_WINCE
    getAppWindow().getTabbar().RemoveTabbar();
#else
    getAppWindow().removeTabbar();
#endif
}

void rho_wmimpl_tabbar_removeTab(int tabIndex)
{
#ifdef OS_WINCE
    getAppWindow().getTabbar().RemoveTab(tabIndex);
#else
#endif
}

int rho_wmimpl_tabbar_currentTabIndex()
{
#ifdef OS_WINCE
    return getAppWindow().getTabbar().GetCurrentTabIndex();
#else
    return getAppWindow().tabbarGetCurrent();
#endif
}

void rho_wmimpl_tabbar_switchTab(int tabIndex)
{
#ifdef OS_WINCE
    getAppWindow().getTabbar().SwitchTab(tabIndex);
#else
    getAppWindow().tabbarSwitch(tabIndex);
#endif
}

void rho_wmimpl_tabbar_setTabBadge(int tabIndex,  const rho::String& badge)
{
#ifdef OS_WINCE
    getAppWindow().getTabbar().SetBadge(tabIndex, badge.c_str());
#else
    getAppWindow().tabbarBadge(tabIndex, badge.c_str());
#endif

}
