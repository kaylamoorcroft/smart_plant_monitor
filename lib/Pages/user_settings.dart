import 'package:flutter/material.dart';
// for persistent storage of user preferences
import 'package:shared_preferences/shared_preferences.dart';


class Settings extends StatefulWidget {
const Settings({super.key});

@override
_SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
    bool _isChecked = false;

    @override
    void initState() {
        super.initState();
        getPrefs();
    }

    //load the notifications preference value from persistent storage on start, or default to false if no pref set yet
        Future<void> getPrefs() async{
            final prefs = await SharedPreferences.getInstance();
            setState((){
                _isChecked = prefs.getBool('notifications') ?? false;
            });
        }

    //after preference is set, asynchronously save to persistent storage
        Future<void> savePref(bool value) async{
            final prefs = await SharedPreferences.getInstance();
            // setState((){
                // _isChecked = prefs.getBool('notifications') ?? true;
                await prefs.setBool('notifications', value);
            // });
        }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
        title: Text('Settings')
        ),
        body: Column(
            children: [
                Container(
                    margin: EdgeInsets.fromLTRB(12, 20, 0, 0),
                    child: CheckboxListTile(
                        title: Text('Get notified about plant conditions'),
                        secondary: Icon(Icons.notification_add),
                        value: _isChecked,
                        //? - check if checkbox has been interacted with yet (if bool is neither true nor false)
                        onChanged: (bool? newValue) {
                            setState((){
                                //! - do not allow null
                                _isChecked = newValue!;
                            });
                            savePref(_isChecked);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        ),
                    ),
                ],
            ),
        );
    }
}

