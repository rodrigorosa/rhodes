/*
 * Copyright (C) 2008 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.zxing.client.android;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.Result;
import com.google.zxing.ResultMetadataType;
import com.google.zxing.ResultPoint;
import com.google.zxing.client.android.camera.CameraManager;
import com.rho.barcode.BarcodeFactory;
import com.rhomobile.rhodes.BaseActivity;
import com.rhomobile.rhodes.Logger;
//import com.rhomobile.rhodes.R;
import com.rhomobile.rhodes.extmanager.RhoExtManager;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetFileDescriptor;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.Vibrator;
import android.preference.PreferenceManager;
import android.text.ClipboardManager;
import android.util.Log;
import android.util.TypedValue;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import java.io.IOException;
import java.text.DateFormat;
import java.util.Date;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

/**
 * The barcode reader activity itself. This is loosely based on the CameraPreview
 * example included in the Android SDK.
 *
 * @author dswitkin@google.com (Daniel Switkin)
 * @author Sean Owen
 */
public final class CaptureActivity extends BaseActivity implements SurfaceHolder.Callback {
	
  protected static final String LOGTAG = "ZXActivity";
  public static final String CAMERA_INDEX_EXTRA = "camera_index";	
  public static final String RHO_BARCODE_ID = "barcode_obj_id";
	

  @Override
protected void onNewIntent(Intent intent)
{
	Logger.D(LOGTAG, "NEW INTENT!!!");
	super.onNewIntent(intent);
}

private static final String TAG = CaptureActivity.class.getSimpleName();

  private static final int SHARE_ID = Menu.FIRST;
  private static final int HISTORY_ID = Menu.FIRST + 1;
  private static final int SETTINGS_ID = Menu.FIRST + 2;
  private static final int HELP_ID = Menu.FIRST + 3;
  private static final int ABOUT_ID = Menu.FIRST + 4;

  private static final long INTENT_RESULT_DURATION = 1500L;
  private static final long BULK_MODE_SCAN_DELAY_MS = 1000L;
  private static final float BEEP_VOLUME = 0.10f;
  private static final long VIBRATE_DURATION = 200L;

  private static final String PACKAGE_NAME = "com.google.zxing.client.android";
  private static final String PRODUCT_SEARCH_URL_PREFIX = "http://www.google";
  private static final String PRODUCT_SEARCH_URL_SUFFIX = "/m/products/scan";
  private static final String ZXING_URL = "http://zxing.appspot.com/scan";
  private static final String RETURN_CODE_PLACEHOLDER = "{CODE}";
  private static final String RETURN_URL_PARAM = "ret";

  private static final Set<ResultMetadataType> DISPLAYABLE_METADATA_TYPES;


  static {
    DISPLAYABLE_METADATA_TYPES = new HashSet<ResultMetadataType>(5);
    DISPLAYABLE_METADATA_TYPES.add(ResultMetadataType.ISSUE_NUMBER);
    DISPLAYABLE_METADATA_TYPES.add(ResultMetadataType.SUGGESTED_PRICE);
    DISPLAYABLE_METADATA_TYPES.add(ResultMetadataType.ERROR_CORRECTION_LEVEL);
    DISPLAYABLE_METADATA_TYPES.add(ResultMetadataType.POSSIBLE_COUNTRY);
  }

  private enum Source {
    NATIVE_APP_INTENT,
    PRODUCT_SEARCH_LINK,
    ZXING_LINK,
    NONE
  }

  private CaptureActivityHandler handler;

  private ViewfinderView viewfinderView;
  //private TextView statusView;
  private View resultView;
  private MediaPlayer mediaPlayer;
  private Result lastResult;
  private boolean hasSurface;
  private boolean playBeep = true;
  private boolean vibrate = false;
  private boolean copyToClipboard = false;
  private Source source;
  private String sourceUrl;
  private String returnUrlTemplate;
  private Vector<BarcodeFormat> decodeFormats;
  private String characterSet;
  private String versionName;
  //private HistoryManager historyManager;
  private InactivityTimer inactivityTimer;
  private String rhoBarcodeId;
  private int camera_index;

  private Button mCancelButton = null;
  private Button mCancelButton2 = null;
  private Button mRetakeButton = null;
  private Button mOKButton = null;
  
