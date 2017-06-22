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

#include <common/RhodesApp.h>
#include <logging/RhoLogConf.h>

/*
#include "Win32Graphics.h"

#ifdef OS_WINCE
#include <initguid.h>
#include <imgguids.h>
#endif //OS_WINCE

extern "C" HWND getMainWnd();
extern "C" void msg_out(const char* text);
extern "C" void err_out(const char* text);

#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "WM MapView Graphics (Win32)"

#define IP_PORTION_COUNT 32 


Win32DrawingImageImpl::Win32DrawingImageImpl(void const *p, int size, bool useAlpha) {
	RHO_MAP_TRACE1("create DrawingImage with buffer length = %d", size);
	init(NULL, p, size, NULL, useAlpha);
}

Win32DrawingImageImpl::Win32DrawingImageImpl(const char* path, bool useAlpha) {
	RHO_MAP_TRACE1("create DrawingImage with filename = %s", path);
	init(path, NULL, 0, NULL, useAlpha);
}

Win32DrawingImageImpl::Win32DrawingImageImpl(WMBitmap* bitmap) {
	init(NULL, NULL, 0, bitmap, false);	
}


static int ourDrawingImageID = 0;

Win32DrawingImageImpl::~Win32DrawingImageImpl() 
{
	RHO_MAP_TRACE1("DrawingImage destroy with ID = %d", mID);
	if (mBitmap != NULL) {
		mBitmap->release();
		mBitmap = NULL;
	}
}

void Win32DrawingImageImpl::init(const char* path, void const *p, int size, WMBitmap* bitmap, bool useAlpha)
{
	mID = ++ourDrawingImageID;
	RHO_MAP_TRACE1("DrawingImage create with ID = %d", mID);

#if defined(_WIN32_WCE)
	IImagingFactory *pImgFactory = NULL;
	IImage *pImage = NULL;

	mWidth = 0;
	mHeight = 0;
	mBitmap = NULL;

	if (bitmap != NULL) {
		mBitmap = bitmap;
		mBitmap->addRef();
		mWidth = bitmap->width();
		mHeight = bitmap->height();
		return;
	}

	HRESULT co_init_result = CoInitializeEx(NULL, 0/*COINIT_APARTMENTTHREADED);
	if ( (co_init_result == S_OK) || (co_init_result == S_FALSE)  ) {
		msg_out("CoInitializeEx OK");
		if (SUCCEEDED(CoCreateInstance (CLSID_ImagingFactory,
			NULL,
			CLSCTX_INPROC_SERVER,
			IID_IImagingFactory,
			(void **)&pImgFactory)))
		{
			HRESULT res = 0;
			if (p != NULL) {
				// from buf
				res = pImgFactory->CreateImageFromBuffer(
															p,
															size,
															BufferDisposalFlagNone,
															&pImage);
			}
			else {
				// from file
				msg_out("Create Image Factory OK");
				wchar_t wc_filename[2048];
				mbstowcs(wc_filename, path, 2048);
				res = pImgFactory->CreateImageFromFile(
														wc_filename,
														&pImage);
			}
			if (SUCCEEDED(res))
			{
				IImage* mimage = pImage;
				ImageInfo imgInfo;
				mimage->GetImageInfo(&imgInfo);
				mWidth = imgInfo.Width;
				mHeight = imgInfo.Height;
				RHO_MAP_TRACE2("Drawing Image was created with WIDTH = %d, HEIGHT = %d", mWidth, mHeight);
				mBitmap = new WMBitmap(mimage, useAlpha);
				mimage->Release();
			}
			else {
				err_out("Image not created !");
			}
			pImgFactory->Release();
		}
		else {
			err_out("ImageFactory not created !");
		}
		CoUninitialize();
	}
	else {
		err_out("CoInitializeEx not initialized !");
	}
#endif //#if defined(_WIN32_WCE)
}

IDrawingImage* Win32DrawingImageImpl::clone() {
	RHO_MAP_TRACE1("clone DrawingImage from ID = %d", mID);
	return new Win32DrawingImageImpl(mBitmap);
}


void Win32DrawingImageImpl::draw(HDC hdc, int x, int y) 
{
	RHO_MAP_TRACE2("draw DrawingImage with x = %d, y = %d", x, y);
	if (mBitmap == NULL) {
		return;
	}
	mBitmap->draw(hdc, x, y);
}



Win32DrawingContextImpl::Win32DrawingContextImpl(HDC hdc, int width, int height) {
	RHO_MAP_TRACE2("DrawingContext create with WIDTH = %d, HEIGHT = %d", width, height);
	mHDC = hdc;
	mWidth = width;
	mHeight = height;
}

int Win32DrawingContextImpl::getWidth() {
	return mWidth;
}

int Win32DrawingContextImpl::getHeight() {
	return mHeight;
}

void Win32DrawingContextImpl::drawImage(int x, int y, IDrawingImage* image) {
	Win32DrawingImageImpl* img = (Win32DrawingImageImpl*)image;
	img->draw(mHDC, x, y);
}

void Win32DrawingContextImpl::drawText(int x, int y,  int nWidth, int nHeight, String const &text, int color) 
{
	RHO_MAP_TRACE2("DrawingContext drawText with x = %d, y = %d", x, y);

	HFONT hfontTahoma;         
	LOGFONT logfont;          
	HFONT hfontSave = NULL;
  
    memset (&logfont, 0, sizeof (logfont));
	logfont.lfHeight = 18;
	logfont.lfWidth = 0;
	logfont.lfEscapement = 0;
	logfont.lfOrientation = 0;
	logfont.lfWeight = FW_BOLD;
	logfont.lfItalic = FALSE;
	logfont.lfUnderline = FALSE;
	logfont.lfStrikeOut = FALSE;
	logfont.lfCharSet = DEFAULT_CHARSET;
	logfont.lfOutPrecision = OUT_DEFAULT_PRECIS;
	logfont.lfClipPrecision = CLIP_DEFAULT_PRECIS;
	logfont.lfQuality = DEFAULT_QUALITY;
	logfont.lfPitchAndFamily = DEFAULT_PITCH | FF_DONTCARE;
	_tcsncpy (logfont.lfFaceName, TEXT("Tahoma"), LF_FACESIZE);
	logfont.lfFaceName[LF_FACESIZE-1] = TEXT('\0');  // Ensure null termination
	hfontTahoma = CreateFontIndirect (&logfont);

	if (hfontTahoma) {
		hfontSave = (HFONT) SelectObject(mHDC, hfontTahoma);
	}

	StringW pathW = convertToStringW(text);
	SetBkMode(mHDC, TRANSPARENT);
	SetTextColor(mHDC, color & 0xFFFFFF);
	//TextOut(mHDC, x, y, pathW.c_str(), pathW.length());
	RECT r;
	r.left = x;
	r.top = y;
	r.right = x+nWidth;
	r.bottom = y + nHeight;
	DrawText(mHDC, pathW.c_str(), -1, &r, DT_LEFT | DT_TOP);

	if (hfontTahoma) {
		SelectObject(mHDC, hfontSave);
		DeleteObject (hfontTahoma);
	}
}

void Win32DrawingContextImpl::fillRect(int x, int y, int width, int height, int color) {
	RECT r;
	r.left = x;
	r.top = y;
	r.right = x+width;
	r.bottom = y + height;

	HBRUSH hBrush;
	HBRUSH hOldBrush;

	hBrush = CreateSolidBrush(0xFF000000 | color);
	hOldBrush = (HBRUSH)SelectObject(mHDC, hBrush);

	FillRect(mHDC, &r, hBrush);

	SelectObject(mHDC, hOldBrush);
	DeleteObject(hBrush);
}

void Win32DrawingContextImpl::getTextRect(int x, int y, String &text, RECT* resultRect) 
{
	//GetTextExtentPoint32
}

void Win32DrawingContextImpl::drawLine(int x1, int y1, int x2, int y2, int color) 
{
}

*/