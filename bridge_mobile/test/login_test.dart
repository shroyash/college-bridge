import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/features/auth/data/models/auth_user_model.dart';

void main() {
  test('Test AuthUserModel.fromJson with Map<dynamic, dynamic>', () {
    final Map<String, dynamic> responseWithDynamicSubmaps = {
      "success": true,
      "message": "Login successful.",
      "data": <dynamic, dynamic>{
        "accessToken": "test_access_token",
        "refreshToken": "test_refresh_token",
        "user": <dynamic, dynamic>{
          "userId": 29,
          "name": "sandesh",
          "email": "sandeshcrest7@gmail.com",
          "role": "STUDENT",
          "institution": <dynamic, dynamic>{
            "institutionId": 2,
            "name": "Aadmin National College",
            "code": "AA01"
          }
        }
      }
    };

    final user = AuthUserModel.fromJson(responseWithDynamicSubmaps);
    expect(user.accessToken, "test_access_token");
    expect(user.userId, 29);
    expect(user.name, "sandesh");
    expect(user.role, "STUDENT");
    expect(user.institution?.code, "AA01");
  });
}
