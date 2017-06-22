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

package com.rhomobile.rhodes;

import com.rhomobile.rhodes.osfunctionality.AndroidFunctionalityManager;
import com.rhomobile.rhodes.util.PerformOnUiThread;
import com.rhomobile.rhodes.util.Utils;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.os.Bundle;
import android.os.IBinder;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Display;
import android.view.Window;
import android.view.WindowManager;
import android.provider.Settings;

public class BaseActivity extends Activity implements ServiceConnection {
	
	private static final String TAG = BaseActivity.class.getSimpleName();
	
	private static final boolean DEBUG = false;
	
	private static boolean setFullScreenFlag = false;
	
	public static final String INTENT_SOURCE = BaseActivity.class.getName();
	
	public boolean mEnableScreenOrientationOverride = false;
	
    public static class ScreenProperties {
        private int mScreenWidth;
        private int mScreenHeight;
        private int mRealScreenWidth;
        private int mRealScreenHeight;
        private int mScreenOrientation;
        private float mScreenPpiX;
        private float mScreenPpiY;
        
        
        ScreenProperties(Context context) {
            reread(context);
        }
        
        public void reread(Context context) {
            Logger.T(TAG, "Updating screen properties");
            
            WindowManager wm = (WindowManager)context.getSystemService(Context.WINDOW_SERVICE);

            Display d = wm.getDefaultDisplay();
	    float dpr = RhodesActivity.getContext().getResources().getDisplayMetrics().density;
            
            mScreenWidth = d.getWidth();
            mScreenHeight = d.getHeight();
            
            mRealScreenWidth = (int) (d.getWidth() / dpr);
            mRealScreenHeight = (int) (d.getHeight() / dpr);
	
            DisplayMetrics metrics = new DisplayMetrics();
            d.getMetrics(metrics);

            mScreenPpiX = metrics.xdpi;
            mScreenPpiY = metrics.ydpi;

            mScreenOrientation = AndroidFunctionalityManager.getAndroidFunctionality().getScreenOrientation(context);

            Logger.D(TAG, "New screen properties - width: " + mScreenWidth + ", height: " + mScreenHeight + ", orientation: " + mScreenOrientation);
        }
        
        public int getWidth() { return mScreenWidth; }
        public int getHeight() { return mScreenHeight; }
        public int getRealWidth() { return mRealScreenWidth; }
        public int getRealHeight() { return mRealScreenHeight; }
        public int getOrientation() { return mScreenOrientation; }
        public float getPpiX() { return mScreenPpiX; }
        public float getPpiY() { return mScreenPpiY; }
    }

    private static ScreenProperties sScreenProp = null;
    
    public static ScreenProperties getScreenProperties() { return sScreenProp; }

    private static boolean sFullScreen = RhoConf.isExist("full_screen") ? RhoConf.getBool("full_screen") : false;

    protected RhodesService mRhodesService;
	private boolean mBoundToService;

    private static int sActivitiesActive;
    private static BaseActivity sTopActivity = null;
    
    private static boolean sScreenAutoRotate = true;

    public static void onActivityStarted(Activity activity) {
        sTopActivity = null;
        activityStarted();
    }

    public static void onActivityStopped(Activity activity) {
        activityStopped();
    }

    public static void onActivityStarted(BaseActivity activity) {
        sTopActivity = activity;
        activityStarted();
    }

    public static void onActivityStopped(BaseActivity activity) {
        if(sTopActivity == activity) {
            sTopActivity = null;
        }
        activityStopped();
    }

    private static void activityStarted() {
        Logger.D(TAG, "activityStarted (1): sActivitiesActive=" + sActivitiesActive);
        if (sActivitiesActive == 0) {
            Logger.D(TAG, "first activity started");

            RhodesService r = RhodesService.getInstance();
            if (r != null)
                r.handleAppActivation();
        }
        ++sActivitiesActive;
        Logger.D(TAG, "activityStarted (2): sActivitiesActive=" + sActivitiesActive);
    }
    
    public static void activityStopped() {
        Logger.D(TAG, "activityStopped (1): sActivitiesActive=" + sActivitiesActive);

        --sActivitiesActive;
        if (sActivitiesActive == 0) {
            Logger.D(TAG, "last activity stopped");

            RhodesService r = RhodesService.getInstance();
            if (r != null)
                r.handleAppDeactivation();
        }
        Logger.D(TAG, "activityStopped (2): sActivitiesActive=" + sActivitiesActive);
    }
    
    public static int getActivitiesCount() {
        return sActivitiesActive;
    }

    @Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		Logger.T(TAG, "onCreate");

		Intent intent = new Intent(this, RhodesService.class);
		intent.putExtra(RhodesService.INTENT_SOURCE, INTENT_SOURCE);
		ComponentName serviceName = startService(intent);
		if (serviceName == null)
			throw new RuntimeException("Can not start Rhodes service");
		bindService(intent, this, Context.BIND_AUTO_CREATE);
		mBoundToService = true;

        if (RhoConf.isExist("disable_screen_rotation")) {
            sScreenAutoRotate = !RhoConf.getBool("disable_screen_rotation");
        }
        if (mEnableScreenOrientationOverride) {
        	sScreenAutoRotate = true;
        }

