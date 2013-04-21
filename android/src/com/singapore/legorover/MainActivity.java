/*INSERT YOUR PACKAGE NAME*/
package com.singapore.legorover;

import java.io.IOException;
import java.util.Set;
import java.util.UUID;



import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.DragEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.DragShadowBuilder;
import android.view.View.OnDragListener;
import android.view.View.OnTouchListener;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.NumberPicker;
import android.widget.TextView;
import android.widget.Toast;

/**
 * Android SDK Tutorial - Drag and Drop Mobiletuts+
 * 
 * Sue Smith January 2013
 */

public class MainActivity extends Activity implements BTConnectable{

	private enum ListItemType {
		Move, Rotate, RotateCamera, TakePhoto
	}

	// TODO consider subclassing rather than enums
	private class ListItem {

		private ListItemType type;
		private CharSequence value;

		public ListItem(ListItemType type) {
			this.type = type;
		}

		public ListItemType getType() {
			return type;
		}

		public CharSequence getValue() {
			return value;
		}

		public TextWatcher getWatcher() {
			return new TextWatcher() {

				@Override
				public void afterTextChanged(Editable arg0) {
					// TODO Auto-generated method stub
				}

				@Override
				public void beforeTextChanged(CharSequence arg0, int arg1,
						int arg2, int arg3) {
					// TODO Auto-generated method stub
				}

				@Override
				public void onTextChanged(CharSequence arg0, int arg1,
						int arg2, int arg3) {
					value = arg0;
				}

			};
		}

	}

	public class MyArrayAdapter  extends ArrayAdapter<ListItem> {

		public MyArrayAdapter(Context context) {
			super(context, android.R.layout.simple_list_item_1);
		}

		@Override
		public View getView(int position, View convertView, ViewGroup parent) {
			LinearLayout layout;
			ListItem item = getItem(position);
			if (item.getType() == ListItemType.TakePhoto) {
				layout = (LinearLayout) inflater.inflate(R.layout.plain_row,
						parent, false);
			} else {
				layout = (LinearLayout) inflater.inflate(R.layout.number_row,
						parent, false);
			}
			// TODO this is s**t look into subclassing layout
			TextView text = (TextView) layout
					.findViewById(R.id.list_option_text);
			text.setText(item.getType().toString());
			EditText edit = (EditText) layout.findViewById(R.id.editText1);
			if (edit != null) {
				edit.addTextChangedListener(item.getWatcher());
			}
			return layout;
		}
	}

	private static final int REQUEST_ENABLE_BT = 0;

	// Create a BroadcastReceiver for ACTION_FOUND
	private BroadcastReceiver receiver;

	// text views being dragged and dropped onto
	private TextView option1, option2, option3, option4;
	private ListView dropzone;
	MyArrayAdapter adapter;
	private LayoutInflater inflater;
	public static final int REQUEST_ENABLE_BLUETOOTH = 1;
	public static final String ROVER_BLUETOOTH_NAME = "White";

	private BluetoothAdapter bluetoothAdapter;
	BTCommunicator communicator;
	
	public void connect_Click(View view)
	{
		bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
		if (bluetoothAdapter == null) {
			Toast toast = Toast.makeText(this, "bluetooth not supported", 1);
			toast.show();
			finish();
		}
		if (!bluetoothAdapter.isEnabled()) {
			Intent enableBtIntent = new Intent(
					BluetoothAdapter.ACTION_REQUEST_ENABLE);
			startActivityForResult(enableBtIntent, REQUEST_ENABLE_BLUETOOTH);
		}
		
		communicator = new BTCommunicator(this, null, bluetoothAdapter, getResources());
		

		Set<BluetoothDevice> pairedDevices = bluetoothAdapter
				.getBondedDevices();
		// If there are paired devices
		boolean pairedDeviceFound = false;
		if (pairedDevices.size() > 0) {
			// Loop through paired devices
			for (BluetoothDevice device : pairedDevices) {
				if (device.getName().equals(ROVER_BLUETOOTH_NAME)) {
					Log.e(this.getClass().toString(), "Rover Already Paired!" );
					pairedDeviceFound = true;
					try
					{
						communicator.setMACAddress(device.getAddress());
						communicator.createNXTconnection();
					}
					catch(Throwable e)
					{
						Log.e(this.getClass().toString(), e.getMessage());
					}
				}
			}
		}
		
		

		receiver = new BroadcastReceiver() {

			public void onReceive(Context context, Intent intent) {
				String action = intent.getAction();
				// When discovery finds a device
				if (BluetoothDevice.ACTION_FOUND.equals(action)) {
					try {
						// Get the BluetoothDevice object from the Intent
						BluetoothDevice device = intent
								.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
						Log.e(MainActivity.class.toString(),
								device.getAddress());
						Log.e(MainActivity.class.toString(), device.getName());
						if (device.getName().equals(ROVER_BLUETOOTH_NAME)) {
							bluetoothAdapter.cancelDiscovery();
							communicator.setMACAddress(device.getAddress());
							communicator.createNXTconnection();

						}
					} catch (Throwable e) {
						Log.e(this.getClass().toString(), "Unable yo Connect "
								+ e.getMessage());

					}
				}
			}
		};
		// Register the BroadcastReceiver
		IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
		registerReceiver(receiver, filter); // Don't forget to unregister during
											// onDestroy
		if (!pairedDeviceFound) {
			bluetoothAdapter.startDiscovery();
		}
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);

