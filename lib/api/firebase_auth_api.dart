import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class FirebaseAuthAPI {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Stream<User?> getUserStream(){
    return auth.authStateChanges();
  }

  Future<String?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      return "Sign in cancelled";
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await auth.signInWithCredential(credential);
    return null; // success
  } on FirebaseAuthException catch (e) {
    return "Firebase error: ${e.message}";
  } catch (e) {
    return "Sign in failed: ${e.toString()}";
  }
}


  Future<String> signIn(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Signed in successfully";;
    } on FirebaseAuthException catch (e) {
      return "Failed at error ${e.code}";
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<String?> signUp(String email, String password) async {
  try {
    await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return null; // no error
  } on FirebaseAuthException catch (e) {
    return e.message; // return readable message
  } catch (e) {
    return "An unknown error occurred";
  }
}

}