  /**
   * When the beep has finished playing, rewind to queue up another one.
   */
  private final OnCompletionListener beepListener = new OnCompletionListener() {
    public void onCompletion(MediaPlayer mediaPlayer) {
      mediaPlayer.seekTo(0);
    }
  };



  ViewfinderView getViewfinderView() {
    return viewfinderView;
  }

  public Handler getHandler() {
    return handler;
  }

  @Override
  public void onCreate(Bundle icicle) {
    super.onCreate(icicle);
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
    Window window = getWindow();
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    setContentView(RhoExtManager.getResourceId("layout", "capture"));

    int camera_index = 0;
    Intent intent = getIntent();
    if (intent != null) {
    	camera_index = intent.getIntExtra(CAMERA_INDEX_EXTRA, 0);
    	Logger.D(LOGTAG, "Intent Camera index: " + camera_index);
    	this.camera_index = camera_index;
    	rhoBarcodeId = intent.getStringExtra(RHO_BARCODE_ID);
    }
    
    CameraManager.init(getApplication());
    viewfinderView = (ViewfinderView) findViewById(RhoExtManager.getResourceId("id", "viewfinder_view"));
    resultView = findViewById(RhoExtManager.getResourceId("id", "result_view"));
    //statusView = (TextView) findViewById(R.id.status_view);
    handler = null;
    lastResult = null;
    hasSurface = false;
    //historyManager = new HistoryManager(this);
    //historyManager.trimHistory();
    inactivityTimer = new InactivityTimer(this);

    mCancelButton2 = (Button)findViewById(RhoExtManager.getResourceId("id", "cancel_button_a"));
    mCancelButton = (Button)findViewById(RhoExtManager.getResourceId("id", "cancel_button"));
    mRetakeButton = (Button)findViewById(RhoExtManager.getResourceId("id", "retake_button"));
    mOKButton = (Button)findViewById(RhoExtManager.getResourceId("id", "ok_button"));
    
    mCancelButton2.setOnClickListener( new OnClickListener() {
		public void onClick(View v) {
			onCancel();
		}});
    mCancelButton.setOnClickListener( new OnClickListener() {
		public void onClick(View v) {
			onCancel();
		}});
    mRetakeButton.setOnClickListener( new OnClickListener() {
		public void onClick(View v) {
			onRetake();
		}});
    mOKButton.setOnClickListener( new OnClickListener() {
		public void onClick(View v) {
			onOK();
		}});
    
    mCancelButton2.setVisibility(View.VISIBLE);
    
    showHelpOnFirstLaunch();
  }
  

  public void onCancel() {
      finish();
      BarcodeFactory.callCancelCallback(rhoBarcodeId);
  }
  
  public void onRetake() {
      resetStatusView();
	  if (handler != null) {
        handler.sendEmptyMessage(RhoExtManager.getResourceId("id", "restart_preview"));
      }
  }
  
  public void onOK() {
      finish();
      String res = null;
      if (lastResult != null) {
    	  res = lastResult.getText();
      }
   	  BarcodeFactory.callOKCallback(lastResult, rhoBarcodeId);
  }
  
  

  @Override
  protected void onResume() {
    super.onResume();
    resetStatusView();
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
    SurfaceView surfaceView = (SurfaceView) findViewById(RhoExtManager.getResourceId("id", "preview_view"));
    SurfaceHolder surfaceHolder = surfaceView.getHolder();
    if (hasSurface) {
      // The activity was paused but not stopped, so the surface still exists. Therefore
      // surfaceCreated() won't be called, so init the camera here.
      initCamera(surfaceHolder);
    } else {
      // Install the callback and wait for surfaceCreated() to init the camera.
      surfaceHolder.addCallback(this);
      surfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
    }
    {
      source = Source.NONE;
      decodeFormats = null;
      characterSet = null;
    }
    

    //SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
    playBeep = true;//prefs.getBoolean(PreferencesActivity.KEY_PLAY_BEEP, true);
    if (playBeep) {
      // See if sound settings overrides this
      AudioManager audioService = (AudioManager) getSystemService(AUDIO_SERVICE);
      if (audioService.getRingerMode() != AudioManager.RINGER_MODE_NORMAL) {
        playBeep = false;
      }
    }
    //vibrate = prefs.getBoolean(PreferencesActivity.KEY_VIBRATE, false);
    //copyToClipboard = prefs.getBoolean(PreferencesActivity.KEY_COPY_TO_CLIPBOARD, true);
    initBeepSound();
  }