		// views to drag
		option1 = (TextView) findViewById(R.id.option_1);
		option2 = (TextView) findViewById(R.id.option_2);
		option3 = (TextView) findViewById(R.id.option_3);
		option4 = (TextView) findViewById(R.id.option_4);

		// tag the options
		option1.setTag(ListItemType.Rotate);
		option2.setTag(ListItemType.Move);
		option3.setTag(ListItemType.RotateCamera);
		option4.setTag(ListItemType.TakePhoto);

		dropzone = (ListView) findViewById(R.id.dropzone);
		adapter = new MyArrayAdapter(this);
		dropzone.setAdapter(adapter);

		// set touch listeners
		option1.setOnTouchListener(new ChoiceTouchListener());
		option2.setOnTouchListener(new ChoiceTouchListener());
		option3.setOnTouchListener(new ChoiceTouchListener());
		option4.setOnTouchListener(new ChoiceTouchListener());

		// set drag listeners
		dropzone.setOnDragListener(new ChoiceDragListener());

		inflater = (LayoutInflater) this
				.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

		
	}

	/**
	 * ChoiceTouchListener will handle touch events on draggable views
	 * 
	 */
	private final class ChoiceTouchListener implements OnTouchListener {
		public boolean onTouch(View view, MotionEvent motionEvent) {
			if (motionEvent.getAction() == MotionEvent.ACTION_DOWN) {
				/*
				 * Drag details: we only need default behavior - clip data could
				 * be set to pass data as part of drag - shadow can be tailored
				 */
				ClipData data = ClipData.newPlainText("", "");
				DragShadowBuilder shadowBuilder = new View.DragShadowBuilder(
						view);
				// start dragging the item touched
				view.startDrag(data, shadowBuilder, view, 0);
				return true;
			} else {
				return false;
			}
		}
	}

	public void listButtonClick(View view) {
		Button b = (Button) view;
		b.setText("Click");
	}

	/**
	 * DragListener will handle dragged views being dropped on the drop area -
	 * only the drop action will have processing added to it as we are not -
	 * amending the default behavior for other parts of the drag process
	 * 
	 */
	private class ChoiceDragListener implements OnDragListener {

		@Override
		public boolean onDrag(View v, DragEvent event) {
			switch (event.getAction()) {
			case DragEvent.ACTION_DRAG_STARTED:
				// no action necessary
				break;
			case DragEvent.ACTION_DRAG_ENTERED:
				// no action necessary
				break;
			case DragEvent.ACTION_DRAG_EXITED:
				// no action necessary
				break;
			case DragEvent.ACTION_DROP:

				// get the original text view
				TextView view = (TextView) event.getLocalState();
				int position = dropzone.pointToPosition((int) event.getX(),
						(int) event.getY());
				ListItem item = new ListItem((ListItemType) view.getTag());
				try {
					adapter.insert(item, position);
				} catch (IndexOutOfBoundsException e) {
					adapter.add(item);
				}
				adapter.notifyDataSetChanged();
				break;
			case DragEvent.ACTION_DRAG_ENDED:
				// no action necessary
				break;
			default:
				break;
			}
			return true;
		}
	}

	public void sendButton_Click(View view) {
		
		for (int i = 0; i < dropzone.getCount(); i++) {

			ListItem item = (ListItem) dropzone.getItemAtPosition(i);
			String action = item.getType().toString();
			String value = "";
			Log.e(this.getClass().toString(), "Action: " + action + " Value: "
					+ item.getValue());
			String msg = "hello";
			try {
				communicator.sendMessage(msg.getBytes());
			} catch (IOException e) {
				Log.e(this.getClass().toString(), "Unable to send msg to NXT");
			}
		}
	}

	@Override
	public boolean isPairing() {
		// TODO Auto-generated method stub
		return false;
	}

}