        if (sScreenProp == null) {
            sScreenProp = new ScreenProperties(this);
        } else {
            if (!sScreenAutoRotate) { 
                Logger.D(TAG, "Screen rotation is disabled. Force orientation: " + getScreenProperties().getOrientation());
                setRequestedOrientation(getScreenProperties().getOrientation());
            }
        }
    }

	@Override
	protected void onDestroy() {
		if (mBoundToService) {
			Logger.T(TAG, "unbindService and stopService");
			unbindService(this);
			//SPR28363fix Start
			Intent stopServiceIntent=new Intent(this,RhodesService.class);
			this.stopService(stopServiceIntent);
			//SPR28363fix End
			mBoundToService = false;
		}
		super.onDestroy();
	}

    @Override
    protected void onStart() {
        super.onStart();
        onActivityStarted(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if((RhoConf.isExist("full_screen") ? RhoConf.getBool("full_screen") : false ) && setFullScreenFlag ==false){
        	 setFullScreen(true);
        }else if(sFullScreen){
        	setFullScreen(true);	
        }else{
    		setFullScreen(false);
        }
        //setFullScreen(sFullScreen);
        if (sScreenAutoRotate) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR);
        }
    }

    @Override
    protected void onStop() {
        onActivityStopped(this);
        super.onStop();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
  		//Utils.platformLog("$$$$$", "BaseActivity.onConfigurationChanged()");
        Logger.T(TAG, "onConfigurationChanged");
        super.onConfigurationChanged(newConfig);
        if(!sScreenAutoRotate)
        {
      		//Utils.platformLog("$$$$$", "BaseActivity.onConfigurationChanged() ###1");

        	if (!mEnableScreenOrientationOverride) {
          		//Utils.platformLog("$$$$$", "BaseActivity.onConfigurationChanged() ###2");
        		Logger.D(TAG, "Screen rotation is disabled. Force old orientation: " + getScreenProperties().getOrientation());
            	setRequestedOrientation(getScreenProperties().getOrientation());
        	}
        }
        else
        {
			// check system options for rotation
			boolean isSystemAutoRotateEnnabled = true;
			int str = 1;
			try {
				str = Settings.System.getInt(this.getContentResolver(), Settings.System.ACCELEROMETER_ROTATION, 1);
			}
			catch (Exception e)
		    {
				Logger.D(TAG, "ERROR: Can not read Screen Rotation enable from System Settings !");
		        e.printStackTrace();
		    }
			if(str==1)
			{
				// rotation is Unlocked
			} else {
				// rotation is Locked
				isSystemAutoRotateEnnabled = false;
			}

			if (isSystemAutoRotateEnnabled) {
				//Utils.platformLog("$$$$$", "BaseActivity.onConfigurationChanged() ###3");

	      		ScreenProperties props = getScreenProperties();
	            props.reread(this);

	            int rotation = 0;
	            switch(props.getOrientation()) {
	            case ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE:
	                rotation = 90;
	                break;
	            case ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT:
	                rotation = 180;
	                break;
	            case ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE:
	                rotation = 270;
	                break;
	            case ActivityInfo.SCREEN_ORIENTATION_PORTRAIT:
	            default:
	                rotation = 0;
	                break;
	            }
	            RhodesService.onScreenOrientationChanged(props.getWidth(), props.getHeight(), rotation);
			}
			else {
				if (!mEnableScreenOrientationOverride) {
	          		//Utils.platformLog("$$$$$", "BaseActivity.onConfigurationChanged() ###2");
	        		Logger.D(TAG, "Screen rotation is disabled by Android settings. ##### Force old orientation: " + getScreenProperties().getOrientation());
	            	setRequestedOrientation(getScreenProperties().getOrientation());
	        	}
			}
        }
    }

	@Override
	public void onServiceConnected(ComponentName name, IBinder service) {
		mRhodesService = ((RhodesService.LocalBinder)service).getService();
		if (DEBUG)
			Log.d(TAG, "Connected to service: " + mRhodesService);
	}

	@Override
	public void onServiceDisconnected(ComponentName name) {
		if (DEBUG)
			Log.d(TAG, "Disconnected from service: " + mRhodesService);
		mRhodesService = null;
	}

    public static void setFullScreenMode(final boolean mode) {
        sFullScreen = mode;
        setFullScreenFlag = true;
        PerformOnUiThread.exec(new Runnable() {
            @Override public void run() {
                if (sTopActivity != null) {
                    sTopActivity.setFullScreen(mode);
                }
            }
        });
    }
    
    public static boolean getFullScreenMode() {
        return sFullScreen;
    }
    
    public static void setScreenAutoRotateMode(boolean mode) {
   		//Utils.platformLog("$$$$$", "BaseActivity.setScreenAutoRotateMode("+String.valueOf(mode)+")");
        sScreenAutoRotate = mode;
        if (sScreenAutoRotate && (sTopActivity!=null)) {
            sTopActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR);
        }
    }

    public static boolean getScreenAutoRotateMode() {
   	   //Utils.platformLog("$$$$$", "BaseActivity.getScreenAutoRotateMode("+String.valueOf(sScreenAutoRotate)+")");
       return sScreenAutoRotate; 
    }

    public void setFullScreen(boolean enable) {
    	sFullScreen = enable;
        Window window = getWindow();
        if (enable) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
            window.setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        }
        else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
            window.setFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN, WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
        }
    }

}
