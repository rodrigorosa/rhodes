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

package com.rhomobile.rhodes.phonebook;

import java.util.HashMap;
import java.util.Map;
import java.util.List;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.ContentValues;
import android.database.Cursor;
import android.net.Uri;
import android.provider.Contacts;
import android.provider.Contacts.Organizations;
import android.provider.Contacts.People;
import android.provider.Contacts.Phones;

import com.rhomobile.rhodes.RhodesService;

@SuppressWarnings("deprecation")
public class ContactAccessorOld implements ContactAccessor {
	
	//private static final String TAG = "ContactsAccessorOld";
	
	/*
	private static final String PB_ID = Phonebook.PB_ID;
	private static final String PB_FIRST_NAME = Phonebook.PB_FIRST_NAME;
	private static final String PB_LAST_NAME = Phonebook.PB_LAST_NAME;
	private static final String PB_MOBILE_NUMBER = Phonebook.PB_MOBILE_NUMBER;
	private static final String PB_HOME_NUMBER = Phonebook.PB_HOME_NUMBER;
	private static final String PB_BUSINESS_NUMBER = Phonebook.PB_BUSINESS_NUMBER;
	private static final String PB_EMAIL_ADDRESS = Phonebook.PB_EMAIL_ADDRESS;
	private static final String PB_COMPANY_NAME = Phonebook.PB_COMPANY_NAME;
	*/
	private ContentResolver cr;
	
	public ContactAccessorOld() {
		cr = RhodesService.getInstance().getContentResolver();
	}

    private static String getConditionString(Map<String,Object> conditionsMap) {
        return null;
    }

	private void fillPhones(String id, Contact contact) {
		Cursor cursor = cr.query(Contacts.Phones.CONTENT_URI,
				new String[] {Phones.NUMBER, Phones.TYPE},
				"person=?", new String[] {id},
				null);

		try {
			int numColumn = cursor.getColumnIndex(Phones.NUMBER);
			int typeColumn = cursor.getColumnIndex(Phones.TYPE);
			cursor.moveToFirst();
			for (int i = 0, lim = cursor.getCount(); i < lim; ++i) {
				switch (cursor.getInt(typeColumn)) {
				case Phones.TYPE_WORK:
					contact.setField(Phonebook.PB_BUSINESS_NUMBER, cursor.getString(numColumn));
					break;
				case Phones.TYPE_HOME:
					contact.setField(Phonebook.PB_HOME_NUMBER, cursor.getString(numColumn));
					break;
				case Phones.TYPE_MOBILE:
					contact.setField(Phonebook.PB_MOBILE_NUMBER, cursor.getString(numColumn));
					break;
				}
				cursor.moveToNext();
			}
		}
		finally {
			cursor.close();
		}
	}

	@Override
	public int getCount(int offset, int max_results, Map<String, Object> conditions) {
		StringBuilder sortMode = new StringBuilder();
		if (max_results > 0 || offset > 0) {
			sortMode.append(People._ID).append(" ASC");
			if (max_results > 0)
				sortMode.append(" LIMIT ").append(max_results);
			if (offset > 0)
				sortMode.append(" OFFSET ").append(offset);
		}
		Cursor cursor = cr.query(People.CONTENT_URI, null, null, null, sortMode.toString());
		int count = -1;
		try {
			count = cursor.getCount();
		} finally {
			cursor.close();
		}
		return count;
	}

	@Override
	public Map<String, Contact> getContacts(int offset, int max_results, List<String> select, Map<String, Object> conditions) throws Exception {
		Map<String, Contact> contacts = new HashMap<String, Contact>();
		
		Cursor cursor = cr.query(People.CONTENT_URI, null, null, null, null);
		try {
			if (!cursor.moveToPosition(offset))
				return contacts;
			if (max_results == -1) {
				max_results = cursor.getCount() - offset;
			}
			
			do {
				if(contacts.size() >= max_results) {
					break;
				}
				Contact contact = new Contact();
	
				String id = cursor.getString(cursor.getColumnIndex(People._ID));
				contact.setId(id);
	
				//contact.setField(PB_COMPANY_NAME, cursor.getString(cursor.getColumnIndex(People.COMPANY)));
	
				//contact.setField(Phonebook.PB_FIRST_NAME, "");
				//contact.setField(Phonebook.PB_LAST_NAME, "");
				String name = cursor.getString(cursor.getColumnIndex(People.NAME));
				if (name != null) {
				    contact.setField(Phonebook.PB_DISPLAY_NAME, name);
					String[] names = name.split(" ");
	
					if (names.length == 1) {
						contact.setField(Phonebook.PB_FIRST_NAME, names[0]);
					}
					else if (names.length > 1) {
						contact.setField(Phonebook.PB_FIRST_NAME, names[0]);
						contact.setField(Phonebook.PB_LAST_NAME, name.replaceFirst(names[0] + " ", ""));
					}
				}
	
				fillPhones(id, contact);
	
				Uri uri = ContentUris.withAppendedId(People.CONTENT_URI,
						Long.parseLong(contact.id()));
	
				Uri orgUri = Uri.withAppendedPath(uri,
						Contacts.Organizations.CONTENT_DIRECTORY);
	
				String[] organizationProjection = new String[] { Organizations.COMPANY };
				Cursor organizationCursor = cr.query(orgUri,
						organizationProjection, "person=?", new String[] {id}, null);
				try {
					int organizationCursorCount = organizationCursor.getCount();
					if (organizationCursorCount > 0) {
						organizationCursor.moveToFirst();
						int numberColumn = organizationCursor
								.getColumnIndex(Organizations.COMPANY);
		
						if (numberColumn != -1)
							contact.setField(Phonebook.PB_COMPANY_NAME,
									organizationCursor.getString(numberColumn));
					}
				}
				finally {
					organizationCursor.close();
				}
	
				String[] contactProjection = new String[] {
						Contacts.ContactMethods.KIND,
						Contacts.ContactMethods.DATA };
	
				Cursor contactCursor = cr.query(
						Contacts.ContactMethods.CONTENT_URI,
						contactProjection, "person=?", new String[] {id}, null);
				try {
					int contactCursorCount = contactCursor.getCount();
					if (contactCursorCount > 0) {
						contactCursor.moveToFirst();
						int numberColumn = contactCursor
								.getColumnIndex(Contacts.ContactMethods.DATA);
						int typeColumn = contactCursor
								.getColumnIndex(Contacts.ContactMethods.KIND);
						for (int j = 0; j < contactCursorCount; j++) {
							switch (contactCursor.getInt(typeColumn)) {
							case Contacts.ContactMethods.TYPE_HOME:
								contact.setField(Phonebook.PB_EMAIL_ADDRESS, contactCursor.getString(numberColumn));
								break;
							}
							contactCursor.moveToNext();
						}
					}
				}
				finally {
					contactCursor.close();
				}
//				contact.makeAllFilled();
				contacts.put(contact.getField(Phonebook.PB_ID), contact);
			} while (cursor.moveToNext());
		}
		finally {
			cursor.close();
		}
		
		return contacts;
	}

	
	@Override
	public Contact getContact(String id) throws Exception {
		Map<String, Contact> allContacts = getContacts(0, -1, null, null);
		/*TODO: implement old API getContact by id. */
		return allContacts.get(id);
	}

