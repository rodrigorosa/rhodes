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

package com.rhomobile.rhodes.mapview;

import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.util.DisplayMetrics;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.ItemizedOverlay;
import com.google.android.maps.OverlayItem;
import com.rhomobile.rhodes.WebView;
import com.rhomobile.rhodes.util.Utils;

public class CalloutOverlay extends ItemizedOverlay<OverlayItem> {
	
	public static final String TAG = "CalloutOverlay";

	private GoogleMapView mainView = null;
	private Callout mCallout = null; 
	private Annotation mSelectedAnnotation = null;
	
	
	private Boolean is_logging = false;
	
	private void printLog(String msg) {
		if (is_logging) {
			Utils.platformLog(TAG, msg);
		}
	}
	
	public CalloutOverlay(GoogleMapView view, Drawable marker) {
		super(boundCenterBottom(marker));
		mainView = view;
		mSelectedAnnotation = null;
		populate();
	}
	
	public void selectAnnotation(Annotation ann) {
		printLog("selectAnnotation() START");
		
		if (mCallout == null) {
			mCallout = new Callout(ann.latitude, ann.longitude, ann.title, ann.subtitle, ann.url, mainView);
		}
		else {
			mCallout.rebuild(ann.latitude, ann.longitude, ann.title, ann.subtitle, ann.url);
		}
		printLog("selectAnnotation() prePopulate");
		final Annotation _ann = ann;
		//PerformOnUiThread.exec(new Runnable() {
			Annotation mAnn = _ann;
			//public void run() {
				mSelectedAnnotation = mAnn;
				populate();
				//mainView.
			//}
		//}, false);
		printLog("selectAnnotation() FINISH");
	}
	
	public void deselectAnnotation() {
		printLog("deselectAnnotation() START");
		printLog("deselectAnnotation() prePopulate");
		//PerformOnUiThread.exec(new Runnable() {
			//public void run() {
				mSelectedAnnotation = null;
				populate();
			//}
		//}, false);
		printLog("deselectAnnotation() FINISH");
	}
	
	
	@Override
	protected OverlayItem createItem(int i) {
		printLog("  --  createItem() START");
		Annotation ann = mSelectedAnnotation;
		OverlayItem item = null;
		
		if (ann != null) {
			GeoPoint pnt = new GeoPoint((int)(ann.latitude*1000000), (int)(ann.longitude*1000000));
			item = new OverlayItem(pnt, ann.title, ann.subtitle);
	
			Bitmap bitmap = mCallout.getResultBitmap();
			bitmap.setDensity(DisplayMetrics.DENSITY_MEDIUM);
			BitmapDrawable bd = new BitmapDrawable(bitmap);
			//bd.setTargetDensity(DisplayMetrics.DENSITY_MEDIUM);
			bd.setVisible(true, true);
			bd.setBounds(	ann.callout_x_offset + mCallout.getXOffset(), 
							ann.callout_y_offset + mCallout.getYOffset(), 
							ann.callout_x_offset + mCallout.getXOffset() + bitmap.getWidth(), 
							ann.callout_y_offset + mCallout.getYOffset() + bitmap.getHeight());
			
			item.setMarker(bd);
		}
		else {
			GeoPoint pnt = new GeoPoint((int)(0), (int)(0));
			item = new OverlayItem(pnt, "", "");
			Bitmap bm = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888);
			bm.eraseColor(0);
			bm.setDensity(DisplayMetrics.DENSITY_MEDIUM);
			BitmapDrawable bd = new BitmapDrawable(bm);
			bd.setVisible(true, true);
			bd.setBounds(	0, 
							0, 
							1, 
							1);
			
			item.setMarker(bd);
		}
		printLog("  --  createItem() FINISH");
		return item;
	}

	@Override
	public int size() {
		int s = 0;
		//if (mSelectedAnnotation != null) {
			s = 1;
		//}
		printLog("size() == "+String.valueOf(s));
		return s;
	}
	
	@Override
	protected boolean onTap(int i) {
		printLog("onTap("+String.valueOf(i)+") START");
		if (mSelectedAnnotation == null) {
			printLog("onTap() return false");
			return false;
		}
		if ((mSelectedAnnotation.url != null) && (mSelectedAnnotation.url.length() > 0)) {
			WebView.navigate(mSelectedAnnotation.url, WebView.activeTab());
			mainView.finish();
			printLog("onTap() return true 1");
			return true;
		}
		printLog("onTap() return true 2");
		return true;
	}

	@Override
	public boolean onTap(GeoPoint p, com.google.android.maps.MapView mapView) {
		printLog("onTap() START");
		boolean result = super.onTap(p, mapView);
		printLog("onTap() after super");
		if (!result) {
			if (mSelectedAnnotation != null) {
				deselectAnnotation();
				/*
				 PerformOnUiThread.exec(new Runnable() {
					public void run() {
						//mSelectedAnnotation = null;
						//populate();
						deselectAnnotation();
					}
				}, false);
				//*/
				
			}
		}
		printLog("onTap() FINISH");
		return result;
	}

}