  @Override
  protected void onPause() {
    super.onPause();
    if (handler != null) {
      handler.quitSynchronously();
      handler = null;
    }
    CameraManager.get().closeDriver();
  }

  @Override
  protected void onDestroy() {
    inactivityTimer.shutdown();
    super.onDestroy();
  }

  @Override
  public boolean onKeyDown(int keyCode, KeyEvent event) {
    if (keyCode == KeyEvent.KEYCODE_BACK) {
    	Logger.D(LOGTAG, "Back Key Caught");
      if (source == Source.NATIVE_APP_INTENT) {
    	  Logger.D(LOGTAG, "Back Native App Intent");
        setResult(RESULT_CANCELED);
        onCancel();
        return true;
      } else if ((source == Source.NONE || source == Source.ZXING_LINK) && lastResult != null) {
    	  onRetake();
        return true;
      }
      setResult(RESULT_CANCELED);
      onCancel();
    } else if (keyCode == KeyEvent.KEYCODE_FOCUS || keyCode == KeyEvent.KEYCODE_CAMERA) {
      // Handle these events so they don't launch the Camera app
      return true;
    }
    return super.onKeyDown(keyCode, event);
  }


  @Override
  public void onConfigurationChanged(Configuration config) {
    // Do nothing, this is to prevent the activity from being restarted when the keyboard opens.
    super.onConfigurationChanged(config);
  }

  public void surfaceCreated(SurfaceHolder holder) {
    if (!hasSurface) {
      hasSurface = true;
      initCamera(holder);
    }
  }

  public void surfaceDestroyed(SurfaceHolder holder) {
    hasSurface = false;
  }

  public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {

  }

  /**
   * A valid barcode has been found, so give an indication of success and show the results.
   *
   * @param rawResult The contents of the barcode.
   * @param barcode   A greyscale bitmap of the camera data which was decoded.
   */
  public void handleDecode(Result rawResult, Bitmap barcode) {
    inactivityTimer.onActivity();
    lastResult = rawResult;
    //historyManager.addHistoryItem(rawResult);
    if (barcode == null) {
      // This is from history -- no saved barcode
      handleDecodeInternally(rawResult, null);
    } else {
      playBeepSoundAndVibrate();
      drawResultPoints(barcode, rawResult);
      handleDecodeInternally(rawResult, barcode);

    }
  }

  /**
   * Superimpose a line for 1D or dots for 2D to highlight the key features of the barcode.
   *
   * @param barcode   A bitmap of the captured image.
   * @param rawResult The decoded results which contains the points to draw.
   */
  private void drawResultPoints(Bitmap barcode, Result rawResult) {
    ResultPoint[] points = rawResult.getResultPoints();
    if (points != null && points.length > 0) {
      Canvas canvas = new Canvas(barcode);
      Paint paint = new Paint();
      paint.setColor(getResources().getColor(RhoExtManager.getResourceId("color", "result_image_border")));
      paint.setStrokeWidth(3.0f);
      paint.setStyle(Paint.Style.STROKE);
      Rect border = new Rect(2, 2, barcode.getWidth() - 2, barcode.getHeight() - 2);
      canvas.drawRect(border, paint);

      paint.setColor(getResources().getColor(RhoExtManager.getResourceId("color", "result_points")));
      if (points.length == 2) {
        paint.setStrokeWidth(4.0f);
        drawLine(canvas, paint, points[0], points[1]);
      } else if (points.length == 4 &&
                 (rawResult.getBarcodeFormat().equals(BarcodeFormat.UPC_A)) ||
                 (rawResult.getBarcodeFormat().equals(BarcodeFormat.EAN_13))) {
        // Hacky special case -- draw two lines, for the barcode and metadata
        drawLine(canvas, paint, points[0], points[1]);
        drawLine(canvas, paint, points[2], points[3]);
      } else {
        paint.setStrokeWidth(10.0f);
        for (ResultPoint point : points) {
          canvas.drawPoint(point.getX(), point.getY(), paint);
        }
      }
    }
  }

  private static void drawLine(Canvas canvas, Paint paint, ResultPoint a, ResultPoint b) {
    canvas.drawLine(a.getX(), a.getY(), b.getX(), b.getY(), paint);
  }

