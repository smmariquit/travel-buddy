import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthAPI {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Stream<User?> getUserStream(){
    return auth.authStateChanges();
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
