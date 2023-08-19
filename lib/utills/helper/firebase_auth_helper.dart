import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_flutter_app/utills/helper/fcm_helper.dart';
import 'package:firebase_flutter_app/utills/helper/firebasefirestore_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_sign_in/google_sign_in.dart';

mixin AuthMixin {
  Future<Map<String, dynamic>> signInAnonymously();

  Future<Map<String, dynamic>> signUpWithEmailPassword(
      {required String Email, required String Password});

  Future<Map<String, dynamic>> signInWithEmailPassword(
      {required String Email, required String Password});

  Future<Map<String, dynamic>> signInWithGoogle();

  Future<void> signOut();
}

class FirebaseAuthHelper with AuthMixin {
  FirebaseAuthHelper._();

  static final FirebaseAuthHelper firebaseAuthHelper = FirebaseAuthHelper._();

  static final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  static final GoogleSignIn googleSignIn = GoogleSignIn();

  // static final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  //
  // static final FacebookAuth facebookAuth = FacebookAuth.instance;

  get verificationid => "";

// anonymously login:
  Future<Map<String, dynamic>> signInAnonymously() async {
    Map<String, dynamic> data = {};

    try {
      UserCredential userCredential = await firebaseAuth.signInAnonymously();

      User? user = userCredential.user;

      data['user'] = user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "admin-restricted-operation":
          data['msg'] = "This service is temporary down.";
        default:
          data['msg'] = "";
      }
    }
    print(data);
    return data;
  }

  //signupwithemailpassword:
  Future<Map<String, dynamic>> signUpWithEmailPassword(
      {required String Email, required String Password}) async {
    Map<String, dynamic> data = {};

    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: Email, password: Password);

      User? user = userCredential.user;

      data['user'] = user;
      print("-----------------------");
      print(user);
      print("-----------------------");
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "admin-restricted-operation":
          data['msg'] = "This Service is temporary down.";
        case "weak-password":
          data['msg'] = "Password must be at-least 6 char.";
        case "email-already-in-use":
          data['msg'] = "This e-mail id is already exists.";
        case "A network error (such as timeout, interrupted connection or unreachable host) has occurred.":
          data['msg'] = "Please check your internet connection.";
        case "The email address is badly formatted.":
          data['msg'] = "email format is not proper";
        default:
          data['msg'] = "";
      }
    }
    return data;
  }

  //signinwithemailandpaasword:
  Future<Map<String, dynamic>> signInWithEmailPassword(
      {required String Email, required String Password}) async {
    Map<String, dynamic> data = {};

    // String? token = await firebaseMessaging.getToken();

    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: Email, password: Password);

      User? user = userCredential.user;

      data['user'] = user;

      // //TODO: add user into firestore database
      // FireBaseFireStoreHelper.fireBaseFireStoreHelper.addUser(
      //   data: {
      //     "email": userCredential.user?.email,
      //     "uid": userCredential.user?.uid,
      //     "phonenumber": userCredential.user?.phoneNumber,
      //   },
      // );

      String? token = await FCMHelper.fcmHelper.getDeviceToken();

      //TODO : add user into firestore database
      FireBaseFireStoreHelper.fireBaseFireStoreHelper.addUser(data: {
        "email": user?.email,
        "uid": user?.uid,
        "token": token,
        "phonenumber": user?.phoneNumber,
      });

      // Map<String, dynamic> userData = {
      //   "email": user!.email,
      //   "uid": user.uid,
      //   "tokenid": token,
      // };

      // print(userData);
      // await FireStoreHelper.fireStoreHelper
      //     .insertUserWhileSignIn(data: userData);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "admin-restricted-operation":
          data['msg'] = "This service is temporary down.";
        case "wrong-password":
          data['msg'] = "Password is wrong...";
        case "user-not -found":
          data['msg'] = "User does not exists with this e-mail id.";
        case "user-disabled":
          data['msg'] = "User is disable,contact admin for this.";
        default:
          data['msg'] = "";
      }
    }
    // print("=========");
    // print(data);
    // print("=========");
    return data;
  }

