/*
 * Copyright (C) 2009 The Android Open Source Project
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

package com.greencardigan.tc4;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

import org.achartengine.GraphicalView;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnLongClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.view.inputmethod.EditorInfo;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

/**
 * This is the main Activity that displays the current chat session.
 */
public class TC4 extends Activity {
	
	// Debugging
	private static final String TAG = "TC4";
	private static final boolean D = true;

	private static boolean crack = false;
	private static int crack_count = 0;
	public static ArrayList<String> val = new ArrayList<String>();
	public static final String PREFS_NAME = "ButtonPrefs";
	
	// Message types sent from the BluetoothChatService Handler
	public static final int MESSAGE_STATE_CHANGE = 1;
	public static final int MESSAGE_READ = 2;
	public static final int MESSAGE_WRITE = 3;
	public static final int MESSAGE_DEVICE_NAME = 4;
	public static final int MESSAGE_TOAST = 5;

	// Key names received from the BluetoothChatService Handler
	public static final String DEVICE_NAME = "device_name";
	public static final String TOAST = "toast";

	// Intent request codes
	private static final int REQUEST_CONNECT_DEVICE = 1;
	private static final int REQUEST_ENABLE_BT = 2;

	// Layout Views
	private TextView mTitle;
	// private ListView mConversationView;
	private EditText mOutEditText;
	private Button mSendButton;

	// Name of the connected device
	private String mConnectedDeviceName = null;
	// Array adapter for the conversation thread
	private ArrayAdapter<String> mConversationArrayAdapter;
	// String buffer for outgoing messages
	private StringBuffer mOutStringBuffer;
	// Local Bluetooth adapter
	private BluetoothAdapter mBluetoothAdapter = null;
	// Member object for the chat services
	private BluetoothChatService mChatService = null;

	private static GraphicalView view;
	private LineGraph line = new LineGraph();

	public int time;
	//public boolean updateGraph = true;
	public boolean startLogging = false;
	
	public List<Float> btVals = new ArrayList<Float>();
	public List<Float> etVals = new ArrayList<Float>();
	public List<Integer> timeVals = new ArrayList<Integer>();

	private File folder;
	
	public String Button1Text = "Fan UP";
	public String Button1Cmd = "OT2,UP";
	public String Button2Text = "Fan DOWN";
	public String Button2Cmd = "OT2,DOWN";
	public String Button3Text = "Fan OFF";
	public String Button3Cmd = "OT2,0";
	public String Button4Text = "P2";
	public String Button4Cmd = "PID,P2";
	public String Button5Text = "PID ON";
	public String Button5Cmd = "PID,ON";
	public String Button6Text = "PID OFF";
	public String Button6Cmd = "PID,OFF";
	public String Button7Text = "Htr OFF";
	public String Button7Cmd = "OT1,0";
	//public String Button8Text = "";
	//public String Button8Cmd = "";
	//public String Button9Text = "START Roast";
	public String Button9Cmd = "PID,GO";
	//public String Button10Text = "STOP Roast";
	public String Button10Cmd = "PID,STOP";
	

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		if (D)
			Log.e(TAG, "+++ ON CREATE +++");

		// Set up the window layout
		requestWindowFeature(Window.FEATURE_CUSTOM_TITLE);
		setContentView(R.layout.main);
		getWindow().setFeatureInt(Window.FEATURE_CUSTOM_TITLE,R.layout.custom_title);
		getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

		// Set up the custom title
		mTitle = (TextView) findViewById(R.id.title_left_text);
		mTitle.setText(R.string.app_name);
		mTitle = (TextView) findViewById(R.id.title_right_text);
		
