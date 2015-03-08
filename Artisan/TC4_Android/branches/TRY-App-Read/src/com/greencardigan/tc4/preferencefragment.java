package com.greencardigan.tc4;

import android.content.SharedPreferences;
import android.content.SharedPreferences.OnSharedPreferenceChangeListener;
import android.os.Bundle;
import android.preference.EditTextPreference;
import android.preference.ListPreference;
import android.preference.MultiSelectListPreference;
import android.preference.Preference;
import android.preference.PreferenceFragment;
import android.preference.PreferenceGroup;

public class preferencefragment extends PreferenceFragment implements OnSharedPreferenceChangeListener {

	public static final String KEY_PREF_READINTERVAL = "pref_ReadInterval";
	
	public static final String KEY_PREF_BUTTON1COMMAND = "pref_Button1Command";
	public static final String KEY_PREF_BUTTON1TEXT = "pref_Button1Text";
	public static final String KEY_PREF_BUTTON2COMMAND = "pref_Button2Command";
	public static final String KEY_PREF_BUTTON2TEXT = "pref_Button2Text";
	public static final String KEY_PREF_BUTTON3COMMAND = "pref_Button3Command";
	public static final String KEY_PREF_BUTTON3TEXT = "pref_Button3Text";
	public static final String KEY_PREF_BUTTON4COMMAND = "pref_Button4Command";
	public static final String KEY_PREF_BUTTON4TEXT = "pref_Button4Text";
	public static final String KEY_PREF_BUTTON5COMMAND = "pref_Button5Command";
	public static final String KEY_PREF_BUTTON5TEXT = "pref_Button5Text";
	public static final String KEY_PREF_BUTTON6COMMAND = "pref_Button6Command";
	public static final String KEY_PREF_BUTTON6TEXT = "pref_Button6Text";
	public static final String KEY_PREF_BUTTON7COMMAND = "pref_Button7Command";
	public static final String KEY_PREF_BUTTON7TEXT = "pref_Button7Text";
	//public static final String KEY_PREF_BUTTON8COMMAND = "pref_Button8Command";
	//public static final String KEY_PREF_BUTTON8TEXT = "pref_Button8Text";
	public static final String KEY_PREF_BUTTON9COMMAND = "pref_Button9Command";
	//public static final String KEY_PREF_BUTTON9TEXT = "pref_Button9Text";
	public static final String KEY_PREF_BUTTON10COMMAND = "pref_Button10Command";
	//public static final String KEY_PREF_BUTTON10TEXT = "pref_Button10Text";
	//public static final String KEY_PREF_BUTTON11COMMAND = "pref_Button11Command";
	//public static final String KEY_PREF_BUTTON11TEXT = "pref_Button11Text";
	//public static final String KEY_PREF_BUTTON12COMMAND = "pref_Button12Command";
	//public static final String KEY_PREF_BUTTON12TEXT = "pref_Button12Text";


	
	@Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        addPreferencesFromResource(R.xml.preferences);
        //PreferenceManager.setDefaultValues(this, R.xml.preferences, false);
        initSummary(getPreferenceScreen());
    }
	
	@Override
	public void onResume() {
        super.onResume();
        // Set up a listener whenever a key changes
        getPreferenceScreen().getSharedPreferences()
                .registerOnSharedPreferenceChangeListener(this);
    }

    @Override
	public void onPause() {
        super.onPause();
        // Unregister the listener whenever a key changes
        getPreferenceScreen().getSharedPreferences()
                .unregisterOnSharedPreferenceChangeListener(this);
    }

    public void onSharedPreferenceChanged(SharedPreferences sharedPreferences,
            String key) {
        updatePrefSummary(findPreference(key));
    }

    private void initSummary(Preference p) {
        if (p instanceof PreferenceGroup) {
            PreferenceGroup pGrp = (PreferenceGroup) p;
            for (int i = 0; i < pGrp.getPreferenceCount(); i++) {
                initSummary(pGrp.getPreference(i));
            }
        } else {
            updatePrefSummary(p);
        }
    }

    private void updatePrefSummary(Preference p) {
        if (p instanceof ListPreference) {
            ListPreference listPref = (ListPreference) p;
            p.setSummary(listPref.getEntry());
        }
        if (p instanceof EditTextPreference) {
            EditTextPreference editTextPref = (EditTextPreference) p;
            if (p.getTitle().toString().contains("assword"))
            {
                p.setSummary("******");
            } else {
                p.setSummary(editTextPref.getText());
            }
        }
        if (p instanceof MultiSelectListPreference) {
            EditTextPreference editTextPref = (EditTextPreference) p;
            p.setSummary(editTextPref.getText());
        }
    }
}