	public void save(Contact contact) throws Exception {
		String rbID = contact.id();
		Uri uri = null;

		String firstName = contact.getField(Phonebook.PB_FIRST_NAME);
		String lastName = contact.getField(Phonebook.PB_LAST_NAME);
		String name = firstName + " " + lastName;

		boolean isNew = false;
		if (rbID != null && !"".equals(rbID)) {
			// update
			long id = Long.parseLong(rbID);
			uri = ContentUris.withAppendedId(People.CONTENT_URI, id);
		}
		else {
			// create
			isNew = true;
			ContentValues person = new ContentValues();
			person.put(People.NAME, name);

			uri = cr.insert(People.CONTENT_URI, person);
		}

		if (uri == null)
			throw new Exception("Can not save contact");
		
		if (!isNew) {
			ContentValues values = new ContentValues();
			values.put(People.NAME, name);
			
			cr.update(uri, values, null, null);
		}

		String pathLeaf = (String) uri.getPathSegments().get(
				uri.getPathSegments().size() - 1);

		contact.setId(pathLeaf);

		String[] phones = {Phonebook.PB_MOBILE_NUMBER, Phonebook.PB_HOME_NUMBER, Phonebook.PB_BUSINESS_NUMBER};
		int[] types = {Phones.TYPE_MOBILE, Phones.TYPE_HOME, Phones.TYPE_WORK};
		for (int i = 0; i < phones.length; ++i) {
			String value = contact.getField(phones[i]);
			if (value == null)
				continue;
			ContentValues number = new ContentValues();
			number.put(Phones.PERSON_ID, pathLeaf);
			number.put(Phones.NUMBER, value);
			number.put(Phones.TYPE, types[i]);
			
			Uri phoneUpdate = cr.insert(Phones.CONTENT_URI, number);
			
			if (phoneUpdate == null) {
				int retval = cr.update(People.CONTENT_URI, number, null, null);
				
				if (retval == 0)
					throw new Exception("Failed to insert phone number");
			}
		}
		
		// add email
		if (contact.getField(Phonebook.PB_EMAIL_ADDRESS) != null) {
			ContentValues email = new ContentValues();
			email.put(Contacts.ContactMethods.PERSON_ID, pathLeaf);
			email.put(Contacts.ContactMethods.KIND,
					Contacts.ContactMethods.TYPE_HOME);

			email.put(Contacts.ContactMethods.DATA, contact.getField(Phonebook.PB_EMAIL_ADDRESS));

			email.put(Contacts.ContactMethods.TYPE,
					Contacts.ContactMethods.CONTENT_EMAIL_ITEM_TYPE);

			Uri emailUpdate = cr.insert(Uri.withAppendedPath(uri,
							Contacts.ContactMethods.CONTENT_URI.getPath()
									.substring(1)), email);
			if (emailUpdate == null) {
				throw new Exception("Failed to insert primary email");
			}
		}
		// add organization
		if (contact.getField(Phonebook.PB_COMPANY_NAME) != null) {
			Uri orgUri = Uri.withAppendedPath(uri,
					Contacts.Organizations.CONTENT_DIRECTORY);

			ContentValues company = new ContentValues();
			company.put(Contacts.Organizations.PERSON_ID, pathLeaf);
			company.put(Contacts.Organizations.TYPE,
					Contacts.Organizations.TYPE_WORK);

			company.put(Contacts.Organizations.COMPANY, contact
					.getField(Phonebook.PB_COMPANY_NAME));

			Uri companyUpdate = cr.insert(orgUri, company);

			if (companyUpdate == null) {
				throw new Exception("Failed to insert company");
			}
		}
	}

	public void remove(Contact contact) {
		Uri uri = People.CONTENT_URI;
		
		String id = contact.id();
		cr.delete(uri, People._ID + "=" + id, null);
	}

}