	    // Restore preferences
	    SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);

	    // read prefs for button 1 or use default val if no pref exists
	    Button1Text = button_settings.getString("Button1Text", Button1Text);		
	    Button1Cmd = button_settings.getString("Button1Cmd", Button1Cmd);		
	    Button2Text = button_settings.getString("Button2Text", Button1Text);		
	    Button2Cmd = button_settings.getString("Button2Cmd", Button1Cmd);		
	    Button3Text = button_settings.getString("Button3Text", Button3Text);		
	    Button3Cmd = button_settings.getString("Button3Cmd", Button3Cmd);		
	    Button4Text = button_settings.getString("Button4Text", Button4Text);		
	    Button4Cmd = button_settings.getString("Button4Cmd", Button4Cmd);		
	    Button5Text = button_settings.getString("Button5Text", Button5Text);		
	    Button5Cmd = button_settings.getString("Button5Cmd", Button5Cmd);		
	    Button6Text = button_settings.getString("Button6Text", Button6Text);		
	    Button6Cmd = button_settings.getString("Button6Cmd", Button6Cmd);		
	    Button7Text = button_settings.getString("Button7Text", Button7Text);		
	    Button7Cmd = button_settings.getString("Button7Cmd", Button7Cmd);		
	    //Button8Text = button_settings.getString("Button8Text", Button8Text);		
	    //Button8Cmd = button_settings.getString("Button8Cmd", Button8Cmd);		
	    //Button9Text = button_settings.getString("Button9Text", Button9Text);		
	    Button9Cmd = button_settings.getString("Button9Cmd", Button9Cmd);		
	    //Button10Text = button_settings.getString("Button10Text", Button10Text);		
	    Button10Cmd = button_settings.getString("Button10Cmd", Button10Cmd);		
	    //Button11Text = button_settings.getString("Button11Text", Button11Text);		
	    //Button11Cmd = button_settings.getString("Button11Cmd", Button11Cmd);		
	    //Button12Text = button_settings.getString("Button12Text", Button12Text);		
	    //Button12Cmd = button_settings.getString("Button12Cmd", Button12Cmd);		
	    
	    // set button text
	    Button button1 = (Button) findViewById(R.id.button_1);
		button1.setText(Button1Text); 
	    Button button2 = (Button) findViewById(R.id.button_2);
		button2.setText(Button2Text); 
	    Button button3 = (Button) findViewById(R.id.button_3);
		button3.setText(Button3Text); 
	    Button button4 = (Button) findViewById(R.id.button_4);
		button4.setText(Button4Text); 
	    Button button5 = (Button) findViewById(R.id.button_5);
		button5.setText(Button5Text); 
	    Button button6 = (Button) findViewById(R.id.button_6);
		button6.setText(Button6Text); 
	    Button button7 = (Button) findViewById(R.id.button_7);
		button7.setText(Button7Text); 
	    //Button button8 = (Button) findViewById(R.id.button_8);
		//button8.setText(Button8Text); 
	    //Button button9 = (Button) findViewById(R.id.button_9);
		//button9.setText(Button9Text); 
	    //Button button10 = (Button) findViewById(R.id.button_10);
		//button10.setText(Button10Text); 
	    //Button button11 = (Button) findViewById(R.id.button_11);
		//button11.setText(Button11Text); 
	    //Button button12 = (Button) findViewById(R.id.button_12);
		//button12.setText(Button12Text); 


		// Get local Bluetooth adapter
		mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

		// If the adapter is null, then Bluetooth is not supported
		if (mBluetoothAdapter == null) {
			Toast.makeText(this, "Bluetooth is not available",
					Toast.LENGTH_LONG).show();
			finish();
			return;
		}
	}

	@Override
	public void onStart() {
		super.onStart();
		if (D)
			Log.e(TAG, "++ ON START ++");

		// If BT is not on, request that it be enabled.
		// setupChat() will then be called during onActivityResult
		if (!mBluetoothAdapter.isEnabled()) {
			Intent enableIntent = new Intent(
					BluetoothAdapter.ACTION_REQUEST_ENABLE);
			startActivityForResult(enableIntent, REQUEST_ENABLE_BT);
			// Otherwise, setup the chat session
		} else {
			if (mChatService == null)
				setupChat();
		}

		try{
		view = line.getView(this);
		// setContentView(view);

		// LineGraph line = new LineGraph();
		// GraphicalView gView = line.getView(this);

		LinearLayout layout = (LinearLayout) findViewById(R.id.chart);
		// layout.addView(gView);
		layout.addView(view);
		}catch(Exception e){ Log.e("START","exception"+e.getMessage()); e.printStackTrace(); }

	}

	@Override
	public synchronized void onResume() {
		super.onResume();
		if (D)
			Log.e(TAG, "+ ON RESUME +");

		// Performing this check in onResume() covers the case in which BT was
		// not enabled during onStart(), so we were paused to enable it...
		// onResume() will be called when ACTION_REQUEST_ENABLE activity
		// returns.
		if (mChatService != null) {
			// Only if the state is STATE_NONE, do we know that we haven't
			// started already
			if (mChatService.getState() == BluetoothChatService.STATE_NONE) {
				// Start the Bluetooth chat services
				mChatService.start();
			}
		}
	}

	private void setupChat() {
		Log.d(TAG, "setupChat()");

		// Initialize the array adapter for the conversation thread
		mConversationArrayAdapter = new ArrayAdapter<String>(this,
				R.layout.message);
		// mConversationView = (ListView) findViewById(R.id.in);
		// mConversationView.setAdapter(mConversationArrayAdapter);

		// Initialize the compose field with a listener for the return key
		mOutEditText = (EditText) findViewById(R.id.edit_text_out);
		mOutEditText.setOnEditorActionListener(mWriteListener);

		// Initialize the send button with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_send);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// Send a message using content of the edit text widget
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String message = view.getText().toString();
				sendMessage(message);
			}
		});

		// Initialize button 1 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_1);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// Send a command
				String message = Button1Cmd;
				sendMessage(message);
			}
		});
		
		// Initialize button 2 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_2);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// Send a command
				String message = getString(R.string.button_2_cmd);
				sendMessage(message);
			}
		});

		// Initialize button 3 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_3);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// Send a command
				String message = getString(R.string.button_3_cmd);
				sendMessage(message);
			}
		});

		// Initialize button 4 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_4);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// Send a command
				String message = getString(R.string.button_4_cmd);
				sendMessage(message);
			}
		});

		// Initialize button 5 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_5);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// Send a command
				String message = getString(R.string.button_5_cmd);
				sendMessage(message);
			}
		});

		// Initialize button 6 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_6);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// Send a command
				String message = getString(R.string.button_6_cmd);
				sendMessage(message);
			}
		});

		// Initialize button 7 with a listener that for click
		// events
		mSendButton = (Button) findViewById(R.id.button_7);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				// Send a command
				String message = getString(R.string.button_7_cmd);
				sendMessage(message);
			}
		});

		// Initialize button 8 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_8);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				Button button8 = (Button) findViewById(R.id.button_8);		
				if(crack_count == 0){
					button8.setText(getString(R.string.button_8_text2));
					crack = true;
				}
				else if (crack_count == 1){
					button8.setText(getString(R.string.button_8_text3));	
					crack = true;  
				}
				else {
					button8.setEnabled(false);
					crack = true;
				}
				crack_count++;					
			}
		});

		// Initialize the button 9 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_9);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
							
				//updateGraph = true;
			    //RoastStarted = true;
			    startLogging = true;
			   
				Toast.makeText(getApplicationContext(), "Logging Started", Toast.LENGTH_SHORT).show();

				findViewById(R.id.button_8).setEnabled(true); // enable button 8 (crack marker)
			    findViewById(R.id.button_10).setEnabled(true); //enable end roast button
			    findViewById(R.id.button_9).setEnabled(false); // disable start roast button after clicked
			    findViewById(R.id.button_11).setEnabled(false); // disable start roast button after clicked
			    findViewById(R.id.button_12).setEnabled(true); // enable Stop logging button

				Button button8 = (Button) findViewById(R.id.button_8);
				button8.setText(getString(R.string.button_8_text1)); // reset button 8 text

				// Send a command
				String message = getString(R.string.button_9_cmd);
				sendMessage(message);
			}
		});

		// Initialize button 10 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_10);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {

				Toast.makeText(getApplicationContext(), "Roast ended but still logging", Toast.LENGTH_LONG).show();
				
				findViewById(R.id.button_8).setEnabled(false); // disable crack marker button
			    findViewById(R.id.button_10).setEnabled(false); // disable end roast button
			    findViewById(R.id.button_9).setEnabled(true); // re-enable start roast button
			    
			    crack_count = 0;

			    // Send a command
				String message = getString(R.string.button_10_cmd);
				sendMessage(message);
			}
		});

		// Initialize button 11 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_11);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				
				startLogging = true;
				
				Toast.makeText(getApplicationContext(), "Logging Started", Toast.LENGTH_SHORT).show();
				
			    findViewById(R.id.button_11).setEnabled(false); // disable button 14
			    findViewById(R.id.button_12).setEnabled(true); // enable button 15
			    findViewById(R.id.button_8).setEnabled(true); // enable button 8
				Button button3 = (Button) findViewById(R.id.button_8);
				button3.setText(getString(R.string.button_8_text1)); // reset button 8 text	
			}
		});

		// Initialize button 12 with a listener that for click events
		mSendButton = (Button) findViewById(R.id.button_12);
		mSendButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {

				Toast.makeText(getApplicationContext(), "Logging Ended", Toast.LENGTH_SHORT).show();
				
			    // Here we Save
				if(startLogging){
					try {
						saveToCSV();
					} catch (IOException e) {
						Toast.makeText(getApplicationContext(), "error creating file", Toast.LENGTH_LONG).show();
						e.printStackTrace();
					}
				}
				startLogging = false;
			    findViewById(R.id.button_11).setEnabled(true); // enable button 14
			    findViewById(R.id.button_12).setEnabled(false); // disable button 15
			    findViewById(R.id.button_8).setEnabled(false); // disable button 8
			    
			    crack_count = 0;	
			}
		});

		////// LONG CLICK LISTENERS //////
		
		// Initialize button 1 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_1);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button1Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 1 text with new text
					Button button1 = (Button) findViewById(R.id.button_1);
					button1.setText(NewButtonText); // set button 1 text

					Toast.makeText(getApplicationContext(), "New Button 1 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button1Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 1 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
										
					Button1Cmd = NewButtonCmd; // update current Button 1 command					
				}
				
		        return true;
			}
		});

		// Initialize button 2 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_2);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button2Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 2 text with new text
					Button button2 = (Button) findViewById(R.id.button_2);
					button2.setText(NewButtonText); // set button 2 text

					Toast.makeText(getApplicationContext(), "New Button 2 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button2Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 2 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button2Cmd = NewButtonCmd; // update current Button 2 command
				}
				
		        return true;
			}
		});

		// Initialize button 3 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_3);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button3Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 3 text with new text
					Button button3 = (Button) findViewById(R.id.button_3);
					button3.setText(NewButtonText); // set button 3 text

					Toast.makeText(getApplicationContext(), "New Button 3 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button3Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 3 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button3Cmd = NewButtonCmd; // update current Button 3 command
				}
				
		        return true;
			}
		});

		// Initialize button 4 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_4);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button4Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 4 text with new text
					Button button4 = (Button) findViewById(R.id.button_4);
					button4.setText(NewButtonText); // set button 4 text

					Toast.makeText(getApplicationContext(), "New Button 4 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button4Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 4 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button4Cmd = NewButtonCmd; // update current Button 4 command
				}
				
		        return true;
			}
		});

		// Initialize button 5 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_5);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button5Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 5 text with new text
					Button button5 = (Button) findViewById(R.id.button_5);
					button5.setText(NewButtonText); // set button 5 text

					Toast.makeText(getApplicationContext(), "New Button 5 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button5Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 5 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button5Cmd = NewButtonCmd; // update current Button 5 command
				}
				
		        return true;
			}
		});

		// Initialize button 6 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_6);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button6Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 6 text with new text
					Button button6 = (Button) findViewById(R.id.button_6);
					button6.setText(NewButtonText); // set button 6 text

					Toast.makeText(getApplicationContext(), "New Button 6 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button6Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 6 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button6Cmd = NewButtonCmd; // update current Button 6 command
				}
				
		        return true;
			}
		});

		// Initialize button 7 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_7);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button7Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 7 text with new text
					Button button7 = (Button) findViewById(R.id.button_7);
					button7.setText(NewButtonText); // set button 7 text

					Toast.makeText(getApplicationContext(), "New Button 7 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button7Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 7 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button7Cmd = NewButtonCmd; // update current Button 7 command
				}
				
		        return true;
			}
		});

