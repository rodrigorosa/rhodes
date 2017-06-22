package com.rho.devicememory;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;

import android.content.ComponentCallbacks2;
import android.content.res.Configuration;
import android.util.Log;

import com.rhomobile.rhodes.Logger;
import com.rhomobile.rhodes.RhodesActivity;
import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.api.MethodResult;

class DeviceMemorySingleton  implements IDeviceMemorySingleton {
	
	private final String TAG="DeviceMemorySingleton";
	
	private MethodResult oscallback=null;
	private DeviceMemComponentCallback compCallback=null;
    public DeviceMemorySingleton(DeviceMemoryFactory factory) {
       // super(factory);
    }
    
    public DeviceMemorySingleton()
    {
    	if(compCallback==null)
    		compCallback=new DeviceMemComponentCallback();
    	
    }

    List<Object> getIDs() {
        List<Object> ids = new LinkedList<Object>();
        ids.add("SCN1");
        ids.add("SCN2");
        return ids;
    }
    
  
	@Override
	public void startListeningPlatformMemoryWarning(IMethodResult result) {
		
		Log.d(TAG,"startListeningPlatformMemoryWarning");
		Logger.I(TAG,"startListeningPlatformMemoryWarning");
		
		if(oscallback!=null)
			oscallback.release();
		
		oscallback=(MethodResult) result;
		oscallback.keepAlive();
		
		RhodesActivity.safeGetInstance().getApplicationContext().registerComponentCallbacks(compCallback);
		
		
		
	}

	@Override
	public void stopListeningPlatformMemoryWarning(IMethodResult result) {
		
		Log.d(TAG,"stopListeningPlatformMemoryWarning");
		Logger.I(TAG,"stopListeningPlatformMemoryWarning");
		if(compCallback!=null)
			RhodesActivity.safeGetInstance().getApplicationContext().unregisterComponentCallbacks(compCallback);
		
		oscallback.release();
		
		oscallback=null;
	}

	@Override
	public void getAvailableMemory(IMethodResult result) {
		
		int str=DeviceMemoryCalculator.getAvailableMemory();
		//Log.d(TAG, "getAvailableMemory="+str);
		//Logger.I(TAG, "getAvailableMemory="+str);
		//str=2147483647;
		if(result!=null)
			result.set(str);	
		
	}

	/*@Override
	public void getAvailableStorageMemory(IMethodResult result) {
		
		String str=MemoryCalculator.getAvailableStorageMemory();
		Log.d(TAG, "getAvailableStorageMemory="+str);
		Logger.I(TAG, "getAvailableStorageMemory="+str);
		result.set(str);
	}

	@Override
	public void getAvailableDataMemory(IMethodResult result) {
		
		String str=MemoryCalculator.getAvailableDataMemory();
		Log.d(TAG, "getAvailableDataMemory="+str);
		Logger.I(TAG, "getAvailableDataMemory="+str);
		result.set(str);
	}
	*/
	private void fireOsCallback(String memStatus)
	{
		if(oscallback!=null)
		{
			HashMap<String,Object> resMap=new HashMap<String,Object>();
			resMap.put("status", memStatus);
			oscallback.set(resMap);
		}
	}
	
	class DeviceMemComponentCallback implements ComponentCallbacks2{

		@Override
		public void onConfigurationChanged(Configuration arg0) {
			// TODO Auto-generated method stub
			
		}

		@Override
		public void onLowMemory() {
			// TODO Auto-generated method stub
			
		}

		@Override
		public void onTrimMemory(int arg0) {
			switch(arg0)
			{
			case ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE:
																	Log.d(TAG,"TRIM_MEMORY_RUNNING_MODERATE");
																	Logger.I(TAG,"TRIM_MEMORY_RUNNING_MODERATE");
																	fireOsCallback(IDeviceMemorySingleton.DEVICE_MEMORY_STATUS_LOW);
																	break;
			case ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW:
																	Log.d(TAG,"TRIM_MEMORY_RUNNING_LOW");
																	Logger.I(TAG,"TRIM_MEMORY_RUNNING_LOW");
																	fireOsCallback(IDeviceMemorySingleton.DEVICE_MEMORY_STATUS_LOW);
																	break;
			case ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL:
																	Log.d(TAG,"TRIM_MEMORY_RUNNING_CRITICAL");
																	Logger.I(TAG,"TRIM_MEMORY_RUNNING_CRITICAL");
																	fireOsCallback(IDeviceMemorySingleton.DEVICE_MEMORY_STATUS_LOW);
																	break;
			
			case ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN:
																	Log.d(TAG,"TRIM_MEMORY_UI_HIDDEN");
																	Logger.I(TAG,"TRIM_MEMORY_UI_HIDDEN");
																	//fireOsCallback("TRIM_MEMORY_UI_HIDDEN");
																	break;
			
			case ComponentCallbacks2.TRIM_MEMORY_BACKGROUND:
																	Log.d(TAG,"TRIM_MEMORY_BACKGROUND");
																	Logger.I(TAG,"TRIM_MEMORY_BACKGROUND");
																	fireOsCallback(IDeviceMemorySingleton.DEVICE_MEMORY_STATUS_CRITICAL);
																	break;
			case ComponentCallbacks2.TRIM_MEMORY_MODERATE:
																	Log.d(TAG,"TRIM_MEMORY_MODERATE");
																	Logger.I(TAG,"TRIM_MEMORY_MODERATE");
																	fireOsCallback(IDeviceMemorySingleton.DEVICE_MEMORY_STATUS_CRITICAL);
																	break;
			case ComponentCallbacks2.TRIM_MEMORY_COMPLETE:
																	Log.d(TAG,"TRIM_MEMORY_COMPLETE");
																	Logger.I(TAG,"TRIM_MEMORY_COMPLETE");
																	fireOsCallback(IDeviceMemorySingleton.DEVICE_MEMORY_STATUS_CRITICAL);
																	break;
			
			
			}
			
		}
		
	}

	@Override
	public void getInternalStorage(IMethodResult result) {
		int str=DeviceMemoryCalculator.getAvailableDataMemory();
		DeviceMemoryListener.internalMemory = str;
		//Log.d(TAG, "getInternalStorage="+str);
		//Logger.I(TAG, "getInternalStorage="+str);
		if(result!=null)
			result.set(str);
	
	}

	@Override
	public void getExternalStorage(IMethodResult result) {
		int str=DeviceMemoryCalculator.getAvailableStorageMemory();
		DeviceMemoryListener.externalMemory = str;
		//Log.d(TAG, "getExternalStorage="+str);
		//Logger.I(TAG, "getExternalStorage="+str);
		if(result!=null)
			result.set(str);
		
	}
	
}
