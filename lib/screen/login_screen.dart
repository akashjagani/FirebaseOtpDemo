import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_otp_verification_demo/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MobileVerificationState {
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE,
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  MobileVerificationState currentState =
      MobileVerificationState.SHOW_MOBILE_FORM_STATE;
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance;

  String verificationId;

  bool showLoading = false;

  ///
  void signInWithPhoneAuthCredential(
      PhoneAuthCredential phoneAuthCredential) async {
    setState(() {
      showLoading = true;
    });

    try {
      final authCredential =
          await _auth.signInWithCredential(phoneAuthCredential);
      setState(() {
        showLoading = false;
      });

      if (authCredential?.user != null) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
            (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        showLoading = false;
      });

      _globalKey.currentState.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  ///
  getMobileFormWidget(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Otp Demo'),
        leading: IconButton(
          onPressed: () {
            print('DRAWER PRESSED');
          },
          icon: Icon(Icons.menu),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Spacer(),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                hintText: 'Enter Your Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            FlatButton(
              onPressed: () async {
                print('SEND OTP BUTTON PRESSED');
                if (_isValidate(phone: phoneController.text)) {
                  setState(() {
                    showLoading = true;
                  });

                  await _auth.verifyPhoneNumber(
                    phoneNumber: '+91' + phoneController.text,
                    verificationCompleted: (phoneAuthCredential) async {
                      setState(() {
                        showLoading = false;
                      });
                      // signInWithPhoneAuthCredential(phoneAuthCredential);
                    },
                    verificationFailed: (verificationFailed) async {
                      _globalKey.currentState.showSnackBar(
                        SnackBar(
                          content: Text(verificationFailed.message),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    codeSent: (verificationId, resendingToken) async {
                      setState(() {
                        showLoading = false;
                        currentState =
                            MobileVerificationState.SHOW_OTP_FORM_STATE;
                        this.verificationId = verificationId;
                      });
                    },
                    codeAutoRetrievalTimeout: (verificationId) async {},
                  );
                }
              },
              child: Text('Send OTP'),
              color: Colors.blue,
              textColor: Colors.white,
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  ///
  getOtpFormWidget(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP Screen'),
        leading: IconButton(
          onPressed: () {
            print('OTPSCREEN BACK BUTTON PRESSED');
          },
          icon: Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Spacer(),
            TextFormField(
              controller: otpController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FlatButton(
                  onPressed: () async {
                    print('VERIFY BUTTON PRESSED');
                    if (_isValidateOtp(otp: otpController.text)) {
                      PhoneAuthCredential phoneAuthCredential =
                          PhoneAuthProvider.credential(
                              verificationId: verificationId,
                              smsCode: otpController.text);

                      signInWithPhoneAuthCredential(phoneAuthCredential);
                    }
                  },
                  child: Text('Verify'),
                  color: Colors.blue,
                  textColor: Colors.white,
                ),
                FlatButton(
                  onPressed: () async {
                    print('SEND AGAIN BUTTON PRESSED');
                    setState(() {
                      showLoading = true;
                    });
                    await _auth.verifyPhoneNumber(
                      phoneNumber: '+91' + phoneController.text,
                      verificationCompleted: (phoneAuthCredential) async {
                        setState(() {
                          showLoading = false;
                        });
                        // signInWithPhoneAuthCredential(phoneAuthCredential);
                      },
                      verificationFailed: (verificationFailed) async {
                        _globalKey.currentState.showSnackBar(
                          SnackBar(
                            content: Text(verificationFailed.message),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      codeSent: (verificationId, resendingToken) async {
                        setState(() {
                          showLoading = false;
                          currentState =
                              MobileVerificationState.SHOW_OTP_FORM_STATE;
                          this.verificationId = verificationId;
                        });
                      },
                      codeAutoRetrievalTimeout: (verificationId) async {},
                    );
                  },
                  child: Text('Send Again'),
                  color: Colors.blue,
                  textColor: Colors.white,
                ),
              ],
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      body: Container(
        child: showLoading
            ? Center(child: CircularProgressIndicator())
            : currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE
                ? getMobileFormWidget(context)
                : getOtpFormWidget(context),
        //padding: EdgeInsets.all(16),
      ),
    );
  }

  bool _isValidate({
    String phone,
  }) {
    if (phone.isEmpty) {
      _globalKey.currentState.showSnackBar(
        SnackBar(
          content: Text('Please Enter your Phone Number'),
          backgroundColor: Colors.blue,
        ),
      );
      return false;
    }
    return true;
  }

  bool _isValidateOtp({
    String otp,
  }) {
    if (otp.isEmpty) {
      _globalKey.currentState.showSnackBar(
        SnackBar(
          content: Text('Invalid OTP, Please Enter Valid OTP'),
          backgroundColor: Colors.blue,
        ),
      );
      return false;
    }
    return true;
  }
}