  // Put up our own UI for how to handle the decoded contents.
  private void handleDecodeInternally(Result rawResult, Bitmap barcode) {
    //statusView.setVisibility(View.GONE);
    viewfinderView.setVisibility(View.GONE);
    resultView.setVisibility(View.VISIBLE);

    ImageView barcodeImageView = (ImageView) findViewById(RhoExtManager.getResourceId("id", "barcode_image_view"));
    if (barcode != null) {
      barcodeImageView.setImageBitmap(barcode);
    }

    TextView contentsTextView = (TextView) findViewById(RhoExtManager.getResourceId("id", "contents_text_view"));
    CharSequence displayContents = rawResult.getText();// resultHandler.getDisplayContents();
    contentsTextView.setText(displayContents);
    // Crudely scale betweeen 22 and 32 -- bigger font for shorter text
    int scaledSize = Math.max(22, 32 - displayContents.length() / 4);
    contentsTextView.setTextSize(TypedValue.COMPLEX_UNIT_SP, scaledSize);
    
    mCancelButton2.setVisibility(View.GONE);
    mCancelButton.setVisibility(View.VISIBLE);
    mRetakeButton.setVisibility(View.VISIBLE);
    mOKButton.setVisibility(View.VISIBLE);
    
  }

  // Briefly show the contents of the barcode, then handle the result outside Barcode Scanner.
  private void handleDecodeExternally(Result rawResult, Bitmap barcode) {
  }

  /**
   * We want the help screen to be shown automatically the first time a new version of the app is
   * run. The easiest way to do this is to check android:versionCode from the manifest, and compare
   * it to a value stored as a preference.
   */
  private boolean showHelpOnFirstLaunch() {
    return false;
  }

  /**
   * Creates the beep MediaPlayer in advance so that the sound can be triggered with the least
   * latency possible.
   */
  private void initBeepSound() {
    if (playBeep && mediaPlayer == null) {
      // The volume on STREAM_SYSTEM is not adjustable, and users found it too loud,
      // so we now play on the music stream.
      setVolumeControlStream(AudioManager.STREAM_MUSIC);
      mediaPlayer = new MediaPlayer();
      mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
      mediaPlayer.setOnCompletionListener(beepListener);

      AssetFileDescriptor file = getResources().openRawResourceFd(RhoExtManager.getResourceId("raw", "beep"));
      try {
        mediaPlayer.setDataSource(file.getFileDescriptor(), file.getStartOffset(),
            file.getLength());
        file.close();
        mediaPlayer.setVolume(BEEP_VOLUME, BEEP_VOLUME);
        mediaPlayer.prepare();
      } catch (IOException e) {
        mediaPlayer = null;
      }
    }
  }

  private void playBeepSoundAndVibrate() {
    if (playBeep && mediaPlayer != null) {
      mediaPlayer.start();
    }
    if (vibrate) {
      Vibrator vibrator = (Vibrator) getSystemService(VIBRATOR_SERVICE);
      vibrator.vibrate(VIBRATE_DURATION);
    }
  }

  private void initCamera(SurfaceHolder surfaceHolder) {
    try {
      CameraManager.get().openDriver(surfaceHolder, camera_index);
    } catch (IOException ioe) {
      Log.w(TAG, ioe);
      return;
    } catch (RuntimeException e) {
      // Barcode Scanner has seen crashes in the wild of this variety:
      // java.?lang.?RuntimeException: Fail to connect to camera service
      Log.w(TAG, "Unexpected error initializating camera", e);
      BarcodeFactory.callErrorCallback("Could not open camera", rhoBarcodeId);
      return;
    }
    if (handler == null) {
      handler = new CaptureActivityHandler(this, decodeFormats, characterSet);
    }
  }

  private void resetStatusView() {
    resultView.setVisibility(View.GONE);
    //statusView.setText(R.string.msg_default_status);
    //statusView.setVisibility(View.VISIBLE);
    viewfinderView.setVisibility(View.VISIBLE);
    
    mCancelButton2.setVisibility(View.VISIBLE);
    mCancelButton.setVisibility(View.GONE);
    mRetakeButton.setVisibility(View.GONE);
    mOKButton.setVisibility(View.GONE);
    lastResult = null;
  }

  public void drawViewfinder() {
    viewfinderView.drawViewfinder();
  }
}
