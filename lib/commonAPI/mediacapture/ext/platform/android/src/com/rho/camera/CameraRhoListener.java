package com.rho.camera;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.sql.Date;
import java.text.SimpleDateFormat;
import java.util.HashMap;
import java.util.Map;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ColorMatrixColorFilter;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Matrix;
import android.media.MediaScannerConnection;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.os.RemoteException;
import android.provider.MediaStore;
import android.provider.MediaStore.MediaColumns;
import com.rhomobile.rhodes.Base64;
import com.rhomobile.rhodes.Logger;
import com.rhomobile.rhodes.RhodesActivity;
import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.extmanager.AbstractRhoListener;
import com.rhomobile.rhodes.extmanager.IRhoExtManager;
import com.rhomobile.rhodes.extmanager.IRhoListener;
import com.rhomobile.rhodes.extmanager.RhoExtManager;
import com.rhomobile.rhodes.util.Utils;
import com.rhomobile.rhodes.file.RhoFileApi;

public class CameraRhoListener extends AbstractRhoListener implements
IRhoListener {

	private static final String TAG = CameraRhoListener.class.getSimpleName();

	private IMethodResult mMethodResult;
	private Map<String, String> mActualPropertyMap = null;
	private static CameraRhoListener sInstance = null;
	private static int picChoosen_imagewidth, picChoosen_imageheight = 0;
	private Uri curUri = null;
	private Uri storedUri = null;
	private HashMap<String,Object> resultMap = null;
	private String imgPath = null;
	private Bitmap mBitmap = null;
	private String rename = null;

	static CameraRhoListener getInstance() {
		return sInstance;
	}


	private void cleanState() {
		mActualPropertyMap = null;
		picChoosen_imagewidth = 0;
		picChoosen_imageheight = 0;
		curUri = null;
		storedUri = null;
		resultMap=new HashMap<String,Object>();
		imgPath = null;
		mBitmap = null;
		rename = null;
	}

	@Override
	public void onCreateApplication(IRhoExtManager extManager) {
		sInstance = this;
		CameraFactorySingleton.setInstance(new CameraFactory(this));
		extManager.addRhoListener(this);
		extManager.registerExtension("RhoCameraApi", new CameraExtension());
		resultMap=new HashMap<String,Object>();
	}


	public Bitmap toGrayscale(Bitmap bmpOriginal)
    {
        int width, height;
        height = bmpOriginal.getHeight();
        width = bmpOriginal.getWidth();

        Bitmap bmpGrayscale = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
        Canvas c = new Canvas(bmpGrayscale);
        Paint paint = new Paint();

		//ColorMatrix cm = new ColorMatrix();
        //cm.setSaturation(0);
        //ColorMatrixColorFilter f = new ColorMatrixColorFilter(cm);

		float[] mat = new float[]{
	            0.3f, 0.59f, 0.11f, 0, 0,
	            0.3f, 0.59f, 0.11f, 0, 0,
	            0.3f, 0.59f, 0.11f, 0, 0,
	            0, 0, 0, 1, 0};
	    ColorMatrixColorFilter f = new ColorMatrixColorFilter(mat);

        paint.setColorFilter(f);
        c.drawBitmap(bmpOriginal, 0, 0, paint);
        return bmpGrayscale;
    }

	public Bitmap rotateBitmap(Bitmap bitmap, int degree) {
		if (degree == 0) {
			return bitmap;
		}
	    int w = bitmap.getWidth();
	    int h = bitmap.getHeight();

	    Matrix mtx = new Matrix();
	    mtx.setRotate(degree);

	    return Bitmap.createBitmap(bitmap, 0, 0, w, h, mtx, true);
	}

	private boolean outputToDataUri() {
		return getActualPropertyMap().get("outputFormat").equalsIgnoreCase("dataUri");
	}

	private Uri makeDataUri() {

		ByteArrayOutputStream stream = null;
		Uri ret = null;
		try {
			stream = new ByteArrayOutputStream();
			mBitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
			byte[] byteArray = stream.toByteArray();
			StringBuilder dataBuilder = new StringBuilder();
			dataBuilder.append("data:image/jpeg;base64,");
			try {
				System.gc();
				dataBuilder.append(Base64.encodeToString(byteArray, false));
			} catch (Exception e) {
				// TODO: handle exception
				e.printStackTrace();
			}
			catch(OutOfMemoryError e){
				stream = new ByteArrayOutputStream();
				mBitmap.compress(Bitmap.CompressFormat.JPEG, 50, stream);
				byteArray = stream.toByteArray();
				dataBuilder.append(Base64.encodeToString(byteArray, false));
			}
			getActualPropertyMap().put("curUri", dataBuilder.toString());
			ret = Uri.parse(dataBuilder.toString());
		} catch ( Throwable e ) {
			if (stream != null) {
				try {
					stream.reset();
					stream.close();
				} catch (Throwable e1) {
					// Do nothing
				}
			}
		}

		return ret;
	}


	@SuppressLint("NewApi")
	@Override
	public void onActivityResult(RhodesActivity activity, int requestCode, int resultCode, Intent intent) {
		RhoExtManager.getInstance().dropActivityResultRequestCode(requestCode);
		Map<String, String> propertyMap = getActualPropertyMap();
		if (mMethodResult == null) {
			return;
		}
		Uri captureUri = null;
		String targetPath = " ";		
		Logger.T(TAG, "CameraRhoListener.onActivityResult() START");
		Logger.T(TAG, "ActualProperties: ["+getActualPropertyMap()+"]");
		Logger.T(TAG, "Properties: ["+propertyMap+"]");

		try {
			if (resultCode == Activity.RESULT_OK)
			{
				Logger.T(TAG, "resultCode == Activity.RESULT_OK");
				getActualPropertyMap().put("default_camera_key_path", "");
				SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd_hhmmss");
				rename = "IMG_"+ dateFormat.format(new Date(System.currentTimeMillis()))+".jpg";
				if(propertyMap.containsKey("fileName")){
					rename = propertyMap.get("fileName")+ ".jpg";
				}

				BitmapFactory.Options options_only_size = new BitmapFactory.Options();
				options_only_size.inJustDecodeBounds = true;

				String curPath = null;
				String strCaptureUri = getActualPropertyMap().get("captureUri");
				if (strCaptureUri != null)
				{
					captureUri = Uri.parse(getActualPropertyMap().get("captureUri"));
					getActualPropertyMap().put("default_camera_key_path", "");
				}
				if (intent != null && intent.hasExtra(MediaStore.EXTRA_OUTPUT))
				{
					Logger.T(TAG, "intent != null && intent.hasExtra(MediaStore.EXTRA_OUTPUT)");
					// used system Camera activity
					if(intent.hasExtra(MediaStore.EXTRA_OUTPUT)){
						Logger.T(TAG, "Intent extras: "+ intent.getExtras().keySet());
						curUri = (Uri) intent.getParcelableExtra(MediaStore.EXTRA_OUTPUT);
						storedUri = curUri;
					}
					if (curUri == null)
					{
						curUri = intent.getData();
					}
					try {
						System.gc();
						if (getActualPropertyMap().get("DeviceGallery_Key") == null){
							BitmapFactory.decodeFile(curUri.getPath(), options_only_size);
							if( outputToDataUri() ){
								mBitmap = BitmapFactory.decodeFile(curUri.getPath());
							}

						}else{
							imgPath = getFilePath(curUri);
							BitmapFactory.decodeFile(imgPath, options_only_size);
							if( outputToDataUri() ){
								mBitmap = BitmapFactory.decodeFile(imgPath);
							}
							File f= new File(imgPath);
							imgPath = copyImg(imgPath);
							//[PT 98935816]Fixing the extra black image issue in KitKat devices.
							fixTheGalleryIssue(imgPath);
							f.renameTo(new File(f.getParentFile(), rename));
							String pathAfterRename = f.getParentFile().getAbsolutePath() +"/"+rename;
							fixTheGalleryIssue(pathAfterRename);
							// RhodesActivity.getContext().sendBroadcast(new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE,
							//			  Uri.parse(curUri.getPath())));
							getActualPropertyMap().put("default_camera_key_path", "default_camera_key_path_value");
						}

					} catch (OutOfMemoryError e1) {
						e1.printStackTrace();
					}
					File file = null;
					if (!getActualPropertyMap().containsKey("fileName") && getActualPropertyMap().get("ChoosePicture_Key") == null){
						file= new File(curUri.getPath());
						file.renameTo(new File(file.getParentFile(), rename));
						String pathAfterRename = file.getParentFile().getAbsolutePath() +"/"+rename;
						fixTheGalleryIssue(pathAfterRename);
						// RhodesActivity.getContext().sendBroadcast(new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE,
						//			  Uri.parse(curUri.getPath())));
					}
					//picChoosen_imagewidth = mBitmap.getWidth();
					//picChoosen_imageheight = mBitmap.getHeight();
					picChoosen_imagewidth = options_only_size.outWidth;
					picChoosen_imageheight = options_only_size.outHeight;


					if( outputToDataUri() ){
						curUri = makeDataUri();						
						mBitmap.recycle();
					}
					Logger.T(TAG, "Photo is captured: " + curUri);
					//mBitmap.recycle();
				}else if (captureUri != null )
				{
					// not used system activity ?!
					// unreacheable ?

					Logger.T(TAG, "captureUri != null");

					curUri = captureUri;

					if (getActualPropertyMap().get("dataURI") == null) {
						Logger.T(TAG, "getActualPropertyMap().get(dataURI) == null");
						boolean fromGallery = false;
						try {
							imgPath = getFilePath(curUri);
						}
						catch (Exception e) {
							e.printStackTrace();
						}
						Logger.T(TAG, "curUri ["+curUri+"]");
						Logger.T(TAG, "imgPath ["+imgPath+"]");
						//Utils.platformLog("################", "intent.getData() ["+intent.getData()+"]");
						if (imgPath == null) {
							try {
								imgPath = getFilePath(intent.getData());
							}
							catch (Exception e) {
								e.printStackTrace();
							}
						}


						if (fromGallery) {
						}
						else {
							File f= new File(imgPath);
							imgPath = copyImg(imgPath);
							getActualPropertyMap().put("default_camera_key_path", "default_camera_key_path_value");
							BitmapFactory.Options options = new BitmapFactory.Options();
							options.inPreferredConfig = Bitmap.Config.ARGB_8888;
							try {
								BitmapFactory.decodeStream(new FileInputStream(f), null, options_only_size);
								if (!getActualPropertyMap().containsKey("fileName") && getActualPropertyMap().get("ChoosePicture_Key") == null){
									f.renameTo(new File(f.getParentFile(), rename));
									String pathAfterRename = f.getParentFile().getAbsolutePath() +"/"+rename;
									fixTheGalleryIssue(pathAfterRename);
									// RhodesActivity.getContext().sendBroadcast(new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE,
									//			  Uri.parse(f.getAbsolutePath())));
								}
							} catch (FileNotFoundException e) {
								e.printStackTrace();
							}
							picChoosen_imagewidth = options_only_size.outWidth;
							picChoosen_imageheight = options_only_size.outHeight;
							//mBitmap.recycle();
						}
					}

				}
				else if ( outputToDataUri() ) {
					Logger.T( TAG, "Making image URI from intent data" );
					mBitmap = (Bitmap)intent.getExtras().get("data");
					curUri = makeDataUri();
					mBitmap.recycle();
					Logger.T(TAG, "Photo is captured: " + curUri);
				}
				else
				{
					Logger.T(TAG, "else(2)");
					curUri = intent.getData();
					Logger.T(TAG, "Check intent data: " + curUri);
				}

				if (curUri == null) {
					curUri = intent.getData();
				}

				if (curUri.getScheme().equals("file"))
				{
					Logger.T(TAG, "curUri.getScheme().equals(file)");
					curPath = curUri.getPath();
					Logger.T(TAG, "curPath["+curPath+"]");
					String dataDir=RhodesActivity.safeGetInstance().getApplicationInfo().dataDir;
					dataDir=dataDir+curPath.substring(curPath.lastIndexOf("/") );

					if(getActualPropertyMap().get("fileName")==null)
					{
						getActualPropertyMap().put("fileName",dataDir);
					}
					if(getActualPropertyMap().get("fileName").contains(".jpg"))
					targetPath = getActualPropertyMap().get("fileName");
					else
					targetPath = getActualPropertyMap().get("fileName")+".jpg";
					File curFile = new File(curPath);

					if (!curPath.equals(targetPath))
					{
						//	Utils.copy(curPath, targetPath);
						//	curFile.delete();
						Logger.T(TAG, "File copied to " + targetPath);
						curUri = Uri.fromFile(new File(targetPath));
					}
					imgPath = copyImg(curPath);
					curUri = Uri.parse(imgPath);
					copyImgAsUserChoice(curPath);

					Logger.T(TAG, "imgPath ["+imgPath+"]");
					Logger.T(TAG, "curUri ["+curUri+"]");
					Logger.T(TAG, "curPath ["+curPath+"]");
					Logger.T(TAG, "targetPath["+targetPath+"]");
				}

				if (!outputToDataUri()) {
					applyPostCaptureTransforms(options_only_size);
				}

				try{
					DefaultCameraAsyncTask async = new DefaultCameraAsyncTask(mMethodResult, resultMap, intent, resultCode);
					async.execute();
				}
				catch(Exception ex)
				{
					ex.printStackTrace();
				}
			}
			else if (resultCode == Activity.RESULT_CANCELED)
			{
				getActualPropertyMap().put("default_camera_key_path", "");
				DefaultCameraAsyncTask async = new DefaultCameraAsyncTask(mMethodResult, resultMap, intent,resultCode);
				async.execute();
			} else {
				mMethodResult.setError("Unknown error");
			}
		} catch (Throwable err) {
			Logger.E(TAG, err);			
			mMethodResult.setError(err.getMessage());
		}

	}

	private void applyPostCaptureTransforms(BitmapFactory.Options options_only_size) {
		int rotate_angle = 0;

		String strExifRotation = getActualPropertyMap().get("useRotationBitmapByEXIF");
		if ((strExifRotation != null) && (Boolean.parseBoolean(strExifRotation))) {
			// detect original exif rotation
			String bitmapPath = imgPath;

			try {

				ExifInterface exif=new ExifInterface(bitmapPath);
				String or_tag = exif.getAttribute(ExifInterface.TAG_ORIENTATION);

				if (or_tag != null) {
					Logger.T(TAG, "$$$ EXIF TAG_ORIENTATION = "+or_tag+" $$$");

			        if(or_tag.equalsIgnoreCase("6")){
			            rotate_angle = 90;
			        } else if(or_tag.equalsIgnoreCase("8")){
			            rotate_angle = 270;
			        } else if(or_tag.equalsIgnoreCase("3")){
			            rotate_angle = 180;
			        } else if(or_tag.equalsIgnoreCase("0")){
			            // undefined
			        }
				}
			} catch (IOException ioerror) {
				Logger.T( TAG, "EXIF attributes can't be read from file: " + bitmapPath );
			}
		}
		if (rotate_angle != 0) {
			Logger.T(TAG, "$$$ Image should be rotated by EXIF !!! angle = "+rotate_angle+" $$$");
		}


		String useRealBitmapResize = getActualPropertyMap().get("useRealBitmapResize");
		if ((useRealBitmapResize != null) && (Boolean.parseBoolean(useRealBitmapResize))) {
			Logger.T(TAG, "$$$ real resize start $$$");
			try {
				// resize to preffered size

				Logger.T(TAG, "imgPath ["+imgPath+"]");
				Logger.T(TAG, "rename ["+rename+"]");
				String bitmapPath = imgPath;


				BitmapFactory.decodeFile(bitmapPath, options_only_size);
				picChoosen_imagewidth = options_only_size.outWidth;
				picChoosen_imageheight = options_only_size.outHeight;

				int idesiredWidth = 0;
				int idesiredHeight = 0;
				if (getActualPropertyMap().get("desiredWidth") != null) {
					idesiredWidth = Integer.valueOf(getActualPropertyMap().get("desiredWidth"));
				}
				if (getActualPropertyMap().get("desiredHeight") != null) {
					idesiredHeight = Integer.valueOf(getActualPropertyMap().get("desiredHeight"));
				}
				Logger.T(TAG, " FILE ["+bitmapPath+"]	 orig["+picChoosen_imagewidth+"x"+picChoosen_imageheight+"] scaleto ["+idesiredHeight+"x"+idesiredHeight+"]");
				if ((idesiredHeight > 0) && (idesiredWidth > 0)) {
					// process resize
					Logger.T(TAG, "Do SCALE  orig["+picChoosen_imagewidth+"x"+picChoosen_imageheight+"] scaleto ["+idesiredHeight+"x"+idesiredHeight+"]");


					float fcurWidth = picChoosen_imagewidth;
					float fcurHeight = picChoosen_imageheight;

					float desiredWidth = idesiredWidth;
					float desiredHeight = idesiredHeight;

					float kw = desiredWidth / fcurWidth;
					float kh = desiredHeight / fcurHeight;

					if (kw > 1.0) {
						if (kh > kw) {
							kw = kw/kh;
							kh = 1.0f;
						}
						else {
							kh = kh/kw;
							kw = 1.0f;
						}
					}
					else {
						if (kh > 1.0) {
							kw = kw/kh;
							kh = 1.0f;
						}
					}

					float k = kw;
					if (kw > kh) {
						k = kh;
					}

					int newWidth = (int)(picChoosen_imagewidth*k);
					int newHeight = (int)(picChoosen_imageheight*k);

					BitmapFactory.Options bmOptions = new BitmapFactory.Options();
					bmOptions.inJustDecodeBounds = false;
					bmOptions.inSampleSize = picChoosen_imagewidth / newWidth;

					picChoosen_imagewidth = newWidth;
					picChoosen_imageheight = newHeight;


					Logger.T(TAG, "Load samle scale ["+bmOptions.inSampleSize+"]");

					bmOptions.inPurgeable = true;

					Bitmap bitmap = BitmapFactory.decodeFile(bitmapPath, bmOptions);

					Bitmap scaledBitmap=Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true);

					if (rotate_angle != 0) {
						Bitmap savedBitmap = scaledBitmap;
						scaledBitmap = rotateBitmap(savedBitmap, rotate_angle);
						savedBitmap.recycle();
						savedBitmap = null;
						rotate_angle = 0;
					}

					ByteArrayOutputStream bos=new ByteArrayOutputStream();
					scaledBitmap.compress(Bitmap.CompressFormat.JPEG, 75, bos);
					bitmap.recycle();
					bitmap=null;
					OutputStream out;
					out = new FileOutputStream(bitmapPath+"_tmp");
					bos.writeTo(out);
					bos.flush();

					File file= new File(bitmapPath+"_tmp");
					File file_old = new File(bitmapPath);
					file_old.delete();
					file.renameTo(new File(bitmapPath));
					fixTheGalleryIssue(bitmapPath);


				}
			} catch (Exception e) {
				// TODO: handle exception
				e.printStackTrace();
			}
			Logger.T(TAG, "$$$ resize finished $$$");
		}

		// Grayscale
		String strColorMode = getActualPropertyMap().get("colorModel");
		if ((strColorMode != null) && (strColorMode.equalsIgnoreCase("grayscale")) ) {
			Logger.T(TAG, "$$$ recolor to grayscale start $$$");

			try {
				Logger.T(TAG, "imgPath ["+imgPath+"]");
				Logger.T(TAG, "rename ["+rename+"]");
				String bitmapPath = imgPath;

				Bitmap bitmap = BitmapFactory.decodeFile(bitmapPath);
				Bitmap gray = toGrayscale(bitmap);
				if (rotate_angle != 0) {
					Bitmap savedBitmap = gray;
					gray = rotateBitmap(savedBitmap, rotate_angle);
					savedBitmap.recycle();
					savedBitmap = null;
					rotate_angle = 0;
				}
				ByteArrayOutputStream bos=new ByteArrayOutputStream();
				gray.compress(Bitmap.CompressFormat.JPEG, 75, bos);
				bitmap.recycle();
				bitmap=null;
				OutputStream out;
				out = new FileOutputStream(bitmapPath+"_tmp");
				bos.writeTo(out);
				bos.flush();

				File file= new File(bitmapPath+"_tmp");
				File file_old = new File(bitmapPath);
				file_old.delete();
				file.renameTo(new File(bitmapPath));
				fixTheGalleryIssue(bitmapPath);

			} catch (Exception e) {
				// TODO: handle exception
				e.printStackTrace();
			}

			Logger.T(TAG, "$$$ recolor to grayscale finished $$$");
		}

		// EXIF rotation
		if (rotate_angle != 0) {
			Logger.T(TAG, "$$$ EXIF rotation start $$$");

			try {
				Logger.T(TAG, "imgPath ["+imgPath+"]");
				Logger.T(TAG, "rename ["+rename+"]");
				String bitmapPath = imgPath;

				Bitmap bitmap = BitmapFactory.decodeFile(bitmapPath);

				Bitmap rotated = rotateBitmap(bitmap, rotate_angle);

				ByteArrayOutputStream bos=new ByteArrayOutputStream();
				rotated.compress(Bitmap.CompressFormat.JPEG, 75, bos);
				bitmap.recycle();
				bitmap=null;
				OutputStream out;
				out = new FileOutputStream(bitmapPath+"_tmp");
				bos.writeTo(out);
				bos.flush();

				File file= new File(bitmapPath+"_tmp");
				File file_old = new File(bitmapPath);
				file_old.delete();
				file.renameTo(new File(bitmapPath));
				fixTheGalleryIssue(bitmapPath);


			} catch (Exception e) {
				// TODO: handle exception
				e.printStackTrace();
			}

			Logger.T(TAG, "$$$ EXIF rotation finished $$$");
		}
	}



	private void fixTheGalleryIssue(String absoluteRenamedPath )
	{
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT)
		{
			MediaScannerConnection.scanFile(RhodesActivity.getContext(), new String[] {absoluteRenamedPath }, null, new MediaScannerConnection.OnScanCompletedListener() {

				public void onScanCompleted(String path, Uri uri)
				{
				}
			});

		}
		else
		{
			RhodesActivity.getContext().sendBroadcast(new Intent(Intent.ACTION_MEDIA_MOUNTED, Uri.parse("file://" + Environment.getExternalStorageDirectory())));
		}


	}


	void setMethodResult(IMethodResult result) {
		mMethodResult = result;
	}

	void releaseMethodResult() {
		mMethodResult = null;
		resultMap.clear();
		//mActualPropertyMap.clear();
		//getActualPropertyMap().put("DeviceGallery_Key", "");
		//getActualPropertyMap().put("ChoosePicture_Key", "");
	}

	void setActualPropertyMap(Map<String, String> propertyMap) {
		mActualPropertyMap = propertyMap;
	}

	Map<String, String> getActualPropertyMap() {
		return mActualPropertyMap;
	}

	/**
	* AsyncTask class to handle keydispatchingtimedout or ANR caused
	* when OK or Cancel button of default camera in clicked
	* @param  IMethodResult  Object to set the hash map properties
	* @param  HashMap to set properties of captured image to map
	* @param  Intent
	* @param  ResultCode to decide click is OK or Cancel
	*/
	public class DefaultCameraAsyncTask extends AsyncTask<Void, Void, Void>{

		IMethodResult inMethodRes;
		HashMap<String, Object> inResultMap = new HashMap<String,Object>();
		Intent intent = new Intent();
		int resCode;

		public DefaultCameraAsyncTask(IMethodResult inMethodRes, HashMap<String, Object> inResultMap, Intent intent, int resCode){
			this.inMethodRes = inMethodRes;
			this.inResultMap = inResultMap;
			this.intent = intent;
			this.resCode = resCode;
		}

		@Override
		protected Void doInBackground(Void... params) {

			if(resCode == -1){
				if (intent != null && intent.hasExtra("error")) {
					inResultMap.put("message", ""+intent.getStringExtra("error"));
					if(intent.getStringExtra("error").contains("\\"))
					inResultMap.put("message", "File path is invalid.");
					inResultMap.put("status", "error");
				}
				else{
					inResultMap.put("status","ok");
					if(CameraSingletonObject.deprecated_choose_pic || CameraObject.deprecated_take_pic){
						inResultMap.put("image_uri",  "db/db-files/"+ curUri.toString().substring(curUri.toString().lastIndexOf("/")+1, curUri.toString().length()));
						inResultMap.put("image_format",   "jpg");
					}
					else{
						if((getActualPropertyMap().get("default_camera_key_path") != null) && (getActualPropertyMap().get("default_camera_key_path") != "")){
							inResultMap.put("imageUri",  imgPath);
							inResultMap.put("imageFormat",   "jpg");
						}else{
							inResultMap.put("imageUri",  curUri.toString());
							inResultMap.put("imageFormat",   "jpg");
						}
					}
					if(picChoosen_imagewidth > 0){
						if(CameraSingletonObject.deprecated_choose_pic || CameraObject.deprecated_take_pic){
							inResultMap.put("image_width",  "" + picChoosen_imagewidth);
							inResultMap.put("image_height",  "" + picChoosen_imageheight);
						}
						else{
							inResultMap.put("imageWidth",  "" + picChoosen_imagewidth);
							inResultMap.put("imageHeight",  "" + picChoosen_imageheight);
						}
					}
					else{
						if(CameraSingletonObject.deprecated_choose_pic || CameraObject.deprecated_take_pic){
							inResultMap.put("image_width",  "" + picChoosen_imagewidth);
							inResultMap.put("image_height",  "" + picChoosen_imageheight);
						}
						else{
							inResultMap.put("imageWidth",  "" + intent.getExtras().get("IMAGE_WIDTH"));
							inResultMap.put("imageHeight",  "" + intent.getExtras().get("IMAGE_HEIGHT"));
						}
					}
				}

			}else if(resCode == 0){

				inResultMap.put("message", "User canceled operation.");
				if (intent != null && intent.hasExtra("error")) {
					inResultMap.put("message", ""+intent.getStringExtra("error"));
					if(intent.getStringExtra("error").contains("\\"))
					inResultMap.put("message", "File path is invalid.");
					inResultMap.put("status", "error");
				} else {
					inResultMap.put("status", "cancel");
				}
			}
			return null;

		}

		@Override
		protected void onPostExecute(Void result) {
			super.onPostExecute(result);
			RhodesActivity.safeGetInstance().setScreenAutoRotateMode(CameraObject.CURRENT_SCREEN_AUTO_ROTATE_MODE);
			RhodesActivity.safeGetInstance().setFullScreenMode(CameraObject.CURRENT_FULL_SCREEN_MODE);
			inMethodRes.set(inResultMap);
			cleanState();
			releaseMethodResult();
		}

	}

	/*
	* method to convert uri to file path
	*
	* @param Uri of file
	* @returns String path of file
	*
	*/
	private String getFilePath(Uri uri){
		String resultPath = null;
		try {
			String mImgPath = null;
			Cursor imageCursor = RhodesActivity.getContext().getContentResolver().query(
			uri, null, null, null, null);
			if(imageCursor.moveToFirst()){
				mImgPath = imageCursor.getString(imageCursor
				.getColumnIndex(MediaColumns.DATA));
				imageCursor.close();
			}
			resultPath = mImgPath;
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		try {
			if (resultPath == null) {

				Uri selectedImage = uri;
				String[] filePathColumn = { MediaStore.Images.Media.DATA };

				Cursor cursor = RhodesActivity.getContext().getContentResolver().query(selectedImage,
				filePathColumn, null, null, null);
				cursor.moveToFirst();

				int columnIndex = cursor.getColumnIndex(filePathColumn[0]);
				resultPath = cursor.getString(columnIndex);
				cursor.close();

			}
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		return resultPath;
	}




private static void makeDirsForFile(String filepath) {
	try {
		String folderPath = filepath.substring(0,filepath.lastIndexOf("/"));
		File folderFile = new File(folderPath);
		if (!folderFile.exists()) {
			folderFile.mkdirs();
		}
	}
	catch (Exception e) {
	   e.printStackTrace();
	}

}


/**
* Copy image.
* Function to copy image from sd card to application root path
*
* @param photo
*			the photo
* @return the string
*/
public String copyImg(String imgPath){

	File oldFile = new File(imgPath);

	int lastIndex  = rename.lastIndexOf("/");

	String file_name= rename.substring(lastIndex+1, rename.length());

	File mediafile  =  new File(RhoFileApi.getDbFilesPath(), file_name);

	makeDirsForFile(mediafile.getAbsolutePath());

	//File mediafile  =  new File(RhoFileApi.getDbFilesPath(), rename);
	FileInputStream finput= null;
	FileOutputStream fout = null;
	try {
		finput = new FileInputStream(oldFile);
		fout = new FileOutputStream(mediafile);
		byte[] b = new byte[1024];
		int read = 0;
		while ((read = finput.read(b)) != -1) {
			fout.write(b, 0, read);
		}
	} catch (FileNotFoundException e) {
		e.printStackTrace();
	} catch (IOException e) {
		e.printStackTrace();
	} finally {
		if(finput != null){
			try {
				finput.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		if(fout != null){
			try {
				fout.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	return mediafile.getAbsolutePath();
}


public String copyImgToTarget(String srcPath, String dstPath) {

	File oldFile = new File(srcPath);
	File mediafile  =  new File(dstPath);

	makeDirsForFile(mediafile.getAbsolutePath());

	//File mediafile  =  new File(RhoFileApi.getDbFilesPath(), rename);
	FileInputStream finput= null;
	FileOutputStream fout = null;
	try {
		finput = new FileInputStream(oldFile);
		fout = new FileOutputStream(mediafile);
		byte[] b = new byte[1024];
		int read = 0;
		while ((read = finput.read(b)) != -1) {
			fout.write(b, 0, read);
		}
	} catch (FileNotFoundException e) {
		e.printStackTrace();
	} catch (IOException e) {
		e.printStackTrace();
	} finally {
		if(finput != null){
			try {
				finput.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		if(fout != null){
			try {
				fout.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	return mediafile.getAbsolutePath();
}

/**
* copyImgAsUserChoice image.
* Function to copy image from sd card to User specific path
*  Provided in TestCam.html file.
* @param photo
*			the photo
*
*/
public void copyImgAsUserChoice(String imgPath){
	if(rename.contains("sdcard")){

		Boolean isSDPresent = android.os.Environment.getExternalStorageState().equals(android.os.Environment.MEDIA_MOUNTED);


		if(isSDPresent)
		{

			File oldFile = new File(imgPath);

			int lastIndex = rename.lastIndexOf("/");

			String subfolderName = rename.replaceAll("/sdcard", "");
			String folderName = subfolderName.substring(subfolderName.indexOf("/")+1,subfolderName.lastIndexOf("/"));

			String file_name= rename.substring(lastIndex+1, rename.length());

			File directory = new File(Environment.getExternalStorageDirectory()+File.separator + folderName);
			boolean flag = directory.mkdirs();

			File mediafile  =  new File(directory +File.separator  + file_name);


			FileInputStream finput= null;
			FileOutputStream fout = null;
			try {
				finput = new FileInputStream(oldFile);
				fout = new FileOutputStream(mediafile);
				byte[] b = new byte[1024];
				int read = 0;
				while ((read = finput.read(b)) != -1) {
					fout.write(b, 0, read);
				}
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			} finally {
				if(finput != null){
					try {
						finput.close();

					} catch (IOException e) {
						e.printStackTrace();
					}
				}

				if(fout != null){
					try {
						fout.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
			}
			deleteImage();
		}


	}
}

/**
* deleteImage image.
* Function for Deleting the Image from SD card.
* And maintain a copy of same Image at user specific Path
* @param nothing
*
*/
public void deleteImage(){
	String storageLocation = null;
	storageLocation = Environment.getExternalStorageDirectory().toString();

	int lastIndex = rename.lastIndexOf("/");
	String file_name= rename.substring(lastIndex+1, rename.length());

	File file = new File(storageLocation + "/Pictures/"+file_name);
	if(file.exists()){
		file.delete();
	}
}

}
