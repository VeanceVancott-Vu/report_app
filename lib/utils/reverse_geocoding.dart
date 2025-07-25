import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> fetchAddressFromNominatim(double lat, double lon) async {
  final url =
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'User-Agent': 'your_app_name_here', // Required by Nominatim
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['display_name']; // This is the full address
  } else {
    return null;
  }
}
