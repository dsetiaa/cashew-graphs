import 'package:cashew_graphs/database/tables.dart'; //TODO: verify if cyclic?
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

late String clientID;
late FinanceDatabase database;
late SharedPreferences sharedPreferences;
final uuid = Uuid();