/*
		// Initialize button 8 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_8);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button8Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 8 text with new text
					Button button8 = (Button) findViewById(R.id.button_8);
					button8.setText(NewButtonText); // set button 8 text

					Toast.makeText(getApplicationContext(), "New Button 8 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button8Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 8 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button8Cmd = NewButtonCmd; // update current Button 8 command
				}
				
		        return true;
			}
		});
*/
		// Initialize button 9 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_9);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			    /*    
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button9Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 9 text with new text
					Button button9 = (Button) findViewById(R.id.button_9);
					button9.setText(NewButtonText); // set button 9 text

					Toast.makeText(getApplicationContext(), "New Button 9 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				*/
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button9Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 9 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button9Cmd = NewButtonCmd; // update current Button 9 command
				}
				
		        return true;
			}
		});

		// Initialize button 10 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_10);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			    /*    
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button10Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 10 text with new text
					Button button10 = (Button) findViewById(R.id.button_10);
					button10.setText(NewButtonText); // set button 10 text

					Toast.makeText(getApplicationContext(), "New Button 10 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				*/
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button10Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 10 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button10Cmd = NewButtonCmd; // update current Button 10 command
				}
				
		        return true;
			}
		});		
		
		/*
		// Initialize button 11 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_11);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button11Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 11 text with new text
					Button button11 = (Button) findViewById(R.id.button_11);
					button11.setText(NewButtonText); // set button 11 text

					Toast.makeText(getApplicationContext(), "New Button 11 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button11Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 11 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button11Cmd = NewButtonCmd; // update current Button 11 command
				}
				
		        return true;
			}
		});
*/
		/*
		// Initialize button 12 with a listener that for long click events
		mSendButton = (Button) findViewById(R.id.button_12);
		mSendButton.setOnLongClickListener(new OnLongClickListener() {
			@Override
			public boolean onLongClick(View v) {
		        
				// We need an Editor object to make preference changes.
		        // All objects are from android.context.Context
		        SharedPreferences button_settings = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
		        SharedPreferences.Editor editor = button_settings.edit();

		        // get string from send command TextView
				TextView view = (TextView) findViewById(R.id.edit_text_out);
				String NewButtonVals = view.getText().toString();
		        
				if (NewButtonVals.startsWith("Text:")) {
			        
					String NewButtonText = NewButtonVals.substring(5);
					editor.putString("Button12Text", NewButtonText); // save new button text to prefs

			        editor.commit(); // Commit the edits!

			        // update button 12 text with new text
					Button button12 = (Button) findViewById(R.id.button_12);
					button12.setText(NewButtonText); // set button 12 text

					Toast.makeText(getApplicationContext(), "New Button 12 text saved", Toast.LENGTH_LONG).show();
					
					view.setText("");
					
				} else if (NewButtonVals.startsWith("Cmd:")) {
			        
					String NewButtonCmd = NewButtonVals.substring(4);
					editor.putString("Button12Cmd", NewButtonCmd); // save new button text to prefs

			        editor.commit(); // Commit the edits!

					Toast.makeText(getApplicationContext(), "New Button 12 command saved: " + NewButtonCmd, Toast.LENGTH_LONG).show();
					
					view.setText("");
					
					Button12Cmd = NewButtonCmd; // update current Button 12 command
				}
				
		        return true;
			}
		});
*/
		
		// Initialize the BluetoothChatService to perform bluetooth connections
		mChatService = new BluetoothChatService(this, mHandler);

		// Initialize the buffer for outgoing messages
		mOutStringBuffer = new StringBuffer("");
	}

	@Override
	public synchronized void onPause() {
		super.onPause();
		if (D)
			Log.e(TAG, "- ON PAUSE -");
	}

	@Override
	public void onStop() {
		super.onStop();
		if (D)
			Log.e(TAG, "-- ON STOP --");
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		// Stop the Bluetooth chat services
		if (mChatService != null)
			mChatService.stop();
		if (D)
			Log.e(TAG, "--- ON DESTROY ---");
	}

	private void ensureDiscoverable() {
		if (D)
			Log.d(TAG, "ensure discoverable");
		if (mBluetoothAdapter.getScanMode() != BluetoothAdapter.SCAN_MODE_CONNECTABLE_DISCOVERABLE) {
			Intent discoverableIntent = new Intent(
					BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE);
			discoverableIntent.putExtra(
					BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300);
			startActivity(discoverableIntent);
		}
	}

	/**
	 * Sends a message.
	 * 
	 * @param message
	 *            A string of text to send.
	 */
	private void sendMessage(String message) {
		// Check that we're actually connected before trying anything
		if (mChatService.getState() != BluetoothChatService.STATE_CONNECTED) {
			Toast.makeText(this, R.string.not_connected, Toast.LENGTH_SHORT)
					.show();
			return;
		}

		// Check that there's actually something to send
		if (message.length() > 0) {
			// Get the message bytes and tell the BluetoothChatService to write
			message = message + "\n";
			byte[] send = message.getBytes();
			mChatService.write(send);

			// Reset out string buffer to zero and clear the edit text field
			mOutStringBuffer.setLength(0);
			mOutEditText.setText(mOutStringBuffer);
		}
	}

	// The action listener for the EditText widget, to listen for the return key
	private TextView.OnEditorActionListener mWriteListener = new TextView.OnEditorActionListener() {
		@Override
		public boolean onEditorAction(TextView view, int actionId,
				KeyEvent event) {
			// If the action is a key-up event on the return key, send the
			// message
			if (actionId == EditorInfo.IME_NULL
					&& event.getAction() == KeyEvent.ACTION_UP) {
				String message = view.getText().toString();
				sendMessage(message);
			}
			if (D)
				Log.i(TAG, "END onEditorAction");
			return true;
		}
	};
	
	
	public String check(String filename){
		File f = new File(filename);
        if(f.isFile() && f.exists()){
        	String t = f.getName();
        	String temp[] = t.split("_")[1].split(Pattern.quote("."));
        	int newf = Integer.parseInt(temp[0])+1;
        	filename = check(folder.toString() + "/" + "roast_"+newf+".csv");
        }
        return filename;
	}
	
	
	@SuppressLint("SimpleDateFormat")
	public void saveToCSV() throws IOException {

	        folder = new File(Environment.getExternalStorageDirectory()+"/Roast");
	        boolean var = false;
	        if (!folder.exists())
	            var = folder.mkdir();

	        System.out.println("" + var);
	        
	        String filename = check(folder.toString() + "/" + "roast_1.csv");
	        FileWriter fw = new FileWriter(filename);
	        for(String s : val){
	        	fw.append(s);
	        }
	        fw.close();
	        val.clear();
			
	        Toast.makeText(getApplicationContext(), "Log saved to " + filename, Toast.LENGTH_LONG).show();
	        
	    }
	
	protected void prepareToSaveToCSV(String[] values) {
		for(String s : values){
        	val.add(s);
        	val.add(",");
        }
		if (crack) {
			if (crack_count == 1) {
				val.add("First Crack Start");
			} else if (crack_count == 2) {
				val.add("First Crack End ");
			} else {
				val.add("Second Crack Start");				
			}
		} else {
			val.add("-");
		}
		crack = false;
		
		val.add("\n");
	}

	// The Handler that gets information back from the BluetoothChatService
	private final Handler mHandler = new Handler() {
		@Override
		public void handleMessage(Message msg) {
			switch (msg.what) {
			case MESSAGE_STATE_CHANGE:
				if (D)
					Log.i(TAG, "MESSAGE_STATE_CHANGE: " + msg.arg1);
				switch (msg.arg1) {
				case BluetoothChatService.STATE_CONNECTED:
					mTitle.setText(R.string.title_connected_to);
					mTitle.append(mConnectedDeviceName);
					mConversationArrayAdapter.clear();
					break;
				case BluetoothChatService.STATE_CONNECTING:
					mTitle.setText(R.string.title_connecting);
					break;
				case BluetoothChatService.STATE_LISTEN:
				case BluetoothChatService.STATE_NONE:
					mTitle.setText(R.string.title_not_connected);
					break;
				}
				break;
			case MESSAGE_WRITE:
				byte[] writeBuf = (byte[]) msg.obj;
				// construct a string from the buffer
				String writeMessage = new String(writeBuf);
				mConversationArrayAdapter.add("OUT: " + writeMessage);
				break;
			case MESSAGE_READ:
				String values[] = (String[]) msg.obj;
				// construct a string from the valid bytes in the buffer
				// mConversationArrayAdapter.add("IN: " + readMessage);

				if (values[0].charAt(0) != '#' & values.length == 8) {
					String counter = values[0];
					String at = values[1];
					String et = values[2];
					String et_ror = values[3];
					String bt = values[4];
					String bt_ror = values[5];
					
					//change this bit?????
					//if (crack) values[5] = "250";
					//crack = false;
					
					String heater = values[6];
					String fan = values[7];
					
					
					
					TextView t;
					t = (TextView) findViewById(R.id.btValue);
					t.setText(bt);
					t = (TextView) findViewById(R.id.btRorValue);
					t.setText(bt_ror);
					t = (TextView) findViewById(R.id.etValue);
					t.setText(et);
					t = (TextView) findViewById(R.id.htrValue);
					t.setText(heater + "%");
					t = (TextView) findViewById(R.id.fanValue);
					t.setText(fan + "%");

					float y1 = Float.parseFloat(bt);
					float y2 = Float.parseFloat(et);
					
					int x = Integer.parseInt(counter);
					
					int m = (x % 3600) / 60;
					int s = x % 60;

					String seconds;

					if (s < 10) {
						seconds = "0" + s;
					} else {
						seconds = "" + s;
					}

					String roastclock = m + ":" + seconds;
					t = (TextView) findViewById(R.id.roastClock);
					t.setText(roastclock);

					if (x < time) { // if there has been a time shift or time reset
						

						int timeShift = time - x + 1;
						
						line.dataset1.clear(); //clear lines
						line.dataset2.clear();
						
						int numRecords = timeVals.size();

						for( int i = 0; i < numRecords; i++) // then shift data and re add lines
						{
							
							int tt = timeVals.get(i);
							tt = tt - timeShift;
							timeVals.set(i, tt);
							
							y1 = btVals.get(i);
							y2 = etVals.get(i);
							
							Point p1 = MockData.getDataFromReceiver(tt, y1);
							line.addNewPoints1(p1);
							
							Point p2 = MockData.getDataFromReceiver(tt, y2);
							line.addNewPoints2(p2);
						}

						LineGraph.setMinX(0);
						
						time = 0;
						// update line??? shift back in time?
						// or clear line data?
						
					    
						// if time has reset then save log and start a new log
						if(startLogging & !val.isEmpty()){ // but don't save if there's nothing to save 
							try {
								saveToCSV();
							} catch (IOException e) {
								Toast.makeText(getApplicationContext(), "error creating file", Toast.LENGTH_LONG).show();
								e.printStackTrace();
							}
						}

						
						
					} else { // no time shift or time reset
						time = x;						

					}

					//LOG DATA into array here

					if(startLogging) prepareToSaveToCSV(values);
					
					if (D)
						Log.i(TAG, "MESSAGE_SAVE_IN_RAM: ok");

						
					btVals.add(y1);
					etVals.add(y2);
					timeVals.add(x);
								
					Point p1 = MockData.getDataFromReceiver(x, y1); // We got new data!
					line.addNewPoints1(p1); // Add it to our graph
						
					Point p2 = MockData.getDataFromReceiver(x, y2); // We got new data!
					line.addNewPoints2(p2); // Add it to our graph
	
					int maxY1 = (int) line.dataset1.getMaxY();
					int maxY2 = (int) line.dataset2.getMaxY();
					
					if (maxY1 > maxY2) {
						LineGraph.setMaxY(maxY1);
					}
					else {
						LineGraph.setMaxY(maxY2);
					}
						
					LineGraph.setMaxX(x);
						
					view.repaint();
					
				}
				break;
			case MESSAGE_DEVICE_NAME:
				// save the connected device's name
				mConnectedDeviceName = msg.getData().getString(DEVICE_NAME);
				Toast.makeText(getApplicationContext(),
						"Connected to " + mConnectedDeviceName,
						Toast.LENGTH_SHORT).show();
				break;
			case MESSAGE_TOAST:
				Toast.makeText(getApplicationContext(),
						msg.getData().getString(TOAST), Toast.LENGTH_SHORT)
						.show();
				break;
			}
		}
	};

	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		if (D)
			Log.d(TAG, "onActivityResult " + resultCode);
		switch (requestCode) {
		case REQUEST_CONNECT_DEVICE:
			// When DeviceListActivity returns with a device to connect
			if (resultCode == Activity.RESULT_OK) {
				// Get the device MAC address
				String address = data.getExtras().getString(
						DeviceListActivity.EXTRA_DEVICE_ADDRESS);
				// Get the BLuetoothDevice object
				BluetoothDevice device = mBluetoothAdapter
						.getRemoteDevice(address);
				// Attempt to connect to the device
				mChatService.connect(device);
			}
			break;
		case REQUEST_ENABLE_BT:
			// When the request to enable Bluetooth returns
			if (resultCode == Activity.RESULT_OK) {
				// Bluetooth is now enabled, so set up a chat session
				setupChat();
			} else {
				// User did not enable Bluetooth or an error occured
				Log.d(TAG, "BT not enabled");
				Toast.makeText(this, R.string.bt_not_enabled_leaving,
						Toast.LENGTH_SHORT).show();
				finish();
			}
		}
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.option_menu, menu);
		return true;
	}

	
	@Override
	public boolean onKeyDown(int keyCode, KeyEvent event) {
		 if ((keyCode == KeyEvent.KEYCODE_BACK)) {
			 this.finish();
			 android.os.Process.killProcess( android.os.Process.myPid()); 
		    }
		    return super.onKeyDown(keyCode, event);
	}
	
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
		case R.id.scan:
			// Launch the DeviceListActivity to see devices and do scan
			Intent serverIntent = new Intent(this, DeviceListActivity.class);
			startActivityForResult(serverIntent, REQUEST_CONNECT_DEVICE);
			return true;
		case R.id.discoverable:
			// Ensure this device is discoverable by others
			ensureDiscoverable();
			return true;
		}
		return false;
	}

}