//signinwithgoogle:
  Future<Map<String, dynamic>> signInWithGoogle() async {
    Map<String, dynamic> data = {};
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);

      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      User? user = userCredential.user;

      data['user'] = user;

      String? token = await FCMHelper.fcmHelper.getDeviceToken();

      // TODO: add user into firestore database
      // FireBaseFireStoreHelper.fireBaseFireStoreHelper.addUser(
      //   data: {
      //     "email": userCredential.user?.email,
      //     "uid": userCredential.user?.uid,
      //     "token" : token,
      //   },
      // );

      //TODO : add user into firestore database
      FireBaseFireStoreHelper.fireBaseFireStoreHelper.addUser(data: {
        "email": user?.email,
        "uid": user?.uid,
        "token": token,
        "phonenumber": user?.phoneNumber,
      });
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "admin-restricted-operation":
          data['msg'] = "This service is temporary down.";
        case "There is no user record corresponding to this identifier":
          data['msg'] = "This user is not available.";
        default:
          data['msg'] = e.code;
      }
    }
    return data;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await googleSignIn.signOut();
  }

  //update email (with only sign in with emil and password):
  Future updateUserEmail(String newEmail) async {
    User? user = firebaseAuth.currentUser;

    if (user != null) {
      try {
        await user.updateEmail(newEmail);
        print("Email Updated Successfully...");
      } on FirebaseAuthException catch (e) {
        print("Email updated failed..${e.code}");
      }
    }
  }

  //update password (with only sign in with emil and password):
  Future updateUserPassWord(String newPassword) async {
    User? user = firebaseAuth.currentUser;

    if (user != null) {
      try {
        await user.updatePassword(newPassword);
        print("Password updated successfully..");
      } on FirebaseAuthException catch (e) {
        print("Password updated failed...${e.code}");
      }
    }
  }

  //delete account  with only sign in with emil and password :
  deleteUserAccount({required String Email, required String Password}) {
    try {
      User? user = firebaseAuth.currentUser;

      AuthCredential credential =
          EmailAuthProvider.credential(email: Email, password: Password);

      user?.reauthenticateWithCredential(credential).then((value) => {
            value.user?.delete().then((res) {
              Get.offAll('/login_page');
              Get.snackbar(
                'User account deleted',
                "Success",
                backgroundColor: Colors.green,
              );
            })
          });
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred while deleting the user account';
      switch (e.code) {
        case "no-current-user":
          errorMessage = "User does not exists with this email id";
          break;
        case 'wrong-password':
          errorMessage = 'Invalid password. Please try again.';
          break;
        default:
          errorMessage = e.code;
          break;
      }
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

// //signin with facebook:
// Future signInWithFacebook() async {
//   Map<String, dynamic> data = {};
//
//   try {
//     LoginResult loginResult =
//     await facebookAuth.login(permissions: ['email']);
//
//     if (loginResult == LoginStatus.success) {
//       data = await facebookAuth.getUserData();
//     } else {
//       print(loginResult.message);
//     }
//
//     OAuthCredential oAuthCredential =
//     FacebookAuthProvider.credential(loginResult.accessToken!.token);
//
//     UserCredential userCredential =
//     firebaseAuth.signInWithCredential(oAuthCredential) as UserCredential;
//
//     User? user = userCredential.user;
//     print(user);
//
//     data['user'] = user;
//   } on FirebaseAuthException catch (e) {
//     switch (e.code) {
//       case "admin-restricted-operation":
//         data['msg'] = "This service is temporary down.";
//       case "There is no user record corresponding to this identifier":
//         data['msg'] = "This user is not available.";
//       default:
//         data['msg'] = e.code;
//     }
//   }
// }
//
// Future fetchOTP() async {
//   String verificationId = "";
//
//   await firebaseAuth.verifyPhoneNumber(
//       phoneNumber: phoneController.text.toString(),
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         UserCredential authCredential =
//         await firebaseAuth.signInWithCredential(credential);
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         if (e.code == 'invalid-phone-number') {
//           print("Invalid phone number");
//
//           Get.snackbar("${e.message.toString()}", "Not Successfully");
//         }
//       },
//       codeSent: (String verificationid, int? resendToken) async {
//         this.verificationid == verificationid;
//       },
//       codeAutoRetrievalTimeout: (String verificationid) {});
// }
//
// Future veRIfy() async {
//   PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
//     verificationId: verificationid.toString(),
//     smsCode: otpController.text.toString(),
//   );
//   UserCredential userCredential =
//   await firebaseAuth.signInWithCredential(phoneAuthCredential);
//
//   if (userCredential.user != null) {
//     Get.toNamed('/');
//
//     Get.snackbar("SUCCESSFULLY LOGIN", "${userCredential.user}",
//         backgroundColor: Colors.green);
//   }
//
//   // User? user = userCredential.user;
// }
//
// Future signInWithPhoneAuthCredential(
//     PhoneAuthCredential phoneAuthCredential) async {
//   try {
//     FirebaseAuthHelper.firebaseAuthHelper.veRIfy();
//
//     final authCredential =
//     await firebaseAuth.signInWithCredential(phoneAuthCredential);
//     if (authCredential.user != null) {
//       Get.toNamed('/');
//     }
//   } on FirebaseAuthException catch (e) {
//     print(e);
//   }
// }
}

// class FireBaseAuthHelper with AuthMixin {
//   FireBaseAuthHelper._();
//
//   static final FireBaseAuthHelper fireBaseAuthHelper = FireBaseAuthHelper._();
//   FirebaseAuth firebaseAuth = FirebaseAuth.instance;
//
//   GoogleSignIn googleSignIn = GoogleSignIn();
//
//   @override
//   Future<Map<String, dynamic>> anonymousSignIn() async {
//     Map<String, dynamic> data = {};
//
//     try {
//       UserCredential userCredential = await firebaseAuth.signInAnonymously();
//       User? user = userCredential.user;
//
//       data['user'] = user;
//     } on FirebaseAuthException catch (e) {
//       data['message'] = e.code;
//     }
//     return data;
//   }
//
//   @override
//   Future<Map<String, dynamic>> signUpWithEmailAndPassword(
//       {required String Email, required String Password}) async {
//     Map<String, dynamic> data = {};
//
//     try {
//       UserCredential userCredential = await firebaseAuth
//           .createUserWithEmailAndPassword(email: Email, password: Password);
//
//       User? user = userCredential.user;
//
//       data['user'] = user;
//     } on FirebaseAuthException catch (e) {
//       data['error'] = e.code;
//     }
//     return data;
//   }
//

// }